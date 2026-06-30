import 'package:latlong2/latlong.dart';

import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

/// Ruta por calles (OSRM en el backend) entre dos puntos, para pintar el avance.
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanciaKm,
    required this.duracionMin,
  });

  final List<LatLng> points;
  final double distanciaKm;
  final int duracionMin;
}

class RouteService {
  RouteService(this._api);

  final ApiClient _api;

  Future<RouteResult?> obtenerRuta({
    required LatLng desde,
    required LatLng hasta,
  }) async {
    final json = await _api.get(ApiEndpoints.viajeRuta(
      fromLat: desde.latitude,
      fromLng: desde.longitude,
      toLat: hasta.latitude,
      toLng: hasta.longitude,
    ));

    final coords = (json['ruta'] as Map?)?['coordinates'] as List?;
    // GeoJSON viene en orden [lng, lat]; LatLng espera (lat, lng).
    final points = coords == null
        ? <LatLng>[desde, hasta]
        : coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

    return RouteResult(
      points: points,
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble() ?? 0,
      duracionMin: (json['duracionMin'] as num?)?.toInt() ?? 0,
    );
  }
}
