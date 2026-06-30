import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl =>
      dotenv.get('API_BASE_URL', fallback: 'https://api.codigoverse.space');

  static Duration get requestTimeout => Duration(
        seconds: int.tryParse(dotenv.get('API_TIMEOUT_SECONDS', fallback: '15')) ?? 15,
      );

  static Duration get uploadTimeout => Duration(
        seconds: int.tryParse(dotenv.get('API_UPLOAD_TIMEOUT_SECONDS', fallback: '60')) ?? 60,
      );

  static String get mapboxToken =>
      dotenv.get('MAPBOX_TOKEN', fallback: '');

  static String mapboxTilesUrlFor(Brightness brightness) {
    final style = brightness == Brightness.dark
        ? 'navigation-night-v1'
        : 'navigation-day-v1';
    return 'https://api.mapbox.com/styles/v1/mapbox/$style/tiles/{z}/{x}/{y}?access_token=$mapboxToken';
  }
}
