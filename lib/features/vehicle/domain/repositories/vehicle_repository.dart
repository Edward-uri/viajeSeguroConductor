import 'dart:typed_data';

import '../entities/vehiculo.dart';

abstract class VehicleRepository {
  Future<List<Vehiculo>> getVehiculos();

  /// Vehículo propio del conductor (o null si aún no registra ninguno).
  Future<Vehiculo?> getMiVehiculo();

  /// Registra el vehículo y devuelve su idVehiculo (para subir documentos).
  Future<int> registrarVehiculo(Vehiculo vehiculo);

  Future<void> actualizarVehiculo(Vehiculo vehiculo);
  Future<void> eliminarVehiculo(String placa);

  /// Sube un documento del vehículo. [tipo] kebab-case: 'tarjeta-circulacion' | 'foto-vehiculo'.
  Future<void> subirDocumento({
    required int idVehiculo,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  });
}
