import '../../domain/entities/ride_history_item.dart';

class RideHistoryMapper {
  const RideHistoryMapper._();

  static RideHistoryItem fromJson(Map<String, dynamic> json) {
    final origenRaw = json['origen'];
    final destinoRaw = json['destino'];

    String extractTexto(Object? raw) {
      if (raw is Map<String, dynamic>) {
        return raw['texto']?.toString() ?? 'N/A';
      }
      return 'N/A';
    }

    double? extractLat(Object? raw) {
      if (raw is Map<String, dynamic>) return (raw['lat'] as num?)?.toDouble();
      return null;
    }

    double? extractLng(Object? raw) {
      if (raw is Map<String, dynamic>) return (raw['lng'] as num?)?.toDouble();
      return null;
    }

    return RideHistoryItem(
      id: json['idViaje']?.toString() ?? '0',
      origen: extractTexto(origenRaw),
      destino: extractTexto(destinoRaw),
      monto: (json['tarifa'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado']?.toString() ?? 'desconocido',
      distanciaKm: (json['distanciaKm'] as num?)?.toDouble(),
      origenLat: extractLat(origenRaw),
      origenLng: extractLng(origenRaw),
      destinoLat: extractLat(destinoRaw),
      destinoLng: extractLng(destinoRaw),
    );
  }
}
