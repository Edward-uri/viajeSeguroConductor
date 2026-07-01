import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';
import '../models/heat_zone.dart';

class HeatmapApi {
  HeatmapApi(this._api);

  final ApiClient _api;

    /// Devuelve la respuesta cruda del backend sin parsear a [HeatZone].
  /// Útil para pasar los datos a un isolate con [Isolate.run].
  Future<List<Map<String, dynamic>>> fetchZonasRaw({
    required int diaSemana,
    required int hora,
  }) async {
    final res = await _api.get(
      ApiEndpoints.zonasCalientes(diaSemana, hora),
      auth: true,
    );
    final zonas = res['zonas'] as List<dynamic>? ?? [];
    return zonas.cast<Map<String, dynamic>>();
  }

  /// Pide las zonas al backend (proxy del modelo). El municipio lo deriva el
  /// servidor del conductor; aquí solo se envía el día/hora locales.
  Future<List<HeatZone>> fetchZonas({
    required int diaSemana,
    required int hora,
  }) async {
    final raw = await fetchZonasRaw(diaSemana: diaSemana, hora: hora);
    return raw.map((z) => HeatZone.fromJson(z)).toList();
  }
}
