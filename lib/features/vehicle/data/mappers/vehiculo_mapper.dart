import '../../domain/entities/vehiculo.dart';

class VehiculoMapper {
  const VehiculoMapper._();

  static Vehiculo fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      placa: json['placa']?.toString() ?? '',
      marca: json['marca']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      anio: (json['anio'] as num?)?.toInt() ?? 0,
      municipio: json['municipio']?.toString() ?? '',
      status: _mapStatus(json['status']?.toString() ?? ''),
      rfc: json['rfc']?.toString(),
      razonSocial: json['razonSocial']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(Vehiculo vehiculo) {
    return {
      'placa': vehiculo.placa,
      'marca': vehiculo.marca,
      'modelo': vehiculo.modelo,
      'color': vehiculo.color,
      'anio': vehiculo.anio,
      'municipio': vehiculo.municipio,
    };
  }

  static VehicleStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return VehicleStatus.active;
      case 'incomplete':
        return VehicleStatus.incomplete;
      case 'reviewing':
        return VehicleStatus.reviewing;
      default:
        return VehicleStatus.incomplete;
    }
  }
}
