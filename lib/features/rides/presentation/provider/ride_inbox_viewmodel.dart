import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/socket/socket_module.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../features/vehicle/domain/entities/vehiculo.dart';
import '../../data/mappers/solicitud_viaje_mapper.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final rideInboxViewModelProvider =
    StateNotifierProvider.autoDispose<RideInboxViewModel, RideInboxState>((ref) {
  return RideInboxViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(socketServiceProvider),
  );
});

/// Bandeja de solicitudes entrantes. Dueña única del ciclo de vida del socket
/// y de las suscripciones a los eventos de viaje entrantes (solicitado /
/// aceptado / no_disponible / cambio_estado). Los cierres que afectan al viaje
/// activo se retransmiten por [viajesCerrados] a RideProgressViewModel, que es
/// el dueño del canal del viaje en curso (ubicación del pasajero + GPS propio).
class RideInboxViewModel extends StateNotifier<RideInboxState> {
  RideInboxViewModel(this._repository, this._socketService)
      : super(const RideInboxState());

  final RidesRepository _repository;
  final SocketService _socketService;

  // Viajes que ESTE conductor aceptó: el evento "no disponible" para ellos no es un error.
  final Set<String> _aceptadosPorMi = {};
  // Viajes rechazados: no se reinyectan por refresh ni por socket.
  final Set<String> _rechazados = {};
  SolicitudViaje? _viajeAceptado;
  // La disponibilidad vive en DriverAvailabilityViewModel; aquí solo se
  // refleja para filtrar solicitudes entrantes y validar la aceptación.
  Vehiculo? _vehiculo;
  bool _online = false;

  StreamSubscription? _rideRequestedSub;
  StreamSubscription? _rideAcceptedSub;
  StreamSubscription? _rideNotAvailableSub;
  StreamSubscription? _rideStateChangedSub;
  StreamSubscription? _socketStatusSub;

  // Canal de retransmisión hacia RideProgressViewModel: cancelaciones y
  // "no disponible" del socket. El consumidor filtra por id del viaje activo.
  final _viajesCerradosController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get viajesCerrados =>
      _viajesCerradosController.stream;

  void setOnline(bool online) => _online = online;

  void setVehiculo(Vehiculo? vehiculo) => _vehiculo = vehiculo;

  void initSocket({required String token}) {
    _socketService.connect(token: token);

    _socketStatusSub?.cancel();
    // El refresh de token ante `unauthorized` lo maneja el propio
    // SocketService (vía ApiClient.refreshSession); aquí sólo se refleja el estado.
    _socketStatusSub = _socketService.statusStream.listen((status) {
      state = state.copyWith(socketStatus: status);
    });

    _rideRequestedSub?.cancel();
    _rideRequestedSub = _socketService.onRideRequested.listen((data) {
      if (!_online) return;
      final viaje = SolicitudViajeMapper.fromJson(data);
      if (_rechazados.contains(viaje.id)) return;
      if (!state.pendientes.any((t) => t.id == viaje.id)) {
        state = state.copyWith(pendientes: [viaje, ...state.pendientes]);
      }
    });

    _rideAcceptedSub?.cancel();
    _rideAcceptedSub = _socketService.onRideAccepted.listen((data) {
      final idViaje = data['idViaje']?.toString();
      if (idViaje == null) return;
      if (_aceptadosPorMi.contains(idViaje)) return;
      final pendientes =
          state.pendientes.where((t) => t.id != idViaje).toList();
      if (state.currentRequest?.id == idViaje) {
        state = state.copyWith(
          pendientes: pendientes,
          currentRequest: null,
          errorMessage: 'Este viaje fue tomado por otro conductor',
        );
      } else {
        state = state.copyWith(pendientes: pendientes);
      }
    });

    _rideNotAvailableSub?.cancel();
    _rideNotAvailableSub = _socketService.onRideNotAvailable.listen((data) {
      // Retransmitir siempre: RideProgressViewModel filtra por el viaje activo.
      _viajesCerradosController.add(data);
      final idViaje = data['idViaje']?.toString();
      if (idViaje == null) return;
      final pendientes =
          state.pendientes.where((t) => t.id != idViaje).toList();
      // Si lo acepté yo, el aviso es normal (no un error): solo quítalo de la lista.
      if (!_aceptadosPorMi.contains(idViaje) &&
          state.currentRequest?.id == idViaje) {
        state = state.copyWith(
          pendientes: pendientes,
          currentRequest: null,
          errorMessage: 'Este viaje ya no está disponible',
        );
      } else {
        state = state.copyWith(pendientes: pendientes);
      }
    });

    _rideStateChangedSub?.cancel();
    _rideStateChangedSub = _socketService.onRideStateChanged.listen((data) {
      final estado = data['estado']?.toString();
      // Cancelación del viaje activo: la consume RideProgressViewModel.
      if (estado == 'cancelado') _viajesCerradosController.add(data);
      final idViaje = data['idViaje']?.toString();
      if (idViaje != null && state.currentRequest?.id == idViaje) {
        if (estado == 'cancelado' ||
            estado == 'en_curso' ||
            estado == 'completado') {
          state = state.copyWith(currentRequest: null);
        }
      }
    });
  }

  /// Lista inicial cargada por DriverAvailabilityViewModel.loadData (una sola
  /// llamada HTTP compartida con stats/vehículo/perfil).
  void setPendientes(List<SolicitudViaje> lista) {
    state = state.copyWith(pendientes: lista);
  }

