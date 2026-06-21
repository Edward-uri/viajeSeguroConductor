enum VehicleStatus { active, incomplete, reviewing }

class Vehiculo {
  final String placa;
  final String marca;
  final String modelo;
  final String color;
  final int anio;
  final String municipio;
  final VehicleStatus status;
  final String? rfc;
  final String? razonSocial;

  const Vehiculo({
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.anio,
    required this.municipio,
    required this.status,
    this.rfc,
    this.razonSocial,
  });
}
