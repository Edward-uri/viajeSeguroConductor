import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroconductor/features/bolsa/data/mappers/bolsa_mapper.dart';
import 'package:viajeseguroconductor/features/bolsa/domain/entities/postulacion.dart';

void main() {
  group('BolsaMapper.vacanteFromJson', () {
    test('shape completo del backend', () {
      final vacante = BolsaMapper.vacanteFromJson({
        'idVacante': 3,
        'idPropietario': 9,
        'idVehiculo': 7,
        'idMunicipio': 1,
        'condiciones': 'Turno matutino, 60/40',
        'estado': 'abierta',
        'placa': 'XYZ-123',
        'modelo': 'Italika 150',
        'color': 'Rojo',
        'anio': 2021,
      });

      expect(vacante.idVacante, 3);
      expect(vacante.idVehiculo, 7);
      expect(vacante.idMunicipio, 1);
      expect(vacante.condiciones, 'Turno matutino, 60/40');
      expect(vacante.placa, 'XYZ-123');
      // La placa manda y se le suman los detalles.
      expect(vacante.descripcionVehiculo, 'XYZ-123 · Italika 150 · Rojo · 2021');
    });

    test('campos opcionales ausentes o null: defaults tolerantes', () {
      final vacante = BolsaMapper.vacanteFromJson({
        'idVacante': 4,
        'idVehiculo': 8,
        'idMunicipio': 1,
        'condiciones': null,
        'placa': 'ABC-987',
        'modelo': null,
        'color': null,
        'anio': null,
      });

      expect(vacante.condiciones, isNull);
      expect(vacante.modelo, '');
      expect(vacante.color, '');
      expect(vacante.anio, 0);
      // Sin modelo/color/anio cae a la placa.
      expect(vacante.descripcionVehiculo, 'ABC-987');
    });
  });

  group('BolsaMapper.postulacionFromJson', () {
    test('shape completo de mis-postulaciones', () {
      final postulacion = BolsaMapper.postulacionFromJson({
        'idPostulacion': 11,
        'idVacante': 3,
        'idConductor': 5,
        'estado': 'aceptada',
        'mensaje': 'Tengo 3 años de experiencia',
        'idVehiculo': 7,
        'idMunicipio': 1,
        'estadoVacante': 'cerrada',
      });

      expect(postulacion.idPostulacion, 11);
      expect(postulacion.idVacante, 3);
      expect(postulacion.estado, EstadoPostulacion.aceptada);
      expect(postulacion.mensaje, 'Tengo 3 años de experiencia');
      expect(postulacion.estadoVacante, 'cerrada');
      expect(postulacion.puedeRetirar, isFalse);
    });

    test('estado desconocido y campos ausentes: tolerante, sin excepción', () {
      final postulacion = BolsaMapper.postulacionFromJson({
        'idPostulacion': 12,
        'idVacante': 4,
        'estado': 'en_espera_de_algo_nuevo',
      });

      expect(postulacion.estado, EstadoPostulacion.desconocido);
      expect(postulacion.mensaje, isNull);
      expect(postulacion.idVehiculo, 0);
      expect(postulacion.estadoVacante, '');
      expect(postulacion.puedeRetirar, isFalse);
    });

    test('estado pendiente permite retirar', () {
      final postulacion = BolsaMapper.postulacionFromJson({
        'idPostulacion': 13,
        'idVacante': 5,
        'estado': 'pendiente',
        'mensaje': null,
        'idVehiculo': 2,
        'idMunicipio': 1,
        'estadoVacante': 'abierta',
      });

      expect(postulacion.estado, EstadoPostulacion.pendiente);
      expect(postulacion.puedeRetirar, isTrue);
    });
  });

  group('BolsaMapper — vista del dueño', () {
    test('vacanteFromJson: mis-vacantes trae estado y postulacionesPendientes',
        () {
      final vacante = BolsaMapper.vacanteFromJson({
        'idVacante': 20,
        'idPropietario': 9,
        'idVehiculo': 7,
        'idMunicipio': 1,
        'condiciones': 'Turno vespertino',
        'estado': 'abierta',
        'postulacionesPendientes': 3,
      });

      expect(vacante.idVacante, 20);
      expect(vacante.estado, 'abierta');
      expect(vacante.abierta, isTrue);
      expect(vacante.postulacionesPendientes, 3);
      // Sin placa/modelo/color/anio (mis-vacantes no los trae): cae a placa/id.
      expect(vacante.descripcionVehiculo, 'Vehículo #7');
    });

    test('vacanteFromJson: vacante cerrada, sin postulacionesPendientes (default 0)',
        () {
      final vacante = BolsaMapper.vacanteFromJson({
        'idVacante': 21,
        'idVehiculo': 8,
        'idMunicipio': 1,
        'estado': 'cerrada',
      });

      expect(vacante.estado, 'cerrada');
      expect(vacante.abierta, isFalse);
      expect(vacante.postulacionesPendientes, 0);
    });

    test('postulacionFromJson: shape público del conductor (nombre/foto/calificación)',
        () {
      final postulacion = BolsaMapper.postulacionFromJson({
        'idPostulacion': 30,
        'idVacante': 20,
        'idConductor': 5,
        'estado': 'pendiente',
        'mensaje': 'Disponible desde ya',
        'conductor': {
          'nombre': 'Juan Pérez',
          'calificacion': 4.8,
          'fotoUrl': '/api/users/5/photo',
        },
      });

      expect(postulacion.idPostulacion, 30);
      expect(postulacion.mensaje, 'Disponible desde ya');
      expect(postulacion.conductorNombre, 'Juan Pérez');
      expect(postulacion.conductorCalificacion, 4.8);
      expect(postulacion.conductorFotoUrl, '/api/users/5/photo');
      expect(postulacion.estado.label, 'Pendiente');
    });

    test('postulacionFromJson: sin objeto conductor (shape de mis-postulaciones), tolerante',
        () {
      final postulacion = BolsaMapper.postulacionFromJson({
        'idPostulacion': 31,
        'idVacante': 20,
        'estado': 'aceptada',
      });

      expect(postulacion.conductorNombre, isNull);
      expect(postulacion.conductorCalificacion, isNull);
      expect(postulacion.conductorFotoUrl, isNull);
      expect(postulacion.estado.color, isNotNull);
    });

    test('postulacionFromJson: conductor con calificacion null (sin evaluaciones aún)',
        () {
      final postulacion = BolsaMapper.postulacionFromJson({
        'idPostulacion': 32,
        'idVacante': 20,
        'estado': 'pendiente',
        'conductor': {
          'nombre': 'Ana Ruiz',
          'calificacion': null,
          'fotoUrl': null,
        },
      });

      expect(postulacion.conductorNombre, 'Ana Ruiz');
      expect(postulacion.conductorCalificacion, isNull);
      expect(postulacion.conductorFotoUrl, isNull);
    });
  });
}
