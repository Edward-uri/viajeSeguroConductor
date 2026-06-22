class RideHistoryItem {
  final String id;
  final String origen;
  final String destino;
  final double monto;
  final String estado;
  final double? distanciaKm;
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
    this.origenLat,
    this.origenLng,
    this.destinoLat,
    this.destinoLng,
  });
}
