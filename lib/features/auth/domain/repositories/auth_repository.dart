import '../entities/register_params.dart';

abstract class AuthRepository {
  Future<void> registerStart({required String correo, required String rol});

  Future<String> registerVerify({
    required String correo,
    required String codigo,
    required String rol,
  });

  Future<void> registerComplete({
    required String registrationToken,
    required RegisterParams params,
  });

  Future<void> loginStart({required String correo});

  Future<void> loginVerify({
    required String correo,
    required String codigo,
  });

  Future<void> loginPassword({
    required String correo,
    required String password,
  });

  Future<bool> hasSession();

  Future<void> logout();

  Future<void> guardarLicencia({
    required int idMunicipio,
    required String licencia,
    required String licenciaFechaExpedicion,
    required String licenciaFechaVencimiento,
  });
}
