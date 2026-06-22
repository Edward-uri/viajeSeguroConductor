import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'https://api.codigoverse.space');

  static Duration get requestTimeout => Duration(
        seconds: int.tryParse(dotenv.get('API_TIMEOUT_SECONDS', fallback: '15')) ?? 15,
      );

  static String get mapboxToken =>
      dotenv.get('MAPBOX_TOKEN', fallback: '');

  static String get mapboxTilesUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/{z}/{x}/{y}?access_token=$mapboxToken';
}
