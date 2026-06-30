class UpdateProfileParams {
  const UpdateProfileParams({
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    required this.correoElectronico,
    this.nombreUsuario,
  });

  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String correoElectronico;
  final String? nombreUsuario;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'apellidoPaterno': apellidoPaterno,
        if (apellidoMaterno != null && apellidoMaterno!.trim().isNotEmpty)
          'apellidoMaterno': apellidoMaterno,
        if (telefono != null && telefono!.trim().isNotEmpty)
          'telefono': telefono,
        'correoElectronico': correoElectronico,
        if (nombreUsuario != null && nombreUsuario!.trim().isNotEmpty)
          'nombreUsuario': nombreUsuario,
      };
}
