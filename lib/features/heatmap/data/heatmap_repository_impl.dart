import '../data/models/heat_zone.dart';
import '../domain/repositories/heatmap_repository.dart';
import 'remote/heatmap_api.dart';

class HeatmapRepositoryImpl implements HeatmapRepository {
  HeatmapRepositoryImpl(this._api);

  final HeatmapApi _api;

  @override
  Future<List<HeatZone>> getZonasCalientes(int municipio) async {
    // Flutter: DateTime.now().weekday → 1=lun, 7=dom
    // API:     dia_semana           → 0=lun, 6=dom
    final now = DateTime.now();
    final diaSemana = now.weekday - 1;
    final hora = now.hour;

    return _api.fetchZonas(
      municipio: municipio,
      diaSemana: diaSemana,
      hora: hora,
    );
  }
}
