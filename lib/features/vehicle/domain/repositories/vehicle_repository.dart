import 'dart:typed_data';

import '../entities/conductor_asignado.dart';
import '../entities/vehiculo.dart';

abstract class VehicleRepository {
  Future<List<Vehiculo>> getVehiculos();

  // ───── Conductores asignados (dueño) ─────
  Future<List<ConductorAsignado>> getConductoresAsignados(int idVehiculo);

  Future<void> editarConductorAsignado(
    int idVehiculo,
    int idConductor, {
    required String tipoTurno,
    required double rentaTurno,
    required List<String> dias,
    String? horario,
  });

  Future<void> darDeBajaConductor(int idVehiculo, int idConductor);

  /// Vehículo propio del conductor (o null si aún no registra ninguno).
  Future<Vehiculo?> getMiVehiculo();

  /// Registra el vehículo y devuelve su idVehiculo (para subir documentos).
  Future<int> registrarVehiculo(Vehiculo vehiculo);

  Future<void> actualizarVehiculo(Vehiculo vehiculo);
  Future<void> eliminarVehiculo(String placa);

  /// Marca el vehículo como el activo del conductor.
  Future<void> setVehiculoActivo(int idVehiculo);

  /// Sube un documento del vehículo. [tipo] kebab-case: 'tarjeta-circulacion' | 'foto-vehiculo'.
  Future<void> subirDocumento({
    required int idVehiculo,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  });

  Future<Map<String, dynamic>> getDatosFacturacion();
  Future<void> guardarDatosFacturacion(Map<String, dynamic> data);
}
