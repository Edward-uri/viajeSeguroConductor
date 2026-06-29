import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/socket/socket_module.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../features/documents/domain/entities/documento.dart';
import '../../../../features/documents/domain/repositories/documento_repository.dart';
import '../../../../features/heatmap/data/models/heat_zone.dart';
import '../../../../features/heatmap/domain/repositories/heatmap_repository.dart';
import '../../../../features/heatmap/di/heatmap_module.dart';
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
  );

  final RidesRepository _repository;
  final LocationService _locationService;
  final SocketService _socketService;
  final DocumentoRepository _documentoRepository;
  final HeatmapRepository _heatmapRepository;

  DriverStats? _stats;
  SolicitudViaje? _currentRequest;
  bool _isLoading = false;
  bool _isOnline = false;
  String? _errorMessage;
  LatLng? _currentPosition;
  SocketStatus _socketStatus = SocketStatus.disconnected;
  StreamSubscription? _rideRequestedSub;
  StreamSubscription? _rideStateChangedSub;
  StreamSubscription? _socketStatusSub;

  List<HeatZone> _zonasCalientes = [];
  bool _isLoadingZonas = false;
  int idMunicipio = 1;

  DriverStats? get stats => _stats;
  SolicitudViaje? get currentRequest => _currentRequest;
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
      notifyListeners();
    });

    _rideRequestedSub?.cancel();
    _rideRequestedSub = _socketService.onRideRequested.listen((data) {
      _currentRequest = SolicitudViajeMapper.fromJson(data);
      notifyListeners();
    });

    _rideStateChangedSub?.cancel();
    _rideStateChangedSub = _socketService.onRideStateChanged.listen((data) {
      final idViaje = data['idViaje']?.toString();
      final estado = data['estado']?.toString();
      if (idViaje != null && _currentRequest?.id == idViaje) {
        if (estado == 'cancelado') {
          _currentRequest = null;
        }
        notifyListeners();
      }
    });
  }

  void goOnline(int idMunicipio) {
    _socketService.emitOnline(idMunicipio);
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
        _repository.getCurrentRequest(),
      ]);
      _stats = results[0] as DriverStats;
      _currentRequest = results[1] as SolicitudViaje?;
    } catch (e) {
      _errorMessage = 'Error al cargar datos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initLocation() async {
    final granted = await _locationService.requestPermission();
    if (!granted) {
      _errorMessage = 'Permiso de ubicación requerido';
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
            docs.every((d) => d.status == DocumentStatus.approved);
        if (!allApproved) {
          _errorMessage =
              'Tus documentos aún no están aprobados. Revisa la sección de documentos.';
          notifyListeners();
          return;
        }
      } catch (_) {
        _errorMessage = 'Error al verificar documentos';
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
          _errorMessage = 'Permiso de ubicación requerido';
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
        _socketService.emitOnline(idMunicipio);
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
      }
    } catch (e) {
      _errorMessage = 'Error al cambiar disponibilidad';
    }
    notifyListeners();
  }

  Future<void> _fetchZonasCalientes() async {
    _isLoadingZonas = true;
    notifyListeners();
    try {
      _zonasCalientes = await _heatmapRepository.getZonasCalientes(idMunicipio);
    } catch (e) {
      _errorMessage = 'Error al cargar zonas calientes';
    } finally {
      _isLoadingZonas = false;
      notifyListeners();
    }
  }

  Future<void> acceptRide({required int idVehiculo}) async {
    if (_currentRequest == null) return;
    try {
      await _repository.acceptRide(
        _currentRequest!.id,
        idVehiculo: idVehiculo,
      );
      _currentRequest = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al aceptar viaje';
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
      _errorMessage = 'Error al iniciar viaje';
      notifyListeners();
    }
  }

  Future<void> completeRide(String rideId) async {
    try {
      await _repository.completeRide(rideId);
    } catch (e) {
      _errorMessage = 'Error al completar viaje';
      notifyListeners();
    }
  }

  Future<void> cancelRide(String rideId, {String? motivo}) async {
    try {
      await _repository.cancelRide(rideId, motivo: motivo);
    } catch (e) {
      _errorMessage = 'Error al cancelar viaje';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _rideRequestedSub?.cancel();
    _rideStateChangedSub?.cancel();
    _socketStatusSub?.cancel();
    _socketService.disconnect();
    _locationService.dispose();
    super.dispose();
  }
}
