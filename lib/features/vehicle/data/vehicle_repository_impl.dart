import '../domain/entities/vehiculo.dart';
import '../domain/repositories/vehicle_repository.dart';
import 'mappers/vehiculo_mapper.dart';
import 'remote/vehiculos_api.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._api);

  final VehiculosApi _api;

  @override
  Future<List<Vehiculo>> getVehiculos() async {
    final res = await _api.getVehiculos();
    final data = res['data'] as List<dynamic>? ?? [];
    return data.map((e) => VehiculoMapper.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> registrarVehiculo(Vehiculo vehiculo) async {
    await _api.registrarVehiculo(VehiculoMapper.toJson(vehiculo));
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await _api.actualizarVehiculo(vehiculo.placa, VehiculoMapper.toJson(vehiculo));
  }

  @override
  Future<void> eliminarVehiculo(String placa) async {
    await _api.eliminarVehiculo(placa);
  }
}
