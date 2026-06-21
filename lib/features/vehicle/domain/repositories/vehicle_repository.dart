import '../entities/vehiculo.dart';

abstract class VehicleRepository {
  Future<List<Vehiculo>> getVehiculos();
  Future<void> registrarVehiculo(Vehiculo vehiculo);
  Future<void> actualizarVehiculo(Vehiculo vehiculo);
  Future<void> eliminarVehiculo(String placa);
}
