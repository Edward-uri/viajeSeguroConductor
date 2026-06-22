import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/services/location_service.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final rideProgressViewModelProvider =
    ChangeNotifierProvider.autoDispose<RideProgressViewModel>((ref) {
  final vm = RideProgressViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});

class RideProgressViewModel extends ChangeNotifier {
  RideProgressViewModel(this._repository, this._locationService);

  final RidesRepository _repository;
  final LocationService _locationService;

  SolicitudViaje? _ride;
  bool _hasStarted = false;
  bool _isLoading = false;
  String? _errorMessage;
  LatLng? _currentPosition;

  SolicitudViaje? get ride => _ride;
  bool get hasStarted => _hasStarted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LatLng? get currentPosition => _currentPosition;

  void setRide(SolicitudViaje ride) {
    _ride = ride;
    notifyListeners();
    _startTracking();
  }

  void _startTracking() {
    _locationService.startTracking();
    _locationService.positionStream.listen((latLng) {
      _currentPosition = latLng;
      notifyListeners();
    });
  }

  Future<void> startRide() async {
    if (_ride == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.startRide(_ride!.id);
      _hasStarted = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al iniciar viaje';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeRide() async {
    if (_ride == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.completeRide(_ride!.id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al completar viaje';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _locationService.stopTracking();
  }
}
