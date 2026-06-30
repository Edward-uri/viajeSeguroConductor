import 'dart:typed_data';

import '../domain/entities/vehiculo.dart';
import '../domain/repositories/vehicle_repository.dart';
import 'mappers/vehiculo_mapper.dart';
import 'remote/vehiculos_api.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._api);

  final VehiculosApi _api;

  @override
  Future<List<Vehiculo>> getVehiculos() async {
    try {
      final res = await _api.getVehiculos();
      final data = res['data'] as List<dynamic>? ?? [];
      return data.map((e) => VehiculoMapper.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Vehiculo?> getMiVehiculo() async {
    final vehiculos = await getVehiculos();
    // ponytail: el conductor-dueño tiene un vehículo; el backend lista los propios primero.
    return vehiculos.isEmpty ? null : vehiculos.first;
  }

  @override
  Future<int> registrarVehiculo(Vehiculo vehiculo) async {
    final res = await _api.registrarVehiculo(VehiculoMapper.toJson(vehiculo));
    return (res['idVehiculo'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    await _api.actualizarVehiculo(vehiculo.placa, VehiculoMapper.toJson(vehiculo));
  }

  @override
  Future<void> eliminarVehiculo(String placa) async {
    await _api.eliminarVehiculo(placa);
  }

  @override
  Future<void> subirDocumento({
    required int idVehiculo,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {
    await _api.subirDocumentoVehiculo(
      idVehiculo: idVehiculo,
      tipo: tipo,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
