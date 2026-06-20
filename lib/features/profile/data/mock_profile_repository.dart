import '../../../shared/domain/entities/user.dart';
import '../domain/entities/profile_photo_upload_ticket.dart';
import '../domain/repositories/profile_repository.dart';


class MockProfileRepository implements ProfileRepository {
  @override
  Future<User> getMe() async {
    return const User(
      idUsuario: 1,
      nombreUsuario: 'usuario',
      rol: 'pasajero',
      estadoCuenta: 'activo',
      fechaRegistro: null,
    );
  }

  @override
  Future<ProfilePhotoUploadTicket> requestPhotoUpload({
    required String contentType,
  }) async {
    const key = 'mock-s3-key';
    return const ProfilePhotoUploadTicket(
      uploadUrl: 'https://mock-s3.example.com/$key',
      s3Key: key,
      publicUrl: 'https://mock-s3.example.com/$key',
      expiresIn: 3600,
      maxBytes: 5 * 1024 * 1024,
    );
  }

  @override
  Future<User> confirmPhotoUpload({required String s3Key}) async {
    return const User(
      idUsuario: 1,
      nombreUsuario: 'usuario',
      rol: 'pasajero',
      estadoCuenta: 'activo',
      fechaRegistro: null,
      fotoPerfilUrl: 'https://mock-s3.example.com/mock-s3-key',
    );
  }

  @override
  Future<void> uploadBytesToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {}

  @override
  Future<void> deleteAccount() async {}
}
