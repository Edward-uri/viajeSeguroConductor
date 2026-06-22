import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> registerStart({
    required String correo,
    required String rol,
  }) =>
      _api.post(ApiEndpoints.registerStart, body: {
        'correo': correo,
        'rol': rol,
      });

  Future<Map<String, dynamic>> registerVerify({
    required String correo,
    required String codigo,
    required String rol,
  }) =>
      _api.post(ApiEndpoints.registerVerify, body: {
        'correo': correo,
        'codigo': codigo,
        'rol': rol,
      });

  Future<Map<String, dynamic>> registerComplete({
    required String registrationToken,
    required Map<String, dynamic> data,
  }) =>
      _api.post(ApiEndpoints.registerComplete, body: {
        'registrationToken': registrationToken,
        ...data,
      });

  Future<Map<String, dynamic>> loginStart({
    required String correo,
  }) =>
      _api.post(ApiEndpoints.loginStart, body: {
        'correo': correo,
      });

  Future<Map<String, dynamic>> loginVerify({
    required String correo,
    required String codigo,
    String? dispositivo,
  }) =>
      _api.post(ApiEndpoints.loginVerify, body: {
        'correo': correo,
        'codigo': codigo,
        if (dispositivo != null) 'dispositivo': dispositivo,
      });

  Future<Map<String, dynamic>> loginPassword({
    required String correo,
    required String password,
    String? dispositivo,
  }) =>
      _api.post(ApiEndpoints.loginPassword, body: {
        'correo': correo,
        'password': password,
        if (dispositivo != null) 'dispositivo': dispositivo,
      });

  Future<void> logout({
    required String refreshToken,
  }) =>
      _api.post(ApiEndpoints.logout, body: {
        'refreshToken': refreshToken,
      });

  Future<Map<String, dynamic>> guardarLicencia({
    required int idMunicipio,
    required String licencia,
    required String licenciaFechaExpedicion,
    required String licenciaFechaVencimiento,
  }) =>
      _api.post(ApiEndpoints.conductorOnboardingLicencia, body: {
        'idMunicipio': idMunicipio,
        'licencia': licencia,
        'licenciaFechaExpedicion': licenciaFechaExpedicion,
        'licenciaFechaVencimiento': licenciaFechaVencimiento,
      }, auth: true);
}
