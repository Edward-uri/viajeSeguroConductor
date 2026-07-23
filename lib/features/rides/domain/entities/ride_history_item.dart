class RideHistoryItem {
  final String id;
  final String origen;
  final String destino;
  final double monto;
  final String estado;
  final double? distanciaKm;
  final DateTime? fecha;
  final double? origenLat;
  final double? origenLng;
  final double? destinoLat;
  final double? destinoLng;

  const RideHistoryItem({
    required this.id,
    required this.origen,
    required this.destino,
    required this.monto,
    required this.estado,
    this.distanciaKm,
    this.fecha,
    this.origenLat,
    this.origenLng,
    this.destinoLat,
    this.destinoLng,
  });
}

/// Una página del historial (contrato de paginación del backend).
class RideHistoryPage {
  final List<RideHistoryItem> items;
  final int page;
  final int totalPages;
  final int total;

  const RideHistoryPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}
