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
    final position = await Geolocator.getCurrentPosition();
    _lastKnown = LatLng(position.latitude, position.longitude);
    return _lastKnown!;
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

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
