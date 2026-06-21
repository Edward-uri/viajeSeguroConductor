import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_storage.dart';

class SecureAuthStorage implements AuthStorage {
  SecureAuthStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: _accessTokenKey);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
