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
      calificacion: 4.8,
      tasaAceptacion: 95,
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
    return SolicitudViaje(
      idViaje: 1,
      idPasajero: 7,
      idMunicipio: 1,
      tipoServicio: 'viaje',
      origenTexto: 'Av. Hidalgo 123',
      origenLat: 16.62,
      origenLng: -93.10,
      destinoTexto: 'Primaria 5 de mayo',
      destinoLat: 16.60,
      destinoLng: -93.12,
      distanciaKm: 4.2,
      tarifa: 48.00,
      tarifaEstimada: false,
      estado: 'solicitado',
      fechaSolicitud: DateTime.now().toIso8601String(),
      pasajeroNombre: 'María',
      pasajeroApellido: 'García',
      pasajeroCalificacion: 4.8,
      metodoPago: 'Efectivo',
      duracionMin: 12,
      origenDistancia: '0.5 km',
    );
  }

  @override
  Future<SolicitudViaje> getRideById(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SolicitudViaje(
      idViaje: int.tryParse(rideId) ?? 0,
      idPasajero: 7,
      idMunicipio: 1,
      tipoServicio: 'viaje',
      origenTexto: 'Av. Hidalgo 123',
      destinoTexto: 'Primaria 5 de mayo',
      distanciaKm: 4.2,
      tarifa: 48.00,
      tarifaEstimada: false,
      estado: 'aceptado',
      fechaSolicitud: DateTime.now().toIso8601String(),
      pasajeroNombre: 'María',
      pasajeroApellido: 'García',
    );
  }

  @override
  Future<void> acceptRide(String rideId, {required int idVehiculo}) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> rejectRide(String rideId) async {
    await Future.delayed(const Duration(milliseconds: 300));
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
  Future<void> cancelRide(String rideId, {String? motivo}) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> rateRide(String rideId, {required int calificacion, String? comentario}) async {
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

  @override
  Future<void> registerDevice({
    required String tokenFcm,
    required String plataforma,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
