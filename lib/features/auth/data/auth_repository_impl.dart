import '../../../core/http/api_exception.dart';
import '../../../core/storage/auth_storage.dart';
import '../domain/entities/register_params.dart';
import '../domain/repositories/auth_repository.dart';
import 'mappers/register_params_mapper.dart';
import 'remote/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._storage);

  final AuthApi _api;
  final AuthStorage _storage;

  @override
  Future<void> registerStart({
    required String correo,
    required String rol,
  }) async {
    await _api.registerStart(correo: correo, rol: rol);
  }

  @override
  Future<String> registerVerify({
    required String correo,
    required String codigo,
    required String rol,
  }) async {
    final response = await _api.registerVerify(
      correo: correo,
      codigo: codigo,
      rol: rol,
    );
    final token = response['registrationToken'] as String?;
    if (token == null) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    return token;
  }

  @override
  Future<void> registerComplete({
    required String registrationToken,
    required RegisterParams params,
  }) async {
    final response = await _api.registerComplete(
      registrationToken: registrationToken,
      data: RegisterParamsMapper.toJson(params),
    );
    await _persistSession(response);
  }

  @override
  Future<void> loginStart({required String correo}) async {
    await _api.loginStart(correo: correo);
  }

  @override
  Future<void> loginVerify({
    required String correo,
    required String codigo,
  }) async {
    final response = await _api.loginVerify(correo: correo, codigo: codigo);
    await _persistSession(response);
  }

  @override
  Future<void> loginPassword({
    required String correo,
    required String password,
  }) async {
    final response = await _api.loginPassword(
      correo: correo,
      password: password,
    );
    await _persistSession(response);
  }

  @override
  Future<bool> hasSession() async {
    final token = await _storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.logout(refreshToken: refreshToken);
      } catch (_) {}
    }
    await _storage.clear();
  }

  @override
  Future<void> guardarLicencia({
    required int idMunicipio,
    required String licencia,
    required String licenciaFechaExpedicion,
    required String licenciaFechaVencimiento,
  }) async {
    await _api.guardarLicencia(
      idMunicipio: idMunicipio,
      licencia: licencia,
      licenciaFechaExpedicion: licenciaFechaExpedicion,
      licenciaFechaVencimiento: licenciaFechaVencimiento,
    );
  }

  Future<void> _persistSession(Map<String, dynamic> response) async {
    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    await _storage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
