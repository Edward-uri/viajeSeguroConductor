class SolicitudViaje {
  final int idViaje;
  final int idPasajero;
  final int? idConductor;
  final int? idVehiculo;
  final int idMunicipio;
  final String tipoServicio;
  final String? origenTexto;
  final double? origenLat;
  final double? origenLng;
  final String? destinoTexto;
  final double? destinoLat;
  final double? destinoLng;
  final int? idZonaDestino;
  final double distanciaKm;
  final double tarifa;
  final bool tarifaEstimada;
  final String estado;
  final String fechaSolicitud;
  final String? fechaAceptacion;
  final String? fechaInicio;
  final String? fechaFin;
  final String? canceladoPor;
  final String? motivoCancelacion;

  String get pasajeroNombre => '';

  String get pasajeroIniciales => '';

  double get pasajeroCalificacion => 0;

  String get metodoPago => 'Efectivo';

  int get duracionMin => 0;

  String get origenDistancia => '';

  String get origen => origenTexto ?? '';

  String get destino => destinoTexto ?? '';

  double get monto => tarifa;

  String get id => idViaje.toString();

  const SolicitudViaje({
    required this.idViaje,
    required this.idPasajero,
    this.idConductor,
    this.idVehiculo,
    required this.idMunicipio,
    required this.tipoServicio,
    this.origenTexto,
    this.origenLat,
    this.origenLng,
    this.destinoTexto,
    this.destinoLat,
    this.destinoLng,
    this.idZonaDestino,
    required this.distanciaKm,
    required this.tarifa,
    required this.tarifaEstimada,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaAceptacion,
    this.fechaInicio,
    this.fechaFin,
    this.canceladoPor,
    this.motivoCancelacion,
  }) : assert(idViaje >= 0);
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
