import '../domain/entities/ride_history_item.dart';
import '../domain/entities/solicitud_viaje.dart';
import '../domain/repositories/rides_repository.dart';

class MockRidesRepository implements RidesRepository {
  @override
  Future<DriverStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const DriverStats(
      gananciasHoy: 340.00,
      viajesHoy: 8,
      horasEnLinea: 5.2,
    );
  }

  @override
  Future<List<RideHistoryItem>> getAssignedRides() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      const RideHistoryItem(
        id: '1',
        origen: 'Av. Hidalgo 123',
        destino: 'Primaria 5 de mayo',
        monto: 48.0,
        estado: 'completado',
        distanciaKm: 4.2,
      ),
      const RideHistoryItem(
        id: '2',
        origen: 'Parque Central',
        destino: 'Col. Linda Vista',
        monto: 35.0,
        estado: 'completado',
        distanciaKm: 3.1,
      ),
    ];
  }

  @override
  Future<SolicitudViaje?> getCurrentRequest() async {
    return const SolicitudViaje(
      id: '1',
      pasajeroNombre: 'Maria G.',
      pasajeroIniciales: 'MG',
      pasajeroCalificacion: 4.8,
      monto: 48.00,
      metodoPago: 'Efectivo',
      distanciaKm: 4.2,
      duracionMin: 12,
      origen: 'Av. Hidalgo 123',
      destino: 'Primaria 5 de mayo',
      origenDistancia: 'a 3 min de ti',
    );
  }

  @override
  Future<void> acceptRide(String rideId) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> rejectRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> startRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> completeRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
