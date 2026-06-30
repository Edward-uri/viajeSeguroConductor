import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/socket/socket_module.dart';
import '../../../../core/socket/socket_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/route_service.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final rideProgressViewModelProvider =
    ChangeNotifierProvider.autoDispose<RideProgressViewModel>((ref) {
  final vm = RideProgressViewModel(
    ref.watch(ridesRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(socketServiceProvider),
    ref.watch(routeServiceProvider),
  );
  ref.onDispose(() => vm.dispose());
  return vm;
});

class RideProgressViewModel extends ChangeNotifier {
  RideProgressViewModel(
    this._repository,
    this._locationService,
    this._socketService,
    this._routeService,
  );

  final RidesRepository _repository;
  final LocationService _locationService;
  final SocketService _socketService;
  final RouteService _routeService;

  SolicitudViaje? _ride;
  bool _hasStarted = false;
  bool _isLoading = false;
  String? _errorMessage;
  LatLng? _currentPosition;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateChangedSub;
  StreamSubscription? _notAvailableSub;
  bool _canceladoPorPasajero = false;

  List<LatLng> _routePoints = const [];
  int? _etaMin;
  double? _remainingKm;
  DateTime? _lastRouteAt;
  bool _routeInFlight = false;

  SolicitudViaje? get ride => _ride;
  bool get hasStarted => _hasStarted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LatLng? get currentPosition => _currentPosition;
  bool get canceladoPorPasajero => _canceladoPorPasajero;
  List<LatLng> get routePoints => _routePoints;
  int? get etaMin => _etaMin;
  double? get remainingKm => _remainingKm;

  void setRide(SolicitudViaje ride) {
    _ride = ride;
    _hasStarted = ride.estado == 'en_curso';
    notifyListeners();
    _startTracking();
    _listenSocket();
    _refreshRoute(force: true);
    _cargarDetalle();
  }

  /// El viaje llega desde la lista sin los datos del pasajero (nombre/teléfono);
  /// los completamos con el detalle enriquecido del backend.
  Future<void> _cargarDetalle() async {
    final id = _ride?.id;
    if (id == null) return;
    try {
      final detalle = await _repository.getRideById(id);
      _ride = detalle;
      _hasStarted = detalle.estado == 'en_curso';
      notifyListeners();
    } catch (_) {
      // Si falla, seguimos con lo que ya teníamos.
    }
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
      _refreshRoute();
    });
  }

  /// Destino del tramo actual: el origen mientras va por el pasajero, el destino una vez iniciado.
  LatLng? get _target {
    final r = _ride;
    if (r == null) return null;
    final lat = _hasStarted ? r.destinoLat : r.origenLat;
    final lng = _hasStarted ? r.destinoLng : r.origenLng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Pide la ruta por calles desde la posición actual al destino del tramo.
  /// Throttle de 20 s para no saturar OSRM; [force] lo salta al cambiar de tramo.
  Future<void> _refreshRoute({bool force = false}) async {
    final from = _currentPosition;
    final to = _target;
    if (from == null || to == null || _routeInFlight) return;
    if (!force &&
        _lastRouteAt != null &&
        DateTime.now().difference(_lastRouteAt!) < const Duration(seconds: 20)) {
      return;
    }
    _routeInFlight = true;
    try {
      final res = await _routeService.obtenerRuta(desde: from, hasta: to);
      if (res == null) return;
      _routePoints = res.points;
      _remainingKm = res.distanciaKm;
      _etaMin = res.duracionMin;
      _lastRouteAt = DateTime.now();
      notifyListeners();
    } catch (_) {
      // Ruta no disponible: el mapa sigue mostrando los marcadores, no rompemos el viaje.
    } finally {
      _routeInFlight = false;
    }
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
      _refreshRoute(force: true);
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
