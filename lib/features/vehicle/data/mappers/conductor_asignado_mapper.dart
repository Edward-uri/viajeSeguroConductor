import '../../domain/entities/conductor_asignado.dart';

class ConductorAsignadoMapper {
  const ConductorAsignadoMapper._();

  /// Item de data en GET /api/flotillas/vehiculos/:id/conductores:
  /// { idConductor, nombre, fotoUrl, calificacion, origen,
  ///   tipoTurno, rentaTurno, dias, horario }
  static ConductorAsignado fromJson(Map<String, dynamic> json) {
    return ConductorAsignado(
      idConductor: (json['idConductor'] as num?)?.toInt() ?? 0,
      nombre: json['nombre']?.toString(),
      fotoUrl: json['fotoUrl']?.toString(),
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      origen: json['origen']?.toString() ?? 'propia',
      tipoTurno: json['tipoTurno']?.toString() ?? '',
      rentaTurno: (json['rentaTurno'] as num?)?.toDouble(),
      dias: (json['dias'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      horario: json['horario']?.toString(),
    );
  }
}
