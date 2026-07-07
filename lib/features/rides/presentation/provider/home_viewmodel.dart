import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/env/api_config.dart';
import '../../../../core/http/api_endpoints.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/socket/socket_module.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../features/documents/domain/entities/documento.dart';
import '../../../../features/documents/domain/repositories/documento_repository.dart';
import '../../../../features/heatmap/data/models/heat_zone.dart';
import '../../../../features/heatmap/domain/repositories/heatmap_repository.dart';
import '../../../../features/heatmap/di/heatmap_module.dart';
import '../../../../features/vehicle/domain/entities/vehiculo.dart';
import '../../../../features/vehicle/domain/repositories/vehicle_repository.dart';
import '../../../../features/vehicle/di/vehicle_module.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../../features/profile/di/profile_module.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../documents/di/documents_module.dart';
import '../../data/mappers/solicitud_viaje_mapper.dart';
import '../../data/services/location_service.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final homeViewModelProvider =
    ChangeNotifierProvider.autoDispose<HomeViewModel>((ref) {
  final vm = HomeViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(socketServiceProvider),
    ref.watch(documentoRepositoryProvider),
    ref.watch(heatmapRepositoryProvider),
    ref.watch(authStorageProvider),
    ref.watch(vehicleRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(
    this._repository,
    this._locationService,
    this._socketService,
    this._documentoRepository,
    this._heatmapRepository,
    this._authStorage,
    this._vehicleRepository,
    this._profileRepository,
  );

  final RidesRepository _repository;
  final LocationService _locationService;
  final SocketService _socketService;
  final DocumentoRepository _documentoRepository;
  final HeatmapRepository _heatmapRepository;
  final AuthStorage _authStorage;
  final VehicleRepository _vehicleRepository;
  final ProfileRepository _profileRepository;

  Vehiculo? _miVehiculo;
  Vehiculo? get miVehiculo => _miVehiculo;

  DriverStats? _stats;
  SolicitudViaje? _currentRequest;
  List<SolicitudViaje> _pendientes = [];
  // Viajes que ESTE conductor aceptó: el evento "no disponible" para ellos no es un error.
  final Set<String> _aceptadosPorMi = {};
  // Viajes rechazados: no se reinyectan por refresh ni por socket.
  final Set<String> _rechazados = {};
  SolicitudViaje? _viajeAceptado;
  SolicitudViaje? get viajeAceptado => _viajeAceptado;
  bool _isLoading = false;
  bool _isOnline = false;
  String? _errorMessage;
  LatLng? _currentPosition;
  SocketStatus _socketStatus = SocketStatus.disconnected;
  StreamSubscription? _rideRequestedSub;
  StreamSubscription? _rideAcceptedSub;
  StreamSubscription? _rideNotAvailableSub;
  StreamSubscription? _rideStateChangedSub;
  StreamSubscription? _socketStatusSub;
  StreamSubscription? _positionSub;

  List<HeatZone> _zonasCalientes = [];
  bool _isLoadingZonas = false;
  int idMunicipio = 1;
  User? _me;

  DriverStats? get stats => _stats;
  // Default true mientras no se conoce (carga/offline): evita el flash del
  // banner "Quiero manejar" para conductores reales en cada arranque.
  bool get esConductor => _me?.esConductor ?? true;
  SolicitudViaje? get currentRequest => _currentRequest;
  List<SolicitudViaje> get pendientes => _pendientes;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get errorMessage => _errorMessage;
  LatLng? get currentPosition => _currentPosition;
  SocketStatus get socketStatus => _socketStatus;
  List<HeatZone> get zonasCalientes => _zonasCalientes;
  bool get isLoadingZonas => _isLoadingZonas;

  void initSocket({required String token}) {
    _socketService.connect(token: token);

    _socketStatusSub?.cancel();
    _socketStatusSub = _socketService.statusStream.listen((status) {
      _socketStatus = status;
      if (status == SocketStatus.unauthorized) {
        _refreshSocketToken();
      }
      notifyListeners();
    });

    _rideRequestedSub?.cancel();
    _rideRequestedSub = _socketService.onRideRequested.listen((data) {
      if (!_isOnline) return;
      final viaje = SolicitudViajeMapper.fromJson(data);
      if (_rechazados.contains(viaje.id)) return;
      if (!_pendientes.any((t) => t.id == viaje.id)) {
        _pendientes = [viaje, ..._pendientes];
        notifyListeners();
      }
    });

    _rideAcceptedSub?.cancel();
    _rideAcceptedSub = _socketService.onRideAccepted.listen((data) {
      final idViaje = data['idViaje']?.toString();
      if (idViaje == null) return;
      if (_aceptadosPorMi.contains(idViaje)) return;
      _pendientes = _pendientes.where((t) => t.id != idViaje).toList();
      if (_currentRequest?.id == idViaje) {
        _currentRequest = null;
        _errorMessage = 'Este viaje fue tomado por otro conductor';
      }
      notifyListeners();
    });

    _rideNotAvailableSub?.cancel();
    _rideNotAvailableSub = _socketService.onRideNotAvailable.listen((data) {
      final idViaje = data['idViaje']?.toString();
      if (idViaje == null) return;
      _pendientes = _pendientes.where((t) => t.id != idViaje).toList();
      // Si lo acepté yo, el aviso es normal (no un error): solo quítalo de la lista.
      if (!_aceptadosPorMi.contains(idViaje) && _currentRequest?.id == idViaje) {
        _currentRequest = null;
        _errorMessage = 'Este viaje ya no está disponible';
      }
      notifyListeners();
    });

    _rideStateChangedSub?.cancel();
    _rideStateChangedSub = _socketService.onRideStateChanged.listen((data) {
      final idViaje = data['idViaje']?.toString();
      final estado = data['estado']?.toString();
      if (idViaje != null && _currentRequest?.id == idViaje) {
        switch (estado) {
          case 'cancelado':
            _currentRequest = null;
            break;
          case 'en_curso':
          case 'completado':
            _currentRequest = null;
            break;
        }
        notifyListeners();
      }
    });
  }

  Future<void> _refreshSocketToken() async {
    try {
      final refreshToken = await _authStorage.readRefreshToken();
      if (refreshToken == null) return;
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.refresh}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': refreshToken}),
            )
            .timeout(ApiConfig.requestTimeout);
        if (response.statusCode != 200) return;
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = decoded['accessToken'] as String?;
        final newRefreshToken = decoded['refreshToken'] as String?;
        if (accessToken == null || newRefreshToken == null) return;
        await _authStorage.writeTokens(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
        );
        _socketService.refreshToken(accessToken);
      } finally {
        client.close();
      }
    } catch (_) {}
  }

  Future<bool> goOnline(int idMunicipio) => _socketService.emitOnline(idMunicipio);

  Future<SolicitudViaje?> getViajeActivoConductor() =>
      _repository.getViajeActivoConductor();

  Future<void> refrescarPendientes() async {
    final lista = await _repository.getPendingTrips();
    _pendientes = lista.where((t) => !_rechazados.contains(t.id)).toList();
    notifyListeners();
  }

  void goOffline() {
    _socketService.emitOffline();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getPendingTrips(),
        _vehicleRepository.getMiVehiculo(),
        // getMe no debe ser fatal: si falla, no debe ocultar la lista de viajes.
        _profileRepository.getMe().then<User?>((u) => u).catchError((_) => null),
      ]);
      _stats = results[0] as DriverStats;
      _pendientes = results[1] as List<SolicitudViaje>;
      _miVehiculo = results[2] as Vehiculo?;
      final user = results[3] as User?;
      _me = user;
      if (user?.idMunicipio != null) idMunicipio = user!.idMunicipio!;
      debugPrint('[Home] pendientes=${_pendientes.length} municipio=$idMunicipio vehiculoAprobado=${_miVehiculo?.aprobado}');
    } catch (e) {
      _errorMessage = 'No pudimos cargar tu información. Revisa tu internet e intenta de nuevo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    _fetchZonasCalientes();
  }

  Future<void> initLocation() async {
    final pos = await _ensurePosition();
    if (pos != null) notifyListeners();
  }

  /// Devuelve la posición actual reutilizando la ya conocida; sólo pide
  /// permiso/GPS si todavía no la tenemos. Pone _errorMessage y devuelve null
  /// si no se puede obtener (notifica en los caminos de error).
  Future<LatLng?> _ensurePosition() async {
    if (_currentPosition != null) return _currentPosition;
    final granted = await _locationService.requestPermission();
    if (!granted) {
      _errorMessage = 'Necesitamos tu ubicación para enviarte viajes cerca de ti. Actívala en los ajustes.';
      notifyListeners();
      return null;
    }
    if (!await _locationService.isServiceEnabled()) {
      _errorMessage = 'Activa la ubicación (GPS) de tu teléfono para mostrar tu posición.';
      notifyListeners();
      return null;
    }
    try {
      _currentPosition = await _locationService.getCurrentPosition();
      return _currentPosition;
    } catch (_) {
      _errorMessage = 'No pudimos obtener tu ubicación. Revisa que el GPS esté activo.';
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleOnline() async {
    if (_isOnline) {
      _goOfflineLocal();
      return;
    }

    // 1) Verificaciones en paralelo: documentos aprobados + vehículo aprobado.
    try {
      final results = await Future.wait<Object?>([
        _documentoRepository.getDocumentos(),
        _vehicleRepository.getMiVehiculo(),
      ]);
      final docs = results[0] as List<Documento>;
      _miVehiculo = results[1] as Vehiculo?;
      final pendientesDocs =
          docs.where((d) => d.status != DocumentStatus.approved).toList();
      if (docs.isEmpty || pendientesDocs.isNotEmpty) {
        _errorMessage = docs.isEmpty
            ? 'Aún no pudimos verificar tus documentos. Revisa tu internet e intenta de nuevo.'
            : 'Te falta que aprueben: ${pendientesDocs.map((d) => d.nombre).join(', ')}.';
        notifyListeners();
        return;
      }
      if (_miVehiculo == null) {
        _errorMessage = 'Registra tu vehículo para poder recibir viajes.';
        notifyListeners();
        return;
      }
      if (!_miVehiculo!.aprobado) {
        _errorMessage =
            'Tu vehículo aún no está aprobado. Espera la revisión del administrador.';
        notifyListeners();
        return;
      }
    } catch (_) {
      _errorMessage = 'No pudimos revisar tu estado. Intenta de nuevo en un momento.';
      notifyListeners();
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
    } catch (_) {
      _errorMessage = 'No pudimos cambiar tu estado. Intenta de nuevo en un momento.';
      notifyListeners();
      return;
    }

    // 4) Ya estás en línea: el switch responde AQUÍ, sin esperar socket ni zonas.
    _isOnline = true;
    _errorMessage = null;
    // immediate:false → no re-pide GPS; ya tenemos `pos` fresca.
    _locationService.startTracking(immediate: false);
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream.listen((latLng) {
      _currentPosition = latLng;
      notifyListeners();
    });
    notifyListeners();

    // 5) Resto del trabajo en segundo plano (no bloquea la UI).
    _socketService.emitOnline(idMunicipio).then((joined) {
      if (!joined) {
        _errorMessage =
            'Ya estás disponible, pero aún no podemos enviarte viajes. Asegúrate de haber terminado tu registro (licencia y vehículo).';
        notifyListeners();
      }
    });
    refrescarPendientes();
    _fetchZonasCalientes();
  }

  void _goOfflineLocal() {
    _isOnline = false;
    _socketService.emitOffline();
    _locationService.stopTracking();
    _positionSub?.cancel();
    _aceptadosPorMi.clear();
    _zonasCalientes = [];
    _currentRequest = null;
    notifyListeners();
    // Avisar al backend en segundo plano: no es crítico para la UI.
    final pos = _currentPosition;
    if (pos != null) {
      _repository
          .toggleAvailability(
              disponible: false, lat: pos.latitude, lng: pos.longitude)
          .catchError((_) {});
    }
  }

  Future<void> _fetchZonasCalientes() async {
    _isLoadingZonas = true;
    notifyListeners();
    try {
      _zonasCalientes = await _heatmapRepository.getZonasCalientes(idMunicipio);
      debugPrint('[Home] zonas calientes: ${_zonasCalientes.length} (municipio $idMunicipio)');
    } catch (e) {
      // Las zonas son un extra: si fallan, no se molesta al usuario con un error técnico.
      _zonasCalientes = [];
      debugPrint('[Home] zonas calientes no disponibles: $e');
    } finally {
      _isLoadingZonas = false;
      notifyListeners();
    }
  }

  /// Selecciona un viaje de la lista para abrir su detalle (pantalla de solicitud).
  void seleccionarViaje(SolicitudViaje viaje) {
    _currentRequest = viaje;
    notifyListeners();
  }

  /// Devuelve el viaje aceptado (para navegar a "viaje en curso") o null si falló.
  Future<SolicitudViaje?> acceptRide() async {
    final viaje = _currentRequest;
    if (viaje == null) return null;
    final vehiculo = _miVehiculo;
    if (vehiculo == null || !vehiculo.aprobado) {
      _errorMessage = 'Necesitas un vehículo aprobado para aceptar viajes.';
      notifyListeners();
      return null;
    }
    final aceptadoId = viaje.id;
    _aceptadosPorMi.add(aceptadoId); // antes del await: el socket puede avisar antes de la respuesta HTTP
    try {
      await _repository.acceptRide(
        aceptadoId,
        idVehiculo: vehiculo.idVehiculo,
      );
      _pendientes = _pendientes.where((t) => t.id != aceptadoId).toList();
      _viajeAceptado = viaje;
      _currentRequest = null;
      _errorMessage = null;
      notifyListeners();
      return viaje;
    } catch (e) {
      _aceptadosPorMi.remove(aceptadoId); // no se aceptó: ya no es mío
      if (e is ApiException && e.statusCode == 409) {
        _currentRequest = null;
        _errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Este viaje ya fue tomado por otro conductor';
      } else {
        _errorMessage = 'No pudimos aceptar el viaje. Intenta de nuevo.';
      }
      notifyListeners();
      return null;
    }
  }

  Future<void> rejectRide() async {
    final viaje = _currentRequest;
    _currentRequest = null;
    _errorMessage = null;
    if (viaje != null) {
      _rechazados.add(viaje.id);
      _pendientes = _pendientes.where((t) => t.id != viaje.id).toList();
      try {
        await _repository.rejectRide(viaje.id);
      } catch (_) {
        // El rechazo local ya surtió efecto; si el backend falla no molestamos al usuario.
      }
    }
    notifyListeners();
  }

  /// Marca un viaje como ignorado localmente (p. ej. tras soltarlo): el backend
  /// lo devuelve al pool y re-emite `viaje:solicitado`; esto evita que reaparezca
  /// en la lista de ESTE conductor. La baja real ya la hizo el endpoint /soltar.
  void ignorarViaje(String rideId) {
    _rechazados.add(rideId);
    _pendientes = _pendientes.where((t) => t.id != rideId).toList();
    if (_viajeAceptado?.id == rideId) _viajeAceptado = null;
    notifyListeners();
  }

  Future<void> startRide(String rideId) async {
    try {
      await _repository.startRide(rideId);
    } catch (e) {
      _errorMessage = 'No pudimos iniciar el viaje. Intenta de nuevo.';
      notifyListeners();
    }
  }

  Future<void> completeRide(String rideId) async {
    try {
      await _repository.completeRide(rideId);
      _aceptadosPorMi.remove(rideId);
      _viajeAceptado = null;
    } catch (e) {
      _errorMessage = 'No pudimos terminar el viaje. Intenta de nuevo.';
      notifyListeners();
    }
  }

  Future<void> cancelRide(String rideId, {String? motivo}) async {
    try {
      await _repository.cancelRide(rideId, motivo: motivo);
    } catch (e) {
      _errorMessage = 'No pudimos cancelar el viaje. Intenta de nuevo.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _rideRequestedSub?.cancel();
    _rideAcceptedSub?.cancel();
    _rideNotAvailableSub?.cancel();
    _rideStateChangedSub?.cancel();
    _socketStatusSub?.cancel();
    _positionSub?.cancel();
    _socketService.disconnect();
    _locationService.dispose();
    super.dispose();
  }
}
