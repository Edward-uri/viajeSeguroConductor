import 'package:flutter/material.dart';

import '../../../../theme/jala_theme.dart';

/// Estados que devuelve el backend; [desconocido] tolera valores nuevos.
enum EstadoPostulacion { pendiente, aceptada, rechazada, retirada, desconocido }

/// Label/color de UI compartidos por las pantallas del dueño y del conductor
/// (única fuente; sin BuildContext, por eso constantes estáticas de marca).
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
        return JalaBrand.warning;
      case EstadoPostulacion.aceptada:
        return JalaBrand.success;
      case EstadoPostulacion.rechazada:
        return JalaBrand.destructive;
      case EstadoPostulacion.retirada:
      case EstadoPostulacion.desconocido:
        return JalaBrand.greyLight;
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
