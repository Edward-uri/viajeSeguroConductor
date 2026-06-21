import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../http/api_client.dart';
import '../session/session_service.dart';
import '../storage/auth_storage.dart';
import '../storage/secure_auth_storage.dart';
import '../storage/secure_sensitive_data_storage.dart';
import '../storage/sensitive_data_storage.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final authStorageProvider = Provider<AuthStorage>((ref) => SecureAuthStorage());

final sensitiveDataStorageProvider =
    Provider<SensitiveDataStorage>((ref) => SecureSensitiveDataStorage());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      ref.watch(httpClientProvider),
      ref.watch(authStorageProvider),
    ));

final sessionServiceProvider = Provider<SessionService>((ref) {
  return _NoopSessionService();
});

class _NoopSessionService implements SessionService {
  @override
  Future<bool> hasSession() async => false;

  @override
  Future<void> logout() async {}
}
