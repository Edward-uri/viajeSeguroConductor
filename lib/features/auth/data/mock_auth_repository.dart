import '../../../core/storage/auth_storage.dart';
import '../../../shared/domain/entities/user.dart';
import '../domain/entities/register_params.dart';
import '../domain/repositories/auth_repository.dart';


class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._storage);

  final AuthStorage _storage;

  @override
  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.writeToken(token);
    return User(
      idUsuario: 1,
      nombreUsuario: identifier,
      rol: 'pasajero',
      estadoCuenta: 'activo',
      fechaRegistro: DateTime.now(),
    );
  }

  @override
  Future<User> register(RegisterParams params) async {
    final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.writeToken(token);
    return User(
      idUsuario: 1,
      nombreUsuario: params.nombreUsuario,
      rol: params.rol,
      estadoCuenta: 'activo',
      fechaRegistro: DateTime.now(),
    );
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<bool> hasSession() async {
    final token = await _storage.readToken();
    return token != null && token.isNotEmpty;
  }
}
