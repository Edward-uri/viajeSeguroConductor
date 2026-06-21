abstract class SessionService {
  Future<bool> hasSession();

  Future<void> logout();
}
