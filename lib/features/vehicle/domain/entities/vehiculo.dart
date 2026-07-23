enum VehicleStatus { active, incomplete, reviewing }

class Vehiculo {
  final int idVehiculo;
  final String placa;
  final String numeroSerie;
  final String marca;
  final String modelo;
  final String color;
  final int anio;
  final int idMunicipio;
  final String municipio; // nombre para mostrar; el backend solo guarda idMunicipio
  final VehicleStatus status;
  final String? rfc;
  final String? razonSocial;
  final bool activo;

  /// Conductores con asignación activa a este vehículo (por vacante o alta directa).
  final int conductoresAsignados;

  const Vehiculo({
    this.idVehiculo = 0,
    required this.placa,
    this.numeroSerie = '',
    this.marca = '',
    required this.modelo,
    required this.color,
    required this.anio,
    this.idMunicipio = 0,
    this.municipio = '',
    required this.status,
    this.rfc,
    this.razonSocial,
    this.activo = false,
    this.conductoresAsignados = 0,
  });

  bool get aprobado => status == VehicleStatus.active;
}
