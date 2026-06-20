import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/auth_storage.dart';
import '../../../shared/domain/entities/user.dart';
import '../domain/entities/register_params.dart';
import '../domain/repositories/auth_repository.dart';


class _StoredUser {
  const _StoredUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.rol,
    required this.email,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    this.telefono,
    this.estadoCuenta = 'activo',
    this.fechaRegistro,
  });

  final int id;
  final String username;
  final String passwordHash;
  final String rol;
  final String email;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String? telefono;
  final String estadoCuenta;
  final DateTime? fechaRegistro;
}


class AuthSimulator implements AuthRepository {
  AuthSimulator(this._storage) {
    _seedDefaultUsers();
  }

  final AuthStorage _storage;

  static final Map<String, _StoredUser> _users = <String, _StoredUser>{};
  static int _nextId = 1;
  static User? _currentUser;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  void _seedDefaultUsers() {
    if (_users.isNotEmpty) return;

    final admin = _StoredUser(
      id: _nextId++,
      username: 'admin',
      passwordHash: _hashPassword('admin123'),
      rol: 'admin',
      email: 'admin@viajeseguro.mx',
      nombre: 'Admin',
      apellidoPaterno: 'Sistema',
      estadoCuenta: 'activo',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
    );
    _users[admin.username] = admin;

    final conductor = _StoredUser(
      id: _nextId++,
      username: 'conductor1',
      passwordHash: _hashPassword('conductor123'),
      rol: 'conductor',
      email: 'conductor@viajeseguro.mx',
      nombre: 'Carlos',
      apellidoPaterno: 'López',
      telefono: '+525512345678',
      estadoCuenta: 'activo',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 15)),
    );
    _users[conductor.username] = conductor;

    final pasajero = _StoredUser(
      id: _nextId++,
      username: 'pasajero1',
      passwordHash: _hashPassword('pasajero123'),
      rol: 'pasajero',
      email: 'pasajero@viajeseguro.mx',
      nombre: 'María',
      apellidoPaterno: 'García',
      telefono: '+525598765432',
      estadoCuenta: 'activo',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 7)),
    );
    _users[pasajero.username] = pasajero;

    debugPrint('[AuthSimulator] Usuarios precargados: ${_users.length}');
  }

  @override
  Future<User> login({
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final stored = _users[identifier.trim()];
    if (stored == null) {
      throw AuthSimulatorException('Usuario no encontrado');
    }

    if (stored.estadoCuenta == 'suspendido') {
      throw AuthSimulatorException('Cuenta suspendida');
    }

    if (stored.estadoCuenta == 'eliminado') {
      throw AuthSimulatorException('Cuenta eliminada');
    }

    final hash = _hashPassword(password);
    if (stored.passwordHash != hash) {
      throw AuthSimulatorException('Contraseña incorrecta');
    }

    final token = 'sim_${_nextId++}_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.writeToken(token);

    _currentUser = User(
      idUsuario: stored.id,
      nombreUsuario: stored.username,
      rol: stored.rol,
      estadoCuenta: stored.estadoCuenta,
      fechaRegistro: stored.fechaRegistro,
    );

    debugPrint('[AuthSimulator] Login exitoso: ${stored.username}');
    return _currentUser!;
  }

  @override
  Future<User> register(RegisterParams params) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_users.containsKey(params.nombreUsuario.trim())) {
      throw AuthSimulatorException('El nombre de usuario ya existe');
    }

    if (params.password.length < 6) {
      throw AuthSimulatorException('La contraseña debe tener al menos 6 caracteres');
    }

    if (!_isValidEmail(params.correoElectronico)) {
      throw AuthSimulatorException('Correo electrónico inválido');
    }

    final stored = _StoredUser(
      id: _nextId++,
      username: params.nombreUsuario.trim(),
      passwordHash: _hashPassword(params.password),
      rol: params.rol,
      email: params.correoElectronico,
      nombre: params.nombre,
      apellidoPaterno: params.apellidoPaterno,
      apellidoMaterno: params.apellidoMaterno,
      telefono: params.telefono,
      estadoCuenta: 'activo',
      fechaRegistro: DateTime.now(),
    );

    _users[stored.username] = stored;

    final token = 'sim_${stored.id}_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.writeToken(token);

    _currentUser = User(
      idUsuario: stored.id,
      nombreUsuario: stored.username,
      rol: stored.rol,
      estadoCuenta: stored.estadoCuenta,
      fechaRegistro: stored.fechaRegistro,
    );

    debugPrint('[AuthSimulator] Registro exitoso: ${stored.username}');
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _storage.clear();
    debugPrint('[AuthSimulator] Sesión cerrada');
  }

  @override
  Future<bool> hasSession() async {
    if (_currentUser != null) return true;
    final token = await _storage.readToken();
    return token != null && token.isNotEmpty;
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }
}


class AuthSimulatorException implements Exception {
  AuthSimulatorException(this.message);

  final String message;

  @override
  String toString() => 'AuthSimulatorException: $message';
}
