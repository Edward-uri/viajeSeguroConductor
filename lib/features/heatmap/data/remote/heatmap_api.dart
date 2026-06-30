import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';
import '../models/heat_zone.dart';

class HeatmapApi {
  HeatmapApi(this._api);

  final ApiClient _api;

  /// Pide las zonas al backend (proxy del modelo). El municipio lo deriva el
  /// servidor del conductor; aquí solo se envía el día/hora locales.
  Future<List<HeatZone>> fetchZonas({
    required int diaSemana,
    required int hora,
  }) async {
    final res = await _api.get(
      ApiEndpoints.zonasCalientes(diaSemana, hora),
      auth: true,
    );
    final zonas = res['zonas'] as List<dynamic>? ?? [];
    return zonas
        .map((z) => HeatZone.fromJson(z as Map<String, dynamic>))
        .toList();
  }
}
