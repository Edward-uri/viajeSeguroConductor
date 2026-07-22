/// Vacante abierta de la bolsa de trabajo (GET /api/bolsa/vacantes) y
/// también la vista del dueño (GET /api/bolsa/mis-vacantes, sin datos de
/// vehículo pero con [estado] y [postulacionesPendientes]).
/// El shape público (conductor) no incluye PII del dueño; solo datos del
/// vehículo y los términos de la oferta.
class Vacante {
  final int idVacante;
  final int idVehiculo;
  final int idMunicipio;

  /// 'completo' | 'matutino' | 'vespertino' | 'nocturno'; '' si no aplica.
  final String tipoTurno;
  final double rentaTurno;
  final List<String> dias;
  final String? horario;
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
    this.tipoTurno = '',
    this.rentaTurno = 0,
    this.dias = const [],
    this.horario,
    this.condiciones,
    this.placa = '',
    this.modelo = '',
    this.color = '',
    this.anio = 0,
    this.estado = '',
    this.postulacionesPendientes = 0,
  });

  bool get abierta => estado == 'abierta';

  String get turnoLabel {
    switch (tipoTurno) {
      case 'completo':
        return 'Jornada completa';
      case 'matutino':
        return 'Matutino';
      case 'vespertino':
        return 'Vespertino';
      case 'nocturno':
        return 'Nocturno';
      default:
        return '';
    }
  }

  /// "$300" MXN (sin decimales si es entero); '' si no hay renta.
  String get rentaLabel {
    if (rentaTurno <= 0) return '';
    final entero = rentaTurno.truncateToDouble() == rentaTurno;
    return '\$${rentaTurno.toStringAsFixed(entero ? 0 : 2)}';
  }

  /// "Lun · Mar · Vie".
  String get diasLabel =>
      dias.map(_diaCorto).where((d) => d.isNotEmpty).join(' · ');

  static String _diaCorto(String d) {
    switch (d) {
      case 'lun':
        return 'Lun';
      case 'mar':
        return 'Mar';
      case 'mie':
        return 'Mié';
      case 'jue':
        return 'Jue';
      case 'vie':
        return 'Vie';
      case 'sab':
        return 'Sáb';
      case 'dom':
        return 'Dom';
      default:
        return '';
    }
  }

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
