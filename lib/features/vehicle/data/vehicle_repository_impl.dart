import '../domain/entities/vehiculo.dart';
import '../domain/repositories/vehicle_repository.dart';
import 'remote/vehiculos_api.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._api);

  final VehiculosApi _api;

  @override
  Future<List<Vehiculo>> getVehiculos() async {
    final res = await _api.getVehiculos();
    final data = res['data'] as List<dynamic>? ?? [];
    return data.map((e) => _mapVehiculo(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> registrarVehiculo(Vehiculo vehiculo) async {
    await _api.registrarVehiculo({
      'placa': vehiculo.placa,
      'marca': vehiculo.marca,
      'modelo': vehiculo.modelo,
      'color': vehiculo.color,
      'anio': vehiculo.anio,
      'municipio': vehiculo.municipio,
    });
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await _api.actualizarVehiculo(vehiculo.placa, {
      'marca': vehiculo.marca,
      'modelo': vehiculo.modelo,
      'color': vehiculo.color,
      'anio': vehiculo.anio,
      'municipio': vehiculo.municipio,
    });
  }

  @override
  Future<void> eliminarVehiculo(String placa) async {
    await _api.eliminarVehiculo(placa);
  }

  Vehiculo _mapVehiculo(Map<String, dynamic> json) {
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

  VehicleStatus _mapStatus(String status) {
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
