import '../../../shared/domain/entities/user.dart';
import '../domain/entities/profile_photo_upload_ticket.dart';
import '../domain/repositories/profile_repository.dart';


class MockProfileRepository implements ProfileRepository {
  User _currentUser = const User(
    idUsuario: 1,
    rol: 'conductor',
    estadoCuenta: 'activo',
    fechaRegistro: null,
  );

  @override
  Future<User> getMe() async {
    return _currentUser;
  }

  @override
  Future<User> updateMe(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = User(
      idUsuario: _currentUser.idUsuario,
      rol: _currentUser.rol,
      estadoCuenta: _currentUser.estadoCuenta,
      telefono: data['telefono'] as String? ?? _currentUser.telefono,
      correoElectronico: data['correoElectronico'] as String? ?? _currentUser.correoElectronico,
      telefonoVerificado: _currentUser.telefonoVerificado,
      idMunicipio: (data['idMunicipio'] as num?)?.toInt() ?? _currentUser.idMunicipio,
      fotoPerfilUrl: _currentUser.fotoPerfilUrl,
      fechaRegistro: _currentUser.fechaRegistro,
    );
    return _currentUser;
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
    _currentUser = User(
      idUsuario: _currentUser.idUsuario,
      rol: _currentUser.rol,
      estadoCuenta: _currentUser.estadoCuenta,
      telefono: _currentUser.telefono,
      correoElectronico: _currentUser.correoElectronico,
      telefonoVerificado: _currentUser.telefonoVerificado,
      idMunicipio: _currentUser.idMunicipio,
      fotoPerfilUrl: 'https://mock-s3.example.com/mock-s3-key',
      fechaRegistro: _currentUser.fechaRegistro,
    );
    return _currentUser;
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
