import '../entities/ride_history_item.dart';
import '../entities/solicitud_viaje.dart';

abstract class RidesRepository {
  Future<DriverStats> getStats();
  Future<List<RideHistoryItem>> getAssignedRides();

  @Deprecated('Usa getPendingTrips() + selección local. Este método devuelve '
      'el primer viaje pendiente, lo cual no representa una "solicitud actual".')
  Future<SolicitudViaje?> getCurrentRequest();

  Future<List<SolicitudViaje>> getPendingTrips();
  Future<SolicitudViaje?> getViajeActivoConductor();
  Future<SolicitudViaje> getRideById(String rideId);
  Future<void> acceptRide(String rideId, {required int idVehiculo});
  Future<void> rejectRide(String rideId);
  Future<void> soltarViaje(String rideId);
  Future<void> startRide(String rideId);
  Future<void> completeRide(String rideId);
  Future<void> cancelRide(String rideId, {String? motivo});
  Future<void> rateRide(String rideId, {required int calificacion, String? comentario});
  Future<void> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  });
  Future<void> registerDevice({
    required String tokenFcm,
    required String plataforma,
  });
}
