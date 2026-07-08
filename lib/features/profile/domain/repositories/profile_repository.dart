import 'dart:typed_data';

import '../../../../shared/domain/entities/user.dart';
import '../entities/update_profile_params.dart';

abstract class ProfileRepository {
  Future<User> getMe();

  Future<User> updateMe(Map<String, dynamic> data);

  Future<User> updateProfile(UpdateProfileParams params);

  /// Sube la foto de perfil al volumen del backend y devuelve el usuario actualizado.
  Future<User> uploadPhoto({required Uint8List bytes, required String fileName});

  Future<void> deleteAccount();

  /// Convierte una cuenta solo-pasajero en propietario (agrega el rol
  /// 'propietario'). El access token viejo no trae el rol nuevo: quien llame
  /// esto debe refrescar tokens después.
  Future<void> activarPropietario();
}
