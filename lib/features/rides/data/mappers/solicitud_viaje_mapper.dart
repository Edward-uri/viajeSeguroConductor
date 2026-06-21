import '../../domain/entities/solicitud_viaje.dart';

class SolicitudViajeMapper {
  const SolicitudViajeMapper._();

  static SolicitudViaje fromJson(Map<String, dynamic> json) {
    return SolicitudViaje(
      id: json['id']?.toString() ?? '',
      pasajeroNombre: json['pasajeroNombre']?.toString() ?? '',
      pasajeroIniciales: json['pasajeroIniciales']?.toString() ?? '',
      pasajeroCalificacion:
          (json['pasajeroCalificacion'] as num?)?.toDouble() ?? 0,
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
