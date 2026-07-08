import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../env/api_config.dart';
import '../navigation/app_navigator.dart';
import '../storage/auth_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._client, this._authStorage, {String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final AuthStorage _authStorage;
  final String baseUrl;

  Future<bool>? _refreshing;
  DateTime? _refreshBlockedUntil;
  bool _sessionDead = false;

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
    if (path.contains('register/complete') && body is Map) {
      debugPrint('[ApiClient] registerComplete body contains rol=${body.containsKey('rol')}');
    }
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
    String method = 'POST',
  }) async {
    final url = _uri(path);
    final timeout = ApiConfig.uploadTimeout;
    debugPrint('[ApiClient] multipartPost $path auth=$auth timeout=${timeout.inSeconds}s size=${bytes.length}');

    var token = auth ? await _authStorage.readAccessToken() : null;
    if (token != null) {
      debugPrint('[ApiClient] Token: $token');
    } else if (auth) {
      debugPrint('[ApiClient] WARNING: auth=true but readAccessToken() returned null');
    }

    http.MultipartRequest buildRequest() {
      final req = http.MultipartRequest(method, url);
      req.headers['Accept'] = 'application/json';
      if (token != null) {
        req.headers['Authorization'] = 'Bearer $token';
        debugPrint('[ApiClient] Token presente (${token.length} chars)');
      }
      req.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
        contentType: contentType,
      ));
      return req;
    }

    try {
      var request = buildRequest();
      var streamed = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamed).timeout(timeout);

      debugPrint('[ApiClient] multipart response ${response.statusCode}');

      if (response.statusCode == 401 && auth && token != null) {
        debugPrint('[ApiClient] 401 — intentando refresh...');
        final refreshed = await _tryRefresh();
        if (refreshed) {
          debugPrint('[ApiClient] Refresh OK, reintentando multipart...');
          token = await _authStorage.readAccessToken();
          request = buildRequest();
          streamed = await request.send().timeout(timeout);
          response = await http.Response.fromStream(streamed).timeout(timeout);
          debugPrint('[ApiClient] multipart retry response ${response.statusCode}');
        }
      }

      _throwIfError(response);
      if (response.body.isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw ApiException('Respuesta del servidor en formato inesperado', statusCode: response.statusCode);
    } on TimeoutException {
      debugPrint('[ApiClient] multipart TIMEOUT');
      throw NetworkException('La solicitud tardó demasiado. Revisa tu conexión.');
    } on SocketException {
      debugPrint('[ApiClient] multipart SOCKET EXCEPTION');
      throw NetworkException('Sin conexión. Revisa internet e intenta de nuevo.');
    } on http.ClientException catch (e) {
      debugPrint('[ApiClient] multipart CLIENT EXCEPTION: ${e.message}');
      throw NetworkException('Error de red: ${e.message}');
    } on FormatException {
      debugPrint('[ApiClient] multipart FORMAT EXCEPTION');
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

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return _send(auth: auth, send: (headers) => _client.patch(
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
      if (token != null) debugPrint('[ApiClient] Token: $token');
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _sessionDead = false;
        _refreshBlockedUntil = null;
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

  Future<bool> _tryRefresh() {
    // Sesión muerta o en cooldown: no martillar /refresh.
    if (_sessionDead) return Future.value(false);
    if (_refreshBlockedUntil != null &&
        DateTime.now().isBefore(_refreshBlockedUntil!)) {
      return Future.value(false);
    }
    // Si ya hay un refresh en curso, comparte ese mismo Future (single-flight).
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshToken = await _authStorage.readRefreshToken();
      if (refreshToken == null) {
        _killSession();
        return false;
      }

      final response = await _client
          .post(
            _uri(ApiEndpoints.refresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = decoded['accessToken'] as String?;
        final newRefreshToken = decoded['refreshToken'] as String?;
        if (accessToken == null || newRefreshToken == null) {
          _killSession();
          return false;
        }
        await _authStorage.writeTokens(accessToken: accessToken, refreshToken: newRefreshToken);
        _refreshBlockedUntil = null;
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        _killSession();
        return false;
      }

      _refreshBlockedUntil = DateTime.now().add(const Duration(seconds: 60));
      return false;
    } catch (_) {
      _refreshBlockedUntil = DateTime.now().add(const Duration(seconds: 10));
      return false;
    }
  }

  void _killSession() {
    if (_sessionDead) return;
    _sessionDead = true;
    _authStorage.clear();
    AppNavigator.goToLogin();
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
