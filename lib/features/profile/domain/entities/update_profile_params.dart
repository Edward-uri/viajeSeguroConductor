// El correo no viaja en la edición de perfil: es de solo lectura en la UI
// (mismo comportamiento que la app pasajero).
class UpdateProfileParams {
  const UpdateProfileParams({
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.nombreUsuario,
  });

  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String? nombreUsuario;

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'apellidoPaterno': apellidoPaterno,
        if (apellidoMaterno != null && apellidoMaterno!.trim().isNotEmpty)
          'apellidoMaterno': apellidoMaterno,
        if (telefono != null && telefono!.trim().isNotEmpty)
          'telefono': telefono,
        if (nombreUsuario != null && nombreUsuario!.trim().isNotEmpty)
          'nombreUsuario': nombreUsuario,
      };
}
