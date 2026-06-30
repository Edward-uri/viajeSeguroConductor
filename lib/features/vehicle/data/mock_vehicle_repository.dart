import 'dart:typed_data';

import '../domain/entities/vehiculo.dart';
import '../domain/repositories/vehicle_repository.dart';

class MockVehicleRepository implements VehicleRepository {
  final _vehiculos = [
    const Vehiculo(
      idVehiculo: 1,
      placa: 'XYZ-123',
      marca: 'Bajaj',
      modelo: 'RE',
      color: 'Rojo',
      anio: 2021,
      municipio: 'Suchiapa',
      status: VehicleStatus.active,
    ),
    const Vehiculo(
      idVehiculo: 2,
      placa: 'ABC-987',
      marca: 'Italika',
      modelo: 'Moto-taxi',
      color: 'Azul',
      anio: 2022,
      municipio: 'Suchiapa',
      status: VehicleStatus.incomplete,
    ),
  ];

  @override
  Future<List<Vehiculo>> getVehiculos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _vehiculos;
  }

  @override
  Future<Vehiculo?> getMiVehiculo() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _vehiculos.first;
  }

  @override
  Future<int> registrarVehiculo(Vehiculo vehiculo) async {
    await Future.delayed(const Duration(seconds: 1));
    return 99;
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> eliminarVehiculo(String placa) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> subirDocumento({
    required int idVehiculo,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<Map<String, dynamic>> getDatosFacturacion() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'rfc': 'MEND920101AB1', 'razonSocial': 'Carlos Méndez'};
  }

  @override
  Future<void> guardarDatosFacturacion(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
