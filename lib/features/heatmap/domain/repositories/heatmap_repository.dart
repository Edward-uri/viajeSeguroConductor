import '../../data/models/heat_zone.dart';

abstract class HeatmapRepository {
  Future<List<HeatZone>> getZonasCalientes(int municipio);
  Future<List<Map<String, dynamic>>> getZonasCalientesRaw(int municipio);
}
