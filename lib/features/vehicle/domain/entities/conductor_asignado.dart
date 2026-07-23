/// Conductor con asignación activa a un vehículo del dueño
/// (GET /api/flotillas/vehiculos/:id/conductores). Shape público: nombre, foto,
/// calificación y los términos de la relación (turno/renta/días/horario).
class ConductorAsignado {
  final int idConductor;
  final String? nombre;
  final String? fotoUrl;
  final double? calificacion;

  /// 'propia' (alta manual del dueño) | 'bolsa' (aceptado de una vacante).
  final String origen;

  /// 'completo' | 'matutino' | 'vespertino' | 'nocturno'; '' si es alta 'propia' sin términos.
  final String tipoTurno;
  final double? rentaTurno;
  final List<String> dias;
  final String? horario;

  const ConductorAsignado({
    required this.idConductor,
    this.nombre,
    this.fotoUrl,
    this.calificacion,
    this.origen = 'propia',
    this.tipoTurno = '',
    this.rentaTurno,
    this.dias = const [],
    this.horario,
  });

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
    final r = rentaTurno;
    if (r == null || r <= 0) return '';
    final entero = r.truncateToDouble() == r;
    return '\$${r.toStringAsFixed(entero ? 0 : 2)}';
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
}
