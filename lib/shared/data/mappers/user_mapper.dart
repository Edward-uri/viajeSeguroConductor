import '../../domain/entities/user.dart';

class UserMapper {
  const UserMapper._();

  static User fromJson(Map<String, dynamic> json) {
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
    );
  }
}
