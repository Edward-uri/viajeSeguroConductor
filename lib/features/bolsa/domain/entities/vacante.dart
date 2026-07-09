/// Vacante abierta de la bolsa de trabajo (GET /api/bolsa/vacantes) y
/// también la vista del dueño (GET /api/bolsa/mis-vacantes, sin datos de
/// vehículo pero con [estado] y [postulacionesPendientes]).
/// El shape público (conductor) no incluye PII del dueño; solo datos del
/// vehículo y condiciones.
class Vacante {
  final int idVacante;
  final int idVehiculo;
  final int idMunicipio;
  final String? condiciones;
  final String placa;
  final String modelo;
  final String color;
  final int anio;

  /// 'abierta' | 'cerrada'; '' si el endpoint no la incluye (shape público).
  final String estado;

  /// Solo en mis-vacantes (dueño); 0 en el shape público.
  final int postulacionesPendientes;

  const Vacante({
    required this.idVacante,
    this.idVehiculo = 0,
    this.idMunicipio = 0,
    this.condiciones,
    this.placa = '',
    this.modelo = '',
    this.color = '',
    this.anio = 0,
    this.estado = '',
    this.postulacionesPendientes = 0,
  });

  bool get abierta => estado == 'abierta';

  /// "Modelo · Color · Año" con lo que haya; placa o id como último recurso.
  String get descripcionVehiculo {
    final partes = [
      if (modelo.isNotEmpty) modelo,
      if (color.isNotEmpty) color,
      if (anio > 0) '$anio',
    ];
    if (partes.isNotEmpty) return partes.join(' · ');
    return placa.isNotEmpty ? placa : 'Vehículo #$idVehiculo';
  }
}
