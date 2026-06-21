import '../domain/entities/solicitud_viaje.dart';
import '../domain/repositories/rides_repository.dart';
import 'remote/rides_api.dart';

class RidesRepositoryImpl implements RidesRepository {
  RidesRepositoryImpl(this._api);

  final RidesApi _api;

  @override
  Future<DriverStats> getStats() async {
    final res = await _api.getStats();
    final data = res['data'] as Map<String, dynamic>? ?? res;
    return DriverStats(
      gananciasHoy: (data['gananciasHoy'] as num?)?.toDouble() ?? 0,
      viajesHoy: (data['viajesHoy'] as num?)?.toInt() ?? 0,
      horasEnLinea: (data['horasEnLinea'] as num?)?.toDouble() ?? 0,
    );
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
      return _mapSolicitud(first);
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

  SolicitudViaje _mapSolicitud(Map<String, dynamic> json) {
    return SolicitudViaje(
      id: json['id']?.toString() ?? '',
      pasajeroNombre: json['pasajeroNombre']?.toString() ?? '',
      pasajeroIniciales: json['pasajeroIniciales']?.toString() ?? '',
      pasajeroCalificacion: (json['pasajeroCalificacion'] as num?)?.toDouble() ?? 0,
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodoPago: json['metodoPago']?.toString() ?? 'Efectivo',
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble() ?? 0,
      duracionMin: (json['duracionMin'] as num?)?.toInt() ?? 0,
      origen: json['origen']?.toString() ?? '',
      destino: json['destino']?.toString() ?? '',
      origenDistancia: json['origenDistancia']?.toString() ?? '',
    );
  }
}