  Future<void> refrescarPendientes() async {
    final lista = await _repository.getPendingTrips();
    // !_online: refresh disparado por un pase a online que ya fue revertido;
    // aplicar la lista repoblaría pendientes con el conductor offline.
    if (!mounted || !_online) return;
    state = state.copyWith(
      pendientes: lista.where((t) => !_rechazados.contains(t.id)).toList(),
    );
  }

  /// La UI ya mostró el error: se limpia para que el siguiente, aunque sea
  /// idéntico, vuelva a ser un cambio para los listeners con select().
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Al pasar a offline: se limpia lo aceptado, la solicitud seleccionada y
  /// las pendientes, y se dejan de admitir solicitudes entrantes.
  void onOffline() {
    _online = false;
    _aceptadosPorMi.clear();
    state = state.copyWith(currentRequest: null, pendientes: const []);
  }

  /// Selecciona un viaje de la lista para abrir su detalle (pantalla de solicitud).
  void seleccionarViaje(SolicitudViaje viaje) {
    state = state.copyWith(currentRequest: viaje);
  }

  /// Devuelve el viaje aceptado (para navegar a "viaje en curso") o null si falló.
  Future<SolicitudViaje?> acceptRide() async {
    final viaje = state.currentRequest;
    if (viaje == null) return null;
    // Defensa en profundidad: si el conductor está offline (aunque la lista
    // muestre pendientes), no se puede aceptar. El viaje activo no pasa por
    // aquí, así que un viaje en curso no se ve afectado.
    if (!_online) {
      state = state.copyWith(
        errorMessage: 'Ponte en línea para aceptar viajes.',
      );
      return null;
    }
    final vehiculo = _vehiculo;
    if (vehiculo == null || !vehiculo.aprobado) {
      state = state.copyWith(
        errorMessage: 'Necesitas un vehículo aprobado para aceptar viajes.',
      );
      return null;
    }
    final aceptadoId = viaje.id;
    _aceptadosPorMi.add(aceptadoId); // antes del await: el socket puede avisar antes de la respuesta HTTP
    try {
      await _repository.acceptRide(
        aceptadoId,
        idVehiculo: vehiculo.idVehiculo,
      );
      _viajeAceptado = viaje;
      if (mounted) {
        state = state.copyWith(
          pendientes:
              state.pendientes.where((t) => t.id != aceptadoId).toList(),
          currentRequest: null,
          errorMessage: null,
        );
      }
      return viaje;
    } catch (e) {
      _aceptadosPorMi.remove(aceptadoId); // no se aceptó: ya no es mío
      if (!mounted) return null;
      if (e is ApiException && e.statusCode == 409) {
        state = state.copyWith(
          currentRequest: null,
          errorMessage: e.message.isNotEmpty
              ? e.message
              : 'Este viaje ya fue tomado por otro conductor',
        );
      } else {
        state = state.copyWith(
          errorMessage: ErrorHandler.messageFor(e,
              fallback: 'No pudimos aceptar el viaje. Intenta de nuevo.'),
        );
      }
      return null;
    }
  }

  Future<void> rejectRide() async {
    final viaje = state.currentRequest;
    if (viaje == null) {
      state = state.copyWith(currentRequest: null, errorMessage: null);
      return;
    }
    _rechazados.add(viaje.id);
    state = state.copyWith(
      currentRequest: null,
      errorMessage: null,
      pendientes: state.pendientes.where((t) => t.id != viaje.id).toList(),
    );
    try {
      await _repository.rejectRide(viaje.id);
    } catch (_) {
      // El rechazo local ya surtió efecto; si el backend falla no molestamos al usuario.
    }
  }

  /// Marca un viaje como ignorado localmente (p. ej. tras soltarlo): el backend
  /// lo devuelve al pool y re-emite `viaje:solicitado`; esto evita que reaparezca
  /// en la lista de ESTE conductor. La baja real ya la hizo el endpoint /soltar.
  void ignorarViaje(String rideId) {
    _rechazados.add(rideId);
    if (_viajeAceptado?.id == rideId) _viajeAceptado = null;
    state = state.copyWith(
      pendientes: state.pendientes.where((t) => t.id != rideId).toList(),
    );
  }

  @override
  void dispose() {
    _rideRequestedSub?.cancel();
    _rideAcceptedSub?.cancel();
    _rideNotAvailableSub?.cancel();
    _rideStateChangedSub?.cancel();
    _socketStatusSub?.cancel();
    _viajesCerradosController.close();
    _socketService.disconnect();
    super.dispose();
  }
}

class RideInboxState extends Equatable {
  static const _sentinel = Object();

  const RideInboxState({
    this.pendientes = const [],
    this.currentRequest,
    this.errorMessage,
    this.socketStatus = SocketStatus.disconnected,
  });

  final List<SolicitudViaje> pendientes;
  final SolicitudViaje? currentRequest;
  final String? errorMessage;
  final SocketStatus socketStatus;

  RideInboxState copyWith({
    List<SolicitudViaje>? pendientes,
    Object? currentRequest = _sentinel,
    Object? errorMessage = _sentinel,
    SocketStatus? socketStatus,
  }) {
    return RideInboxState(
      pendientes: pendientes ?? this.pendientes,
      currentRequest: identical(currentRequest, _sentinel)
          ? this.currentRequest
          : currentRequest as SolicitudViaje?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      socketStatus: socketStatus ?? this.socketStatus,
    );
  }

  @override
  List<Object?> get props =>
      [pendientes, currentRequest, errorMessage, socketStatus];
}
