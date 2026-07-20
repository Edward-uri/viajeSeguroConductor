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
}
