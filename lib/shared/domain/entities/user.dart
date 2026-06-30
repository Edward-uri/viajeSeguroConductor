class User {
  const User({
    required this.idUsuario,
    required this.rol,
    required this.estadoCuenta,
    this.telefono,
    this.correoElectronico,
    this.telefonoVerificado,
    this.idMunicipio,
    this.fotoPerfilUrl,
    this.fechaRegistro,
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.fechaNacimiento,
    this.nombreUsuario,
  });

  final int idUsuario;
  final String rol;
  final String estadoCuenta;
  final String? telefono;
  final String? correoElectronico;
  final bool? telefonoVerificado;
  final int? idMunicipio;
  final String? fotoPerfilUrl;
  final DateTime? fechaRegistro;
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? fechaNacimiento;
  final String? nombreUsuario;

  String get nombreCompleto => [nombre, apellidoPaterno, apellidoMaterno]
      .whereType<String>()
      .where((p) => p.trim().isNotEmpty)
      .join(' ');

  User copyWith({
    String? fotoPerfilUrl,
    String? estadoCuenta,
    String? telefono,
    String? correoElectronico,
    int? idMunicipio,
    String? nombreUsuario,
  }) {
    return User(
      idUsuario: idUsuario,
      rol: rol,
      estadoCuenta: estadoCuenta ?? this.estadoCuenta,
      telefono: telefono ?? this.telefono,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      telefonoVerificado: telefonoVerificado,
      idMunicipio: idMunicipio ?? this.idMunicipio,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      fechaRegistro: fechaRegistro,
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      fechaNacimiento: fechaNacimiento,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
    );
  }
}
