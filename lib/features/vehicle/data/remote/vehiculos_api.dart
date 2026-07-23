import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class VehiculosApi {
  VehiculosApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getVehiculos() =>
      _api.get(ApiEndpoints.flotillasVehiculos);

  Future<Map<String, dynamic>> registrarVehiculo(
    Map<String, dynamic> data,
  ) =>
      _api.post(ApiEndpoints.flotillasVehiculos, body: data, auth: true);

  Future<Map<String, dynamic>> actualizarVehiculo(
    String placa,
    Map<String, dynamic> data,
  ) =>
      _api.put(ApiEndpoints.flotillasVehiculo(placa), body: data);

  Future<void> eliminarVehiculo(String placa) =>
      _api.delete(ApiEndpoints.flotillasVehiculo(placa));

  Future<Map<String, dynamic>> setVehiculoActivo(int idVehiculo) =>
      _api.patch(
        ApiEndpoints.flotillasVehiculoActivo,
        body: {'idVehiculo': idVehiculo},
      );

  /// [tipo] en kebab-case según la ruta del backend: 'tarjeta-circulacion' | 'foto-vehiculo'.
  Future<Map<String, dynamic>> subirDocumentoVehiculo({
    required int idVehiculo,
    required Uint8List bytes,
    required String fileName,
    required String tipo,
  }) =>
      _api.multipartPost(
        ApiEndpoints.flotillasVehiculoDocumento(idVehiculo, tipo),
        bytes: bytes,
        fieldName: 'archivo',
        fileName: fileName,
        contentType: MediaType('image', 'jpeg'),
        auth: true,
      );

  // ───── Conductores asignados (dueño) ─────

  Future<Map<String, dynamic>> getConductoresAsignados(int idVehiculo) =>
      _api.get(ApiEndpoints.flotillasVehiculoConductores(idVehiculo));

  Future<Map<String, dynamic>> editarConductorAsignado(
    int idVehiculo,
    int idConductor,
    Map<String, dynamic> body,
  ) =>
      _api.patch(
        ApiEndpoints.flotillasVehiculoConductor(idVehiculo, idConductor),
        body: body,
      );

  Future<void> darDeBajaConductor(int idVehiculo, int idConductor) =>
      _api.delete(ApiEndpoints.flotillasVehiculoConductor(idVehiculo, idConductor));

  Future<Map<String, dynamic>> getDatosFacturacion() =>
      _api.get(ApiEndpoints.flotillasFacturacion);

  Future<Map<String, dynamic>> guardarDatosFacturacion(
    Map<String, dynamic> data,
  ) =>
      _api.put(ApiEndpoints.flotillasFacturacion, body: data);
}
