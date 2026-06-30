import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Timer? _timer;
  final _controller = StreamController<LatLng>.broadcast();

  LatLng? _lastKnown;

  LatLng? get lastKnown => _lastKnown;

  Stream<LatLng> get positionStream => _controller.stream;

  Future<LatLng> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        // ponytail: GPS frío en hardware real tarda; sin límite se cuelga.
        timeLimit: const Duration(seconds: 15),
      );
      _lastKnown = LatLng(position.latitude, position.longitude);
      return _lastKnown!;
    } catch (e) {
      // Si el fix tarda/falla, usa la última posición del SO (mejor que colgarse).
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _lastKnown = LatLng(last.latitude, last.longitude);
        return _lastKnown!;
      }
      rethrow;
    }
  }

  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// ¿El GPS del teléfono está encendido? (distinto del permiso de la app).
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  void startTracking({Duration interval = const Duration(seconds: 10)}) {
    stopTracking();
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> _tick() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      _lastKnown = latLng;
      _controller.add(latLng);
    } catch (_) {}
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopTracking();
    _controller.close();
  }
}
