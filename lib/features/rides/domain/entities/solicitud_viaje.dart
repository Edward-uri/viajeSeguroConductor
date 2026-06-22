class SolicitudViaje {
  final String id;
  final String pasajeroNombre;
  final String pasajeroIniciales;
  final double pasajeroCalificacion;
  final double monto;
  final String metodoPago;
  final double distanciaKm;
  final int duracionMin;
  final String origen;
  final String destino;
  final String origenDistancia;
  final double? origenLat;
  final double? origenLng;
  final double? destinoLat;
  final double? destinoLng;

  const SolicitudViaje({
    required this.id,
    required this.pasajeroNombre,
    required this.pasajeroIniciales,
    required this.pasajeroCalificacion,
    required this.monto,
    required this.metodoPago,
    required this.distanciaKm,
    required this.duracionMin,
    required this.origen,
    required this.destino,
    required this.origenDistancia,
    this.origenLat,
    this.origenLng,
    this.destinoLat,
    this.destinoLng,
  });
}

class DriverStats {
  final double gananciasHoy;
  final int viajesHoy;
  final double horasEnLinea;

  const DriverStats({
    required this.gananciasHoy,
    required this.viajesHoy,
    required this.horasEnLinea,
  });
}
