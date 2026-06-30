import 'dart:typed_data';

import '../../../shared/domain/entities/user.dart';
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
  Future<User> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = User(
      idUsuario: _currentUser.idUsuario,
      rol: _currentUser.rol,
      estadoCuenta: _currentUser.estadoCuenta,
      telefono: _currentUser.telefono,
      correoElectronico: _currentUser.correoElectronico,
      telefonoVerificado: _currentUser.telefonoVerificado,
      idMunicipio: _currentUser.idMunicipio,
      fotoPerfilUrl: 'https://mock.example.com/foto.jpg',
      fechaRegistro: _currentUser.fechaRegistro,
    );
    return _currentUser;
  }

  @override
  Future<void> deleteAccount() async {}
}
