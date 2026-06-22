import '../entities/ride_history_item.dart';
import '../entities/solicitud_viaje.dart';

abstract class RidesRepository {
  Future<DriverStats> getStats();
  Future<List<RideHistoryItem>> getAssignedRides();
  Future<SolicitudViaje?> getCurrentRequest();
  Future<void> acceptRide(String rideId);
  Future<void> rejectRide(String rideId);
  Future<void> startRide(String rideId);
  Future<void> completeRide(String rideId);
  Future<void> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  });
}
