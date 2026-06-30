import '../../../core/session/session_service.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/storage/auth_storage.dart';
import 'remote/auth_api.dart';

class AuthSessionService implements SessionService {
  AuthSessionService(this._api, this._storage, this._socketService);

  final AuthApi _api;
  final AuthStorage _storage;
  final SocketService _socketService;

  @override
  Future<bool> hasSession() async {
    final token = await _storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    try {
      _socketService.emitOffline();
    } catch (_) {}
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken: refreshToken);
      } catch (_) {}
    }
    await _storage.clear();
  }
}
