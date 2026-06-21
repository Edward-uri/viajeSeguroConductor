import '../domain/entities/solicitud_viaje.dart';
import '../domain/repositories/rides_repository.dart';
import 'mappers/driver_stats_mapper.dart';
import 'mappers/solicitud_viaje_mapper.dart';
import 'remote/rides_api.dart';

class RidesRepositoryImpl implements RidesRepository {
  RidesRepositoryImpl(this._api);

  final RidesApi _api;

  @override
  Future<DriverStats> getStats() async {
    final res = await _api.getStats();
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return DriverStatsMapper.fromJson(data);
  }

  @override
  Future<SolicitudViaje?> getCurrentRequest() async {
    try {
      final res = await _api.getPendingRides();
      final data = res['data'];
      if (data == null) return null;

      final list = data is List ? data : [data];
      if (list.isEmpty) return null;

      final first = list.first as Map<String, dynamic>;
      return SolicitudViajeMapper.fromJson(first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> acceptRide(String rideId) async {
    await _api.acceptRide(rideId);
  }

  @override
  Future<void> rejectRide(String rideId) async {
    await _api.rejectRide(rideId);
  }
}
