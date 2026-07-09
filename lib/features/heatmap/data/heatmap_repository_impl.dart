import '../data/models/heat_zone.dart';
import '../domain/repositories/heatmap_repository.dart';
import 'remote/heatmap_api.dart';

class HeatmapRepositoryImpl implements HeatmapRepository {
  HeatmapRepositoryImpl(this._api);

  final HeatmapApi _api;

  // Flutter: DateTime.now().weekday → 1=lun, 7=dom
  // API:     dia_semana           → 0=lun, 6=dom
  int get _diaSemana => DateTime.now().weekday - 1;
  int get _hora => DateTime.now().hour;

  @override
  Future<List<HeatZone>> getZonasCalientes(int municipio) async {
    return _api.fetchZonas(diaSemana: _diaSemana, hora: _hora);
  }

  @override
  Future<List<Map<String, dynamic>>> getZonasCalientesRaw(int municipio) async {
    return _api.fetchZonasRaw(diaSemana: _diaSemana, hora: _hora);
  }
}
