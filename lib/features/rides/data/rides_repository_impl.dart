import '../domain/entities/ride_history_item.dart';
import '../domain/entities/solicitud_viaje.dart';
import '../domain/repositories/rides_repository.dart';
import 'mappers/driver_stats_mapper.dart';
import 'mappers/ride_history_mapper.dart';
import 'mappers/solicitud_viaje_mapper.dart';
import 'remote/rides_api.dart';

class RidesRepositoryImpl implements RidesRepository {
  RidesRepositoryImpl(this._api);

  final RidesApi _api;

  @override
  Future<DriverStats> getStats() async {
    try {
      final res = await _api.getStats();
      final data = res['data'] as Map<String, dynamic>? ?? res;
      return DriverStatsMapper.fromJson(data);
    } catch (_) {
      return const DriverStats(gananciasHoy: 0, viajesHoy: 0, horasEnLinea: 0);
    }
  }

  @override
  Future<List<RideHistoryItem>> getAssignedRides() async {
    try {
      final res = await _api.getAssignedRides();
      final data = res['data'];
      if (data is! List) return [];
      return data
          .map((e) => RideHistoryMapper.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
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

  @override
  Future<void> startRide(String rideId) async {
    await _api.startRide(rideId);
  }

  @override
  Future<void> completeRide(String rideId) async {
    await _api.completeRide(rideId);
  }

  @override
  Future<void> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  }) async {
    await _api.toggleAvailability(
      disponible: disponible,
      lat: lat,
      lng: lng,
    );
  }
}
