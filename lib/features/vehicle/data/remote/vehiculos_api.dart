import 'dart:typed_data';

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

  Future<Map<String, dynamic>> subirDocumentoVehiculo({
    required String placa,
    required Uint8List bytes,
    required String fileName,
    required String tipo,
  }) =>
      _api.multipartPost(
        ApiEndpoints.flotillasVehiculoDocumentos(placa),
        bytes: bytes,
        fieldName: tipo,
        fileName: fileName,
        auth: true,
      );

  Future<Map<String, dynamic>> getDatosFacturacion() =>
      _api.get(ApiEndpoints.flotillasFacturacion);

  Future<Map<String, dynamic>> guardarDatosFacturacion(
    Map<String, dynamic> data,
  ) =>
      _api.put(ApiEndpoints.flotillasFacturacion, body: data);
}
