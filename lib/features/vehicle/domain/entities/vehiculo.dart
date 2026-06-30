enum VehicleStatus { active, incomplete, reviewing }

class Vehiculo {
  final int idVehiculo;
  final String placa;
  final String marca;
  final String modelo;
  final String color;
  final int anio;
  final int idMunicipio;
  final String municipio; // nombre para mostrar; el backend solo guarda idMunicipio
  final VehicleStatus status;
  final String? rfc;
  final String? razonSocial;

  const Vehiculo({
    this.idVehiculo = 0,
    required this.placa,
    this.marca = '',
    required this.modelo,
    required this.color,
    required this.anio,
    this.idMunicipio = 0,
    this.municipio = '',
    required this.status,
    this.rfc,
    this.razonSocial,
  });

  bool get aprobado => status == VehicleStatus.active;
}
