import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../env/api_config.dart';
import '../storage/auth_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._client, this._authStorage, {this.baseUrl = ApiConfig.baseUrl});

  final http.Client _client;
  final AuthStorage _authStorage;
  final String baseUrl;

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    return _send(auth: auth, send: (headers) => _client.get(_uri(path), headers: headers));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool auth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = extraHeaders ?? {};
    return _send(auth: auth, send: (h) => _client.post(
      _uri(path),
      headers: {...h, ...headers},
      body: body == null ? null : jsonEncode(body),
    ));
  }

  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required Uint8List bytes,
    required String fieldName,
    required String fileName,
    MediaType? contentType,
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));

    var token = auth ? await _authStorage.readAccessToken() : null;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: fileName,
      contentType: contentType,
    ));

    try {
      final streamed = await request.send().timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      _throwIfError(response);
      if (response.body.isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Respuesta del servidor en formato inesperado', statusCode: response.statusCode);
    } on TimeoutException {
      throw NetworkException('La solicitud tardó demasiado. Revisa tu conexión.');
    } on SocketException {
      throw NetworkException('Sin conexión. Revisa internet e intenta de nuevo.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    } on FormatException {
      throw ApiException('Respuesta del servidor en formato inválido');
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return _send(auth: auth, send: (headers) => _client.put(
      _uri(path),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    ));
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final response = await _sendRaw(auth: auth, send: (h) => _client.delete(_uri(path), headers: h));
    _throwIfError(response);
  }

  Uri _uri(String path) =>
      Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');

  Map<String, String> _buildHeaders({required bool auth, String? token, bool hasBody = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json',
    };
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _send({
    required bool auth,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    final response = await _sendRaw(auth: auth, send: send);
    _throwIfError(response);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return const <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Respuesta del servidor en formato inesperado', statusCode: response.statusCode);
    } on FormatException {
      throw ApiException(
        'Respuesta del servidor en formato inválido',
        statusCode: response.statusCode,
      );
    }
  }

  Future<http.Response> _sendRaw({
    required bool auth,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    try {
      var token = auth ? await _authStorage.readAccessToken() : null;
      var headers = _buildHeaders(auth: auth, token: token, hasBody: true);
      var response = await send(headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 401 && auth && token != null) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          token = await _authStorage.readAccessToken();
          headers = _buildHeaders(auth: true, token: token, hasBody: true);
          response = await send(headers).timeout(ApiConfig.requestTimeout);
        }
      }

      return response;
    } on TimeoutException {
      throw NetworkException('La solicitud tardó demasiado. Revisa tu conexión.');
    } on SocketException {
      throw NetworkException('Sin conexión. Revisa internet e intenta de nuevo.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    }
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _authStorage.readRefreshToken();
      if (refreshToken == null) return false;

      final response = await _client
          .post(
            _uri(ApiEndpoints.refresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = decoded['accessToken'] as String?;
      final newRefreshToken = decoded['refreshToken'] as String?;
      if (accessToken == null || newRefreshToken == null) return false;

      await _authStorage.writeTokens(accessToken: accessToken, refreshToken: newRefreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'Error ${response.statusCode}';
    Object? details;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map) {
        final err = decoded['error'] as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
        details = err['details'];
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(message);
      case 400:
      case 422:
        throw ValidationException(message, details: details);
      default:
        throw ApiException(message, statusCode: response.statusCode, details: details);
    }
  }
}
