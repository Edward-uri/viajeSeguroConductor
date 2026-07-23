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
      fecha: DateTime.tryParse(json['fechaSolicitud']?.toString() ?? '')?.toLocal(),
      origenLat: extractLat(origenRaw),
      origenLng: extractLng(origenRaw),
      destinoLat: extractLat(destinoRaw),
      destinoLng: extractLng(destinoRaw),
    );
  }

  /// Página del historial: GET /api/viajes/historial → { data, page, totalPages, total }.
  static RideHistoryPage pageFromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final items = data is List
        ? data
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList()
        : <RideHistoryItem>[];
    return RideHistoryPage(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }
}
