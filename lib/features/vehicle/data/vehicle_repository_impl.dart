import 'dart:typed_data';

import '../domain/entities/conductor_asignado.dart';
import '../domain/entities/vehiculo.dart';
import '../domain/repositories/vehicle_repository.dart';
import 'mappers/conductor_asignado_mapper.dart';
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
    if (vehiculos.isEmpty) return null;
    return vehiculos.firstWhere(
      (v) => v.aprobado,
      orElse: () => vehiculos.firstWhere((v) => v.activo, orElse: () => vehiculos.first),
    );
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
  Future<void> setVehiculoActivo(int idVehiculo) async {
    await _api.setVehiculoActivo(idVehiculo);
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

  // Las lecturas/mutaciones de conductores NO tragan errores: el viewmodel los
  // convierte en SnackBar (a diferencia de getVehiculos).

  @override
  Future<List<ConductorAsignado>> getConductoresAsignados(int idVehiculo) async {
    final res = await _api.getConductoresAsignados(idVehiculo);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ConductorAsignadoMapper.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> editarConductorAsignado(
    int idVehiculo,
    int idConductor, {
    required String tipoTurno,
    required double rentaTurno,
    required List<String> dias,
    String? horario,
  }) async {
    await _api.editarConductorAsignado(idVehiculo, idConductor, {
      'tipoTurno': tipoTurno,
      'rentaTurno': rentaTurno,
      'dias': dias,
      if (horario != null && horario.isNotEmpty) 'horario': horario,
    });
  }

  @override
  Future<void> darDeBajaConductor(int idVehiculo, int idConductor) async {
    await _api.darDeBajaConductor(idVehiculo, idConductor);
  }

  @override
  Future<Map<String, dynamic>> getDatosFacturacion() async {
    try {
      final res = await _api.getDatosFacturacion();
      return (res['data'] as Map<String, dynamic>?) ?? res;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<void> guardarDatosFacturacion(Map<String, dynamic> data) async {
    await _api.guardarDatosFacturacion(data);
  }
}
