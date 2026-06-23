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
  final String pasajeroNombre;
  final String pasajeroApellido;
  final double pasajeroCalificacion;
  final String metodoPago;
  final int duracionMin;
  final String origenDistancia;

  String get pasajeroIniciales {
    if (pasajeroNombre.isEmpty) return '';
    final parts = pasajeroNombre.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return pasajeroNombre[0].toUpperCase();
  }

  String get nombreCompleto {
    if (pasajeroNombre.isEmpty) return '';
    return pasajeroApellido.isNotEmpty
        ? '$pasajeroNombre $pasajeroApellido'
        : pasajeroNombre;
  }

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
    this.pasajeroNombre = '',
    this.pasajeroApellido = '',
    this.pasajeroCalificacion = 0,
    this.metodoPago = 'Efectivo',
    this.duracionMin = 0,
    this.origenDistancia = '',
  }) : assert(idViaje >= 0);
}

class DriverStats {
  final double gananciasHoy;
  final int viajesHoy;
  final double horasEnLinea;
  final double? calificacion;
  final double? tasaAceptacion;

  const DriverStats({
    required this.gananciasHoy,
    required this.viajesHoy,
    required this.horasEnLinea,
    this.calificacion,
    this.tasaAceptacion,
  });
}
