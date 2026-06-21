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
