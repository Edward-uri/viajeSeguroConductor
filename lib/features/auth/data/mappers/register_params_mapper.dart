import '../../domain/entities/register_params.dart';

class RegisterParamsMapper {
  const RegisterParamsMapper._();

  static Map<String, dynamic> toJson(RegisterParams params) {
    return {
      'nombre': params.nombre,
      'apellidoPaterno': params.apellidoPaterno,
      if (params.apellidoMaterno != null)
        'apellidoMaterno': params.apellidoMaterno,
      if (params.telefono != null) 'telefono': params.telefono,
      if (params.idSexo != null) 'idSexo': params.idSexo,
      if (params.fechaNacimiento != null)
        'fechaNacimiento': params.fechaNacimiento,
      if (params.idMunicipio != null) 'idMunicipio': params.idMunicipio,
      if (params.dispositivo != null) 'dispositivo': params.dispositivo,
    };
  }
}
