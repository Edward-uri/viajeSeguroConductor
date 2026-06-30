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
  bool _isLoading = false;
  bool _isOnline = false;
  String? _errorMessage;
  LatLng? _currentPosition;
  SocketStatus _socketStatus = SocketStatus.disconnected;
  StreamSubscription? _rideRequestedSub;
  StreamSubscription? _rideNotAvailableSub;
  StreamSubscription? _rideStateChangedSub;
  StreamSubscription? _socketStatusSub;

  List<HeatZone> _zonasCalientes = [];
  bool _isLoadingZonas = false;
  int idMunicipio = 1;

  DriverStats? get stats => _stats;
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
      if (!_pendientes.any((t) => t.id == viaje.id)) {
        _pendientes = [viaje, ..._pendientes];
        notifyListeners();
      }
    });

    _rideNotAvailableSub?.cancel();
    _rideNotAvailableSub = _socketService.onRideNotAvailable.listen((data) {
      final idViaje = data['idViaje']?.toString();
      if (idViaje == null) return;
      _pendientes = _pendientes.where((t) => t.id != idViaje).toList();
      if (_currentRequest?.id == idViaje) {
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

  Future<void> refrescarPendientes() async {
    _pendientes = await _repository.getPendingTrips();
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
    final granted = await _locationService.requestPermission();
    if (!granted) {
      _errorMessage = 'Necesitamos tu ubicación para enviarte viajes cerca de ti. Actívala en los ajustes.';
      notifyListeners();
      return;
    }
    final pos = await _locationService.getCurrentPosition();
    _currentPosition = pos;
    notifyListeners();
  }

  Future<void> toggleOnline() async {
    if (!_isOnline) {
      try {
        final docs = await _documentoRepository.getDocumentos();
        final allApproved =
            docs.isNotEmpty && docs.every((d) => d.status == DocumentStatus.approved);
        if (!allApproved) {
          _errorMessage =
              'Tus documentos aún no están aprobados. Revisa la sección de documentos.';
          notifyListeners();
          return;
        }
        _miVehiculo = await _vehicleRepository.getMiVehiculo();
        if (_miVehiculo == null) {
          _errorMessage =
              'Registra tu vehículo para poder recibir viajes.';
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
    }
    final newState = !_isOnline;
    try {
      LatLng pos;
      if (_currentPosition != null) {
        pos = _currentPosition!;
      } else {
        final granted = await _locationService.requestPermission();
        if (!granted) {
          _errorMessage = 'Necesitamos tu ubicación para enviarte viajes cerca de ti. Actívala en los ajustes.';
          notifyListeners();
          return;
        }
        pos = await _locationService.getCurrentPosition();
        _currentPosition = pos;
      }

      await _repository.toggleAvailability(
        disponible: newState,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      _isOnline = newState;
      _errorMessage = null;

      if (_isOnline) {
        final joined = await _socketService.emitOnline(idMunicipio);
        if (!joined) {
          _errorMessage =
              'Ya estás disponible, pero aún no podemos enviarte viajes. Asegúrate de haber terminado tu registro (licencia y vehículo).';
        }
        await refrescarPendientes();
        _locationService.startTracking();
        _locationService.positionStream.listen((latLng) {
          _currentPosition = latLng;
          notifyListeners();
        });
        _fetchZonasCalientes();
      } else {
        _socketService.emitOffline();
        _locationService.stopTracking();
        _zonasCalientes = [];
        _currentRequest = null;
      }
    } catch (e) {
      _errorMessage = 'No pudimos cambiar tu estado. Intenta de nuevo en un momento.';
    }
    notifyListeners();
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

  Future<void> acceptRide() async {
    if (_currentRequest == null) return;
    final vehiculo = _miVehiculo;
    if (vehiculo == null || !vehiculo.aprobado) {
      _errorMessage = 'Necesitas un vehículo aprobado para aceptar viajes.';
      notifyListeners();
      return;
    }
    final aceptadoId = _currentRequest!.id;
    try {
      await _repository.acceptRide(
        aceptadoId,
        idVehiculo: vehiculo.idVehiculo,
      );
      _pendientes = _pendientes.where((t) => t.id != aceptadoId).toList();
      _currentRequest = null;
      _errorMessage = null;
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        _currentRequest = null;
        _errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Este viaje ya fue tomado por otro conductor';
      } else {
        _errorMessage = 'No pudimos aceptar el viaje. Intenta de nuevo.';
      }
    }
    notifyListeners();
  }

  Future<void> rejectRide() async {
    _currentRequest = null;
    _errorMessage = null;
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
    _rideNotAvailableSub?.cancel();
    _rideStateChangedSub?.cancel();
    _socketStatusSub?.cancel();
    _socketService.disconnect();
    _locationService.dispose();
    super.dispose();
  }
}
