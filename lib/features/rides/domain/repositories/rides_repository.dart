import '../entities/solicitud_viaje.dart';

abstract class RidesRepository {
  Future<DriverStats> getStats();
  Future<SolicitudViaje?> getCurrentRequest();
  Future<void> acceptRide(String rideId);
  Future<void> rejectRide(String rideId);
}
