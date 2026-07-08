import '../../domain/entities/vehiculo.dart';

class VehiculoMapper {
  const VehiculoMapper._();

  /// Lee la forma que devuelve el backend (GET /api/flotillas/vehiculos):
  /// { idVehiculo, placa, modelo, color, anio, idMunicipio, estadoVerificacion, origen }
  static Vehiculo fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      idVehiculo: (json['idVehiculo'] as num?)?.toInt() ?? 0,
      placa: json['placa']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      anio: (json['anio'] as num?)?.toInt() ?? 0,
      idMunicipio: (json['idMunicipio'] as num?)?.toInt() ?? 0,
      status: _mapStatus(json['estadoVerificacion']?.toString() ?? ''),
      rfc: json['rfc']?.toString(),
      razonSocial: json['razonSocial']?.toString(),
      activo: json['activo'] == true,
    );
  }

  /// Cuerpo que espera POST/PATCH /api/flotillas/vehiculos: sin marca ni nombre de municipio.
  static Map<String, dynamic> toJson(Vehiculo vehiculo) {
    return {
      'placa': vehiculo.placa,
      'modelo': vehiculo.modelo,
      'color': vehiculo.color,
      'anio': vehiculo.anio,
      'idMunicipio': vehiculo.idMunicipio,
    };
  }

  /// estadoVerificacion del backend → status de UI.
  static VehicleStatus _mapStatus(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado':
        return VehicleStatus.active;
      case 'en_revision':
        return VehicleStatus.reviewing;
      case 'rechazado':
      case 'incompleto':
      default:
        return VehicleStatus.incomplete;
    }
  }
}
