import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class BolsaApi {
  BolsaApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getVacantes(int idMunicipio) =>
      _api.get(ApiEndpoints.bolsaVacantes(idMunicipio));

  // ponytail: sin campo mensaje — la UI minimalista no lo captura; el backend lo acepta opcional.
  Future<Map<String, dynamic>> postular(int idVacante) => _api.post(
        ApiEndpoints.bolsaPostular(idVacante),
        body: const <String, dynamic>{},
        auth: true,
      );

  Future<Map<String, dynamic>> getMisPostulaciones() =>
      _api.get(ApiEndpoints.bolsaMisPostulaciones);

  Future<void> retirarPostulacion(int idPostulacion) =>
      _api.delete(ApiEndpoints.bolsaPostulacion(idPostulacion));

  // ───── Dueño ─────

  Future<Map<String, dynamic>> crearVacante(
    int idVehiculo,
    String? condiciones,
  ) =>
      _api.post(
        ApiEndpoints.bolsaCrearVacante,
        body: <String, dynamic>{
          'idVehiculo': idVehiculo,
          if (condiciones != null && condiciones.isNotEmpty)
            'condiciones': condiciones,
        },
        auth: true,
      );

  Future<Map<String, dynamic>> getMisVacantes() =>
      _api.get(ApiEndpoints.bolsaMisVacantes);

  Future<Map<String, dynamic>> cerrarVacante(int idVacante) => _api.post(
        ApiEndpoints.bolsaCerrarVacante(idVacante),
        body: const <String, dynamic>{},
        auth: true,
      );

  Future<Map<String, dynamic>> getPostulacionesDeVacante(int idVacante) =>
      _api.get(ApiEndpoints.bolsaPostulacionesDeVacante(idVacante));

  Future<Map<String, dynamic>> aceptarPostulacion(int idPostulacion) =>
      _api.post(
        ApiEndpoints.bolsaAceptarPostulacion(idPostulacion),
        body: const <String, dynamic>{},
        auth: true,
      );
}
