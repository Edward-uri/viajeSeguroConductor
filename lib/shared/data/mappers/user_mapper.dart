import '../../domain/entities/user.dart';

class UserMapper {
  const UserMapper._();

  static User fromJson(Map<String, dynamic> json) {
    final persona = json['persona'] as Map<String, dynamic>?;
    return User(
      idUsuario: (json['idUsuario'] as num).toInt(),
      rol: json['rol'] as String,
      estadoCuenta: json['estadoCuenta'] as String,
      telefono: json['telefono'] as String?,
      correoElectronico: json['correoElectronico'] as String?,
      telefonoVerificado: json['telefonoVerificado'] as bool?,
      idMunicipio: (json['idMunicipio'] as num?)?.toInt(),
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      fechaRegistro: json['fechaRegistro'] != null
          ? DateTime.tryParse(json['fechaRegistro'].toString())
          : null,
      nombre: persona?['nombre'] as String?,
      apellidoPaterno: persona?['apellidoPaterno'] as String?,
      apellidoMaterno: persona?['apellidoMaterno'] as String?,
      fechaNacimiento: persona?['fechaNacimiento'] as String?,
    );
  }
}
