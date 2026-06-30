import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/socket/socket_module.dart';
import '../../../../core/socket/socket_service.dart';
import '../../data/services/location_service.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final rideProgressViewModelProvider =
    ChangeNotifierProvider.autoDispose<RideProgressViewModel>((ref) {
  final vm = RideProgressViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(socketServiceProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});

class RideProgressViewModel extends ChangeNotifier {
  RideProgressViewModel(this._repository, this._locationService, this._socketService);

  final RidesRepository _repository;
  final LocationService _locationService;
  final SocketService _socketService;

  SolicitudViaje? _ride;
  bool _hasStarted = false;
  bool _isLoading = false;
  String? _errorMessage;
  LatLng? _currentPosition;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateChangedSub;
  StreamSubscription? _notAvailableSub;
  bool _canceladoPorPasajero = false;

  SolicitudViaje? get ride => _ride;
  bool get hasStarted => _hasStarted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LatLng? get currentPosition => _currentPosition;
  bool get canceladoPorPasajero => _canceladoPorPasajero;

  void setRide(SolicitudViaje ride) {
    _ride = ride;
    notifyListeners();
    _startTracking();
    _listenSocket();
  }

  void _listenSocket() {
    _stateChangedSub?.cancel();
    _stateChangedSub = _socketService.onRideStateChanged.listen((data) {
      if (data['estado']?.toString() == 'cancelado') {
        _marcarCancelado(data['idViaje']?.toString());
      }
    });
    _notAvailableSub?.cancel();
    _notAvailableSub = _socketService.onRideNotAvailable.listen((data) {
      _marcarCancelado(data['idViaje']?.toString());
    });
  }

  void _marcarCancelado(String? idViaje) {
    if (_ride == null || idViaje != _ride!.id) return;
    _canceladoPorPasajero = true;
    notifyListeners();
  }

  void _startTracking() {
    _positionSub?.cancel();
    _locationService.startTracking(interval: const Duration(seconds: 5));
    _positionSub = _locationService.positionStream.listen((latLng) {
      _currentPosition = latLng;
      notifyListeners();

      if (_ride != null && _hasStarted) {
        _socketService.emitLocation(
          idViaje: _ride!.idViaje,
          lat: latLng.latitude,
          lng: latLng.longitude,
        );
      }
    });
  }

  /// Suelta el viaje aceptado (antes de iniciar): vuelve al pool en el backend.
  Future<bool> soltarViaje() async {
    if (_ride == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.soltarViaje(_ride!.id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'No pudimos soltar el viaje. Intenta de nuevo.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    _positionSub?.cancel();
    _stateChangedSub?.cancel();
    _notAvailableSub?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }
}
