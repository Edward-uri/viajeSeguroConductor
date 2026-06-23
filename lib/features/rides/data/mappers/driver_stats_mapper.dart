import '../../domain/entities/solicitud_viaje.dart';

class DriverStatsMapper {
  const DriverStatsMapper._();

  static DriverStats fromJson(Map<String, dynamic> json) {
    return DriverStats(
      gananciasHoy: (json['gananciasHoy'] as num?)?.toDouble() ?? 0,
      viajesHoy: (json['viajesHoy'] as num?)?.toInt() ?? 0,
      horasEnLinea: (json['horasEnLinea'] as num?)?.toDouble() ?? 0,
      calificacion: (json['calificacion'] as num?)?.toDouble(),
      tasaAceptacion: (json['tasaAceptacion'] as num?)?.toDouble(),
    );
  }
}
