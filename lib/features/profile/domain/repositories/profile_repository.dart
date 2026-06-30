import 'dart:typed_data';

import '../../../../shared/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<User> getMe();

  Future<User> updateMe(Map<String, dynamic> data);

  /// Sube la foto de perfil al volumen del backend y devuelve el usuario actualizado.
  Future<User> uploadPhoto({required Uint8List bytes, required String fileName});

  Future<void> deleteAccount();
}
