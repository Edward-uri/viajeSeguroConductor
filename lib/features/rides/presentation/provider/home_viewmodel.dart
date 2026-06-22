import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/services/location_service.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final homeViewModelProvider =
    ChangeNotifierProvider.autoDispose<HomeViewModel>((ref) {
  final vm = HomeViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository, this._locationService);

  final RidesRepository _repository;
  final LocationService _locationService;

  DriverStats? _stats;
  SolicitudViaje? _currentRequest;
  bool _isLoading = false;
  bool _isOnline = false;
  String? _errorMessage;
  LatLng? _currentPosition;

  DriverStats? get stats => _stats;
  SolicitudViaje? get currentRequest => _currentRequest;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get errorMessage => _errorMessage;
  LatLng? get currentPosition => _currentPosition;

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
        _locationService.startTracking();
        _locationService.positionStream.listen((latLng) {
          _currentPosition = latLng;
          notifyListeners();
        });
      } else {
        _locationService.stopTracking();
      }
    } catch (e) {
      _errorMessage = 'Error al cambiar disponibilidad';
    }
    notifyListeners();
  }

  Future<void> acceptRide() async {
    if (_currentRequest == null) return;
    try {
      await _repository.acceptRide(_currentRequest!.id);
      _currentRequest = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al aceptar viaje';
    }
    notifyListeners();
  }

  Future<void> rejectRide() async {
    if (_currentRequest == null) return;
    try {
      await _repository.rejectRide(_currentRequest!.id);
      _currentRequest = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al rechazar viaje';
    }
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

  @override
  void dispose() {
    super.dispose();
    _locationService.dispose();
  }
}
