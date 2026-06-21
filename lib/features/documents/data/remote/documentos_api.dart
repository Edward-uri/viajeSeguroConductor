import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class DocumentosApi {
  DocumentosApi(this._api);

  final ApiClient _api;

  static String _endpointForTipo(String tipo) {
    debugPrint('[DocumentosApi] tipo a subir: "$tipo"');
    switch (tipo) {
      case 'licencia':
        return ApiEndpoints.conductorDocumentosLicencia;
      case 'ine-frente':
        return ApiEndpoints.conductorDocumentosIneFrente;
      case 'ine-reverso':
        return ApiEndpoints.conductorDocumentosIneReverso;
      case 'tarjeta-circulacion':
        return ApiEndpoints.conductorDocumentosTarjetaCirculacion;
      case 'foto-vehiculo':
        return ApiEndpoints.conductorDocumentosFotoVehiculo;
      default:
        debugPrint('[DocumentosApi] tipo desconocido "$tipo" — usando licencia');
        return ApiEndpoints.conductorDocumentosLicencia;
    }
  }

  Future<Map<String, dynamic>> getDocumentos() =>
      _api.get(ApiEndpoints.conductorOnboarding, auth: true);

  Future<Map<String, dynamic>> subirDocumento({
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) =>
      _api.multipartPost(
        _endpointForTipo(tipo),
        bytes: bytes,
        fieldName: 'archivo',
        fileName: fileName,
        contentType: MediaType('image', 'jpeg'),
        auth: true,
      );

  Future<void> crearConductor() async {
    final now = DateTime.now();
    final exp =
        '${now.year - 5}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ven =
        '${now.year + 5}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _api.post(ApiEndpoints.conductorOnboardingLicencia, body: {
      'idMunicipio': 1,
      'licencia': 'PENDIENTE',
      'licenciaFechaExpedicion': exp,
      'licenciaFechaVencimiento': ven,
    }, auth: true);
  }
}
