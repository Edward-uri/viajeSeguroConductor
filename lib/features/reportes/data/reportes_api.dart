import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../../../core/http/api_client.dart';
import '../../../core/http/api_endpoints.dart';

/// Reporta a la contraparte de un viaje. El backend deriva a quién se reporta
/// (y su rol) a partir de quién hace la petición. Un reporte basta para bloquear
/// mutuamente al par de forma permanente.
class ReportesApi {
  ReportesApi(this._api);

  final ApiClient _api;

  Future<void> reportar({
    required int idViaje,
    required String motivo,
    String? comentario,
  }) =>
      _api.post(
        ApiEndpoints.reportes,
        body: <String, dynamic>{
          'idViaje': idViaje,
          'motivo': motivo,
          if (comentario != null && comentario.trim().isNotEmpty)
            'comentario': comentario.trim(),
        },
        auth: true,
      );
}

final reportesApiProvider = Provider<ReportesApi>(
  (ref) => ReportesApi(ref.watch(apiClientProvider)),
);
