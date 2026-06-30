class RegisterParams {
  const RegisterParams({
    required this.nombre,
    required this.apellidoPaterno,
    this.password,
    this.apellidoMaterno,
    this.telefono,
    this.idSexo,
    this.fechaNacimiento,
    this.idMunicipio,
    this.dispositivo,
  });

  final String? password;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final int? idSexo;
  final String? fechaNacimiento;
  final int? idMunicipio;
  final String? dispositivo;
}
