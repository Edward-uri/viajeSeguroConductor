import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroconductor/core/error/app_error.dart';
import 'package:viajeseguroconductor/core/http/api_exception.dart';

void main() {
  group('ErrorHandler.messageFor', () {
    test('mensaje real del backend gana sobre el fallback', () {
      final e = ApiException('El viaje ya no existe', statusCode: 502);
      expect(
        ErrorHandler.messageFor(e, fallback: 'Contextual'),
        'El viaje ya no existe',
      );
    });

    test("mensaje fabricado 'Error 502' usa el fallback contextual", () {
      final e = ApiException('Error 502', statusCode: 502);
      expect(ErrorHandler.messageFor(e, fallback: 'Contextual'), 'Contextual');
    });

    test('mensaje fabricado sin fallback usa el default por status', () {
      final e = ApiException('Error 502', statusCode: 502);
      expect(ErrorHandler.messageFor(e), 'Error del servidor (502).');
    });

    test('mensaje fabricado 500 mapea al default de servidor', () {
      final e = ApiException('Error 500', statusCode: 500);
      expect(ErrorHandler.messageFor(e), 'Error del servidor. Intenta más tarde.');
    });

    test('error desconocido usa el fallback', () {
      expect(
        ErrorHandler.messageFor(Exception('boom'), fallback: 'Contextual'),
        'Contextual',
      );
    });

    test('unauthorized conserva su mensaje de sesión aunque venga fabricado', () {
      final e = UnauthorizedException('Error 401');
      expect(
        ErrorHandler.messageFor(e, fallback: 'Contextual'),
        'Tu sesión expiró. Inicia sesión de nuevo.',
      );
    });

    test('409 con cuerpo vacío mapea a conflicto amigable', () {
      final e = ApiException('', statusCode: 409);
      expect(
        ErrorHandler.messageFor(e),
        'Ya existe un registro con esos datos.',
      );
    });
  });
}
