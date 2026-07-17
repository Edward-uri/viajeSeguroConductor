import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/error/error.dart';
import '../../../../core/socket/socket_module.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../features/documents/di/documents_module.dart';
import '../../../../features/documents/domain/entities/documento.dart';
import '../../../../features/documents/domain/repositories/documento_repository.dart';
import '../../../../features/heatmap/presentation/provider/heatmap_viewmodel.dart';
import '../../../../features/profile/di/profile_module.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../../features/vehicle/di/vehicle_module.dart';
import '../../../../features/vehicle/domain/entities/vehiculo.dart';
import '../../../../features/vehicle/domain/repositories/vehicle_repository.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../data/services/location_service.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';
import 'ride_inbox_viewmodel.dart';

final driverAvailabilityViewModelProvider = StateNotifierProvider.autoDispose<
    DriverAvailabilityViewModel, DriverAvailabilityState>((ref) {
  return DriverAvailabilityViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(socketServiceProvider),
    ref.watch(documentoRepositoryProvider),
    ref.watch(vehicleRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(rideInboxViewModelProvider.notifier),
    ref.watch(heatmapViewModelProvider.notifier),
  );
});

/// Disponibilidad del conductor: switch online/offline con su gating de
/// documentos + vehículo, adquisición de GPS/permiso y datos de arranque del
/// home (stats, perfil, vehículo). Dueño del stream de posición mientras está
/// en línea sin viaje; durante un viaje el GPS lo maneja RideProgressViewModel.
class DriverAvailabilityViewModel
    extends StateNotifier<DriverAvailabilityState> {
  DriverAvailabilityViewModel(
    this._repository,
    this._locationService,
    this._socketService,
    this._documentoRepository,
    this._vehicleRepository,
    this._profileRepository,
    this._inbox,
    this._heatmap,
  ) : super(const DriverAvailabilityState());

  final RidesRepository _repository;
  final LocationService _locationService;
  final SocketService _socketService;
  final DocumentoRepository _documentoRepository;
  final VehicleRepository _vehicleRepository;
  final ProfileRepository _profileRepository;
  final RideInboxViewModel _inbox;
  final HeatmapViewModel _heatmap;

  StreamSubscription? _positionSub;

  Future<SolicitudViaje?> getViajeActivoConductor() =>
      _repository.getViajeActivoConductor();

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getPendingTrips(),
        _vehicleRepository.getMiVehiculo(),
        // getMe no debe ser fatal: si falla, no debe ocultar la lista de viajes.
        _profileRepository.getMe().then<User?>((u) => u).catchError((_) => null),
      ]);
      if (!mounted) return;
      final pendientes = results[1] as List<SolicitudViaje>;
      final vehiculo = results[2] as Vehiculo?;
      final user = results[3] as User?;
      state = state.copyWith(
        stats: results[0] as DriverStats,
        miVehiculo: vehiculo,
        me: user,
        idMunicipio: user?.idMunicipio ?? state.idMunicipio,
      );
      _inbox.setPendientes(pendientes);
      _inbox.setVehiculo(vehiculo);
      if (kDebugMode) {
        debugPrint('[Home] pendientes=${pendientes.length} municipio=${state.idMunicipio} vehiculoAprobado=${vehiculo?.aprobado}');
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: ErrorHandler.messageFor(e,
            fallback: 'No pudimos cargar tu información. Revisa tu internet e intenta de nuevo.'),
      );
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
    _heatmap.fetchZonas(state.idMunicipio);
  }

  Future<void> initLocation() async {
    await _ensurePosition();
  }

  /// Devuelve la posición actual reutilizando la ya conocida; sólo pide
  /// permiso/GPS si todavía no la tenemos. Pone errorMessage y devuelve null
  /// si no se puede obtener.
  Future<LatLng?> _ensurePosition() async {
    final actual = state.currentPosition;
    if (actual != null) return actual;
    final granted = await _locationService.requestPermission();
    if (!mounted) return null;
    if (!granted) {
      state = state.copyWith(
        errorMessage: 'Necesitamos tu ubicación para enviarte viajes cerca de ti. Actívala en los ajustes.',
      );
      return null;
    }
    if (!await _locationService.isServiceEnabled()) {
      if (!mounted) return null;
      state = state.copyWith(
        errorMessage: 'Activa la ubicación (GPS) de tu teléfono para mostrar tu posición.',
      );
      return null;
    }
    try {
      final pos = await _locationService.getCurrentPosition();
      if (mounted) state = state.copyWith(currentPosition: pos);
      return pos;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          errorMessage: 'No pudimos obtener tu ubicación. Revisa que el GPS esté activo.',
        );
      }
      return null;
    }
  }

  Future<void> toggleOnline() async {
    if (state.isOnline) {
      _goOfflineLocal();
      return;
    }

    // 1) Verificaciones en paralelo: documentos aprobados + vehículo aprobado.
    try {
      final results = await Future.wait<Object?>([
        _documentoRepository.getDocumentos(),
        _vehicleRepository.getMiVehiculo(),
      ]);
      if (!mounted) return;
      final docs = results[0] as List<Documento>;
      final vehiculo = results[1] as Vehiculo?;
      state = state.copyWith(miVehiculo: vehiculo);
      _inbox.setVehiculo(vehiculo);
      final pendientesDocs =
          docs.where((d) => d.status != DocumentStatus.approved).toList();
      if (docs.isEmpty || pendientesDocs.isNotEmpty) {
        state = state.copyWith(
          errorMessage: docs.isEmpty
              ? 'Aún no pudimos verificar tus documentos. Revisa tu internet e intenta de nuevo.'
              : 'Te falta que aprueben: ${pendientesDocs.map((d) => d.nombre).join(', ')}.',
        );
        return;
      }
      if (vehiculo == null) {
        state = state.copyWith(
          errorMessage: 'Registra tu vehículo para poder recibir viajes.',
        );
        return;
      }
      if (!vehiculo.aprobado) {
        state = state.copyWith(
          errorMessage:
              'Tu vehículo aún no está aprobado. Espera la revisión del administrador.',
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: ErrorHandler.messageFor(e,
            fallback: 'No pudimos revisar tu estado. Intenta de nuevo en un momento.'),
      );
      return;
    }

    // 2) Posición: reutiliza la que ya tenemos; sólo pide GPS si falta.
    final pos = await _ensurePosition();
    if (pos == null) return; // _ensurePosition ya mostró el mensaje.

    // 3) Marcar disponible en el backend (única llamada que bloquea el switch).
    try {
      await _repository.toggleAvailability(
        disponible: true,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        errorMessage: ErrorHandler.messageFor(e,
            fallback: 'No pudimos cambiar tu estado. Intenta de nuevo en un momento.'),
      );
      return;
    }
    if (!mounted) return;

    // 4) Ya estás en línea: el switch responde AQUÍ, sin esperar socket ni zonas.
    state = state.copyWith(isOnline: true, errorMessage: null);
    // immediate:false → no re-pide GPS; ya tenemos `pos` fresca.
    _locationService.startTracking(immediate: false);
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream.listen((latLng) {
      state = state.copyWith(currentPosition: latLng);
    });
    _inbox.setOnline(true);

    // 5) Resto del trabajo en segundo plano (no bloquea la UI).
    _socketService.emitOnline(state.idMunicipio).then((joined) {
      if (!joined && mounted) {
        state = state.copyWith(
          errorMessage:
              'Ya estás disponible, pero aún no podemos enviarte viajes. Asegúrate de haber terminado tu registro (licencia y vehículo).',
        );
      }
    });
    _inbox.refrescarPendientes();
    _heatmap.fetchZonas(state.idMunicipio);
  }

  void _goOfflineLocal() {
    _socketService.emitOffline();
    _locationService.stopTracking();
    _positionSub?.cancel();
    _inbox.onOffline();
    _heatmap.clear();
    state = state.copyWith(isOnline: false);
    // Avisar al backend en segundo plano: no es crítico para la UI.
    final pos = state.currentPosition;
    if (pos != null) {
      _repository
          .toggleAvailability(
              disponible: false, lat: pos.latitude, lng: pos.longitude)
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    // El LocationService es compartido (su provider lo dispone); aquí solo se
    // detiene el tracking que este viewmodel inició.
    _locationService.stopTracking();
    super.dispose();
  }
}

class DriverAvailabilityState extends Equatable {
  static const _sentinel = Object();

  const DriverAvailabilityState({
    this.isLoading = false,
    this.isOnline = false,
    this.errorMessage,
    this.currentPosition,
    this.stats,
    this.miVehiculo,
    this.me,
    this.idMunicipio = 1,
  });

  final bool isLoading;
  final bool isOnline;
  final String? errorMessage;
  final LatLng? currentPosition;
  final DriverStats? stats;
  final Vehiculo? miVehiculo;
  final User? me;
  final int idMunicipio;

  // Default true mientras no se conoce (carga/offline): evita el flash del
  // banner "Quiero manejar" para conductores reales en cada arranque.
  bool get esConductor => me?.esConductor ?? true;

  DriverAvailabilityState copyWith({
    bool? isLoading,
    bool? isOnline,
    Object? errorMessage = _sentinel,
    LatLng? currentPosition,
    DriverStats? stats,
    Object? miVehiculo = _sentinel,
    Object? me = _sentinel,
    int? idMunicipio,
  }) {
    return DriverAvailabilityState(
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      currentPosition: currentPosition ?? this.currentPosition,
      stats: stats ?? this.stats,
      miVehiculo: identical(miVehiculo, _sentinel)
          ? this.miVehiculo
          : miVehiculo as Vehiculo?,
      me: identical(me, _sentinel) ? this.me : me as User?,
      idMunicipio: idMunicipio ?? this.idMunicipio,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isOnline,
        errorMessage,
        currentPosition,
        stats,
        miVehiculo,
        me,
        idMunicipio,
      ];
}
