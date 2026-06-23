import '../../domain/entities/solicitud_viaje.dart';

class SolicitudViajeMapper {
  const SolicitudViajeMapper._();

  static Map<String, dynamic> _extractOrigenDestino(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    return <String, dynamic>{};
  }

  static SolicitudViaje fromJson(Map<String, dynamic> json) {
    final origenRaw = _extractOrigenDestino(json['origen']);
    final destinoRaw = _extractOrigenDestino(json['destino']);
    final pasajeroRaw = json['pasajero'] as Map<String, dynamic>?;

    return SolicitudViaje(
      idViaje: (json['idViaje'] as num?)?.toInt() ?? 0,
      idPasajero: (json['idPasajero'] as num?)?.toInt() ?? 0,
      idConductor: (json['idConductor'] as num?)?.toInt(),
      idVehiculo: (json['idVehiculo'] as num?)?.toInt(),
      idMunicipio: (json['idMunicipio'] as num?)?.toInt() ?? 0,
      tipoServicio: json['tipoServicio']?.toString() ?? 'viaje',
      origenTexto: origenRaw['texto']?.toString(),
      origenLat: (origenRaw['lat'] as num?)?.toDouble(),
      origenLng: (origenRaw['lng'] as num?)?.toDouble(),
      destinoTexto: destinoRaw['texto']?.toString(),
      destinoLat: (destinoRaw['lat'] as num?)?.toDouble(),
      destinoLng: (destinoRaw['lng'] as num?)?.toDouble(),
      idZonaDestino: (json['idZonaDestino'] as num?)?.toInt(),
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble() ?? 0,
      tarifa: (json['tarifa'] as num?)?.toDouble() ?? 0,
      tarifaEstimada: json['tarifaEstimada'] == true,
      estado: json['estado']?.toString() ?? 'solicitado',
      fechaSolicitud: json['fechaSolicitud']?.toString() ?? '',
      fechaAceptacion: json['fechaAceptacion']?.toString(),
      fechaInicio: json['fechaInicio']?.toString(),
      fechaFin: json['fechaFin']?.toString(),
      canceladoPor: json['canceladoPor']?.toString(),
      motivoCancelacion: json['motivoCancelacion']?.toString(),
      pasajeroNombre: pasajeroRaw?['nombre']?.toString() ?? '',
      pasajeroApellido: pasajeroRaw?['apellidoPaterno']?.toString() ?? '',
      pasajeroCalificacion: (pasajeroRaw?['calificacion'] as num?)?.toDouble() ?? 0,
      metodoPago: json['metodoPago']?.toString() ?? 'Efectivo',
      duracionMin: (json['duracionEstimada'] as num?)?.toInt() ?? 0,
      origenDistancia: json['origenDistancia']?.toString() ?? '',
    );
  }
}
