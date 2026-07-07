import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroconductor/shared/data/mappers/user_mapper.dart';

void main() {
  group('UserMapper.fromJson', () {
    test('old backend: only rol string', () {
      final user = UserMapper.fromJson({
        'idUsuario': 1,
        'rol': 'conductor',
        'estadoCuenta': 'activo',
      });

      expect(user.rol, 'conductor');
      expect(user.rolesEfectivos, ['conductor']);
      expect(user.esConductor, isTrue);
    });

    test('new backend: rol + roles[]', () {
      final user = UserMapper.fromJson({
        'idUsuario': 2,
        'rol': 'propietario',
        'roles': ['propietario', 'pasajero'],
        'estadoCuenta': 'activo',
      });

      expect(user.roles, ['propietario', 'pasajero']);
      expect(user.esPropietario, isTrue);
      expect(user.esPasajero, isTrue);
    });

    test('no rol, only roles[]: does not crash', () {
      final user = UserMapper.fromJson({
        'idUsuario': 3,
        'roles': ['propietario'],
        'estadoCuenta': 'activo',
      });

      expect(user.rol, 'propietario');
      expect(user.roles, ['propietario']);
    });
  });
}
