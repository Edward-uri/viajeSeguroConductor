import 'package:flutter/material.dart';

/// Estados que devuelve el backend; [desconocido] tolera valores nuevos.
enum EstadoPostulacion { pendiente, aceptada, rechazada, retirada, desconocido }

/// Label/color de UI para las pantallas del dueño (mismos valores que
/// BolsaViewModel usa para el conductor; se comparten aquí para no duplicar
/// el switch en un viewmodel nuevo).
extension EstadoPostulacionUi on EstadoPostulacion {
  String get label {
    switch (this) {
      case EstadoPostulacion.pendiente:
        return 'Pendiente';
      case EstadoPostulacion.aceptada:
        return 'Aceptada';
      case EstadoPostulacion.rechazada:
        return 'Rechazada';
      case EstadoPostulacion.retirada:
        return 'Retirada';
      case EstadoPostulacion.desconocido:
        return 'N/A';
    }
  }

  Color get color {
    switch (this) {
      case EstadoPostulacion.pendiente:
        return const Color(0xFFE8A317);
      case EstadoPostulacion.aceptada:
        return const Color(0xFF1E8E5A);
      case EstadoPostulacion.rechazada:
        return const Color(0xFFD84315);
      case EstadoPostulacion.retirada:
      case EstadoPostulacion.desconocido:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Postulación propia (GET /api/bolsa/mis-postulaciones) o, para el dueño,
/// item de GET /api/bolsa/vacantes/:id/postulaciones (trae [conductorNombre]
/// / [conductorCalificacion] / [conductorFotoUrl] — shape público, sin
/// teléfono, mismo patrón que PersonaParte en viajes).
class Postulacion {
  final int idPostulacion;
  final int idVacante;
  final EstadoPostulacion estado;
  final String? mensaje;
  final int idVehiculo;
  final int idMunicipio;

  /// 'abierta' | 'cerrada'; '' si el endpoint no la incluye.
  final String estadoVacante;

  final String? conductorNombre;
  final double? conductorCalificacion;
  final String? conductorFotoUrl;

  const Postulacion({
    required this.idPostulacion,
    required this.idVacante,
    required this.estado,
    this.mensaje,
    this.idVehiculo = 0,
    this.idMunicipio = 0,
    this.estadoVacante = '',
    this.conductorNombre,
    this.conductorCalificacion,
    this.conductorFotoUrl,
  });

  bool get puedeRetirar => estado == EstadoPostulacion.pendiente;
}
