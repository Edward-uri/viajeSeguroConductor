import '../domain/entities/vehiculo.dart';
import '../domain/repositories/vehicle_repository.dart';

class MockVehicleRepository implements VehicleRepository {
  final _vehiculos = [
    const Vehiculo(
      placa: 'XYZ-123',
      marca: 'Bajaj',
      modelo: 'RE',
      color: 'Rojo',
      anio: 2021,
      municipio: 'Tuxtla Gutiérrez',
      status: VehicleStatus.active,
    ),
    const Vehiculo(
      placa: 'ABC-987',
      marca: 'Italika',
      modelo: 'Moto-taxi',
      color: 'Azul',
      anio: 2022,
      municipio: 'Tuxtla Gutiérrez',
      status: VehicleStatus.incomplete,
    ),
  ];

  @override
  Future<List<Vehiculo>> getVehiculos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _vehiculos;
  }

  @override
  Future<void> registrarVehiculo(Vehiculo vehiculo) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> eliminarVehiculo(String placa) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
