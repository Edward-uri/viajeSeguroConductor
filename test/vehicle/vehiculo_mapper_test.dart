import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroconductor/features/vehicle/data/mappers/vehiculo_mapper.dart';

void main() {
  group('VehiculoMapper.fromJson', () {
    test('backend con activo: true', () {
      final vehiculo = VehiculoMapper.fromJson({
        'idVehiculo': 1,
        'placa': 'XYZ-123',
        'modelo': 'RE',
        'color': 'Rojo',
        'anio': 2021,
        'idMunicipio': 1,
        'estadoVerificacion': 'aprobado',
        'activo': true,
      });

      expect(vehiculo.activo, isTrue);
    });

    test('backend viejo sin campo activo: false', () {
      final vehiculo = VehiculoMapper.fromJson({
        'idVehiculo': 2,
        'placa': 'ABC-987',
        'modelo': 'Moto-taxi',
        'color': 'Azul',
        'anio': 2022,
        'idMunicipio': 1,
        'estadoVerificacion': 'aprobado',
      });

      expect(vehiculo.activo, isFalse);
    });
  });
}
