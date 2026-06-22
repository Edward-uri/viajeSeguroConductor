import '../../domain/entities/solicitud_viaje.dart';

class SolicitudViajeMapper {
  const SolicitudViajeMapper._();

  static SolicitudViaje fromJson(Map<String, dynamic> json) {
    final origenRaw = json['origen'];
    final destinoRaw = json['destino'];

    String extractTexto(Object? raw) {
      if (raw is Map<String, dynamic>) return raw['texto']?.toString() ?? '';
      return raw?.toString() ?? '';
    }

    double? extractLat(Object? raw) {
      if (raw is Map<String, dynamic>) return (raw['lat'] as num?)?.toDouble();
      return null;
    }

    double? extractLng(Object? raw) {
      if (raw is Map<String, dynamic>) return (raw['lng'] as num?)?.toDouble();
      return null;
    }

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
      origen: extractTexto(origenRaw),
      destino: extractTexto(destinoRaw),
      origenDistancia: json['origenDistancia']?.toString() ?? '',
      origenLat: extractLat(origenRaw),
      origenLng: extractLng(origenRaw),
      destinoLat: extractLat(destinoRaw),
      destinoLng: extractLng(destinoRaw),
    );
  }
}
