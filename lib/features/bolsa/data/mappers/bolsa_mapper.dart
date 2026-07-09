import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';

class BolsaMapper {
  const BolsaMapper._();

  /// Item de data en GET /api/bolsa/vacantes:
  /// { idVacante, idPropietario, idVehiculo, idMunicipio, condiciones,
  ///   estado, placa, modelo, color, anio }
  /// (idPropietario se ignora: sin PII de dueño).
  /// También sirve para GET /api/bolsa/mis-vacantes (dueño): mismo shape
  /// base + postulacionesPendientes, sin placa/modelo/color/anio.
  /// Y para POST /api/bolsa/vacantes y /cerrar (respuesta cruda, sin "data").
  static Vacante vacanteFromJson(Map<String, dynamic> json) {
    return Vacante(
      idVacante: (json['idVacante'] as num?)?.toInt() ?? 0,
      idVehiculo: (json['idVehiculo'] as num?)?.toInt() ?? 0,
      idMunicipio: (json['idMunicipio'] as num?)?.toInt() ?? 0,
      condiciones: json['condiciones']?.toString(),
      placa: json['placa']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      anio: (json['anio'] as num?)?.toInt() ?? 0,
      estado: json['estado']?.toString() ?? '',
      postulacionesPendientes:
          (json['postulacionesPendientes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Item de data en GET /api/bolsa/mis-postulaciones:
  /// { idPostulacion, idVacante, idConductor, estado, mensaje,
  ///   idVehiculo, idMunicipio, estadoVacante }
  /// También sirve para GET /api/bolsa/vacantes/:id/postulaciones (dueño):
  /// mismo shape base + conductor: { nombre, calificacion, fotoUrl }
  /// (shape público, sin teléfono).
  static Postulacion postulacionFromJson(Map<String, dynamic> json) {
    final conductor = json['conductor'] as Map<String, dynamic>?;
    return Postulacion(
      idPostulacion: (json['idPostulacion'] as num?)?.toInt() ?? 0,
      idVacante: (json['idVacante'] as num?)?.toInt() ?? 0,
      estado: _mapEstado(json['estado']?.toString() ?? ''),
      mensaje: json['mensaje']?.toString(),
      idVehiculo: (json['idVehiculo'] as num?)?.toInt() ?? 0,
      idMunicipio: (json['idMunicipio'] as num?)?.toInt() ?? 0,
      estadoVacante: json['estadoVacante']?.toString() ?? '',
      conductorNombre: conductor?['nombre']?.toString(),
      conductorCalificacion:
          (conductor?['calificacion'] as num?)?.toDouble(),
      conductorFotoUrl: conductor?['fotoUrl']?.toString(),
    );
  }

  /// estado del backend → enum de UI; valores nuevos no truenan.
  static EstadoPostulacion _mapEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return EstadoPostulacion.pendiente;
      case 'aceptada':
        return EstadoPostulacion.aceptada;
      case 'rechazada':
        return EstadoPostulacion.rechazada;
      case 'retirada':
        return EstadoPostulacion.retirada;
      default:
        return EstadoPostulacion.desconocido;
    }
  }
}
