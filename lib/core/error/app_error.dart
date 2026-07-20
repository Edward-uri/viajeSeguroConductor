import 'dart:async';

import '../http/api_exception.dart';

sealed class AppError {
  const AppError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}

class NetworkAppError extends AppError {
  const NetworkAppError({
    super.message = 'Sin conexión. Revisa tu internet e intenta de nuevo.',
  });
}

class TimeoutAppError extends AppError {
  const TimeoutAppError({
    super.message = 'La solicitud tardó demasiado. Intenta de nuevo.',
  });
}

class UnauthorizedAppError extends AppError {
  const UnauthorizedAppError({
    super.message = 'Tu sesión expiró. Inicia sesión de nuevo.',
  });
}

class ValidationAppError extends AppError {
  const ValidationAppError({
    required super.message,
    this.details,
  });

  final Object? details;
}

class ServerAppError extends AppError {
  const ServerAppError({
    super.message = 'Error del servidor. Intenta más tarde.',
    super.statusCode,
  });
}

class NotFoundAppError extends AppError {
  const NotFoundAppError({
    super.message = 'No se encontró el recurso solicitado.',
  });
}

class ConflictAppError extends AppError {
  const ConflictAppError({
    super.message = 'Ya existe un registro con esos datos.',
  });
}

class UnknownAppError extends AppError {
  const UnknownAppError({
    super.message = 'Ocurrió un error inesperado. Intenta de nuevo.',
  });
}

class ErrorHandler {
  const ErrorHandler._();

  static AppError handle(Object error) {
    if (error is AppError) return error;
    if (error is ApiException) return _fromApiException(error);
    if (error is TimeoutException) return const TimeoutAppError();
    if (error is FormatException) {
      return const UnknownAppError(
        message: 'Error al procesar la respuesta del servidor.',
      );
    }
    return const UnknownAppError();
  }

  /// Mensaje fabricado por ApiClient ('Error 502') cuando la respuesta no
  /// trae cuerpo JSON (gateways, proxies): no le dice nada al usuario.
  static final _mensajeFabricado = RegExp(r'^Error \d+$');

  /// Mensaje para la UI: si el error no se pudo clasificar, usa [fallback]
  /// (el texto específico del contexto) en vez del genérico.
  static String messageFor(Object error, {String? fallback}) {
    final appError = handle(error);
    if (fallback != null && appError is UnknownAppError) return fallback;
    // 'Error 502' fabricado tampoco informa nada: mismo trato que Unknown.
    // Sólo aplica a la ApiException base; Unauthorized/Validation/Network ya
    // mapean a mensajes propios más útiles que el fallback contextual.
    if (fallback != null &&
        error is ApiException &&
        error is! UnauthorizedException &&
        error is! ValidationException &&
        error is! NetworkException &&
        _mensajeFabricado.hasMatch(error.message)) {
      return fallback;
    }
    return appError.message;
  }

  static AppError _fromApiException(ApiException e) {
    return switch (e) {
      UnauthorizedException() => const UnauthorizedAppError(),
      ValidationException() => ValidationAppError(
        message: e.message,
        details: e.details,
      ),
      NetworkException() => NetworkAppError(message: e.message),
      ApiException() => _fromStatusCode(e.statusCode, e.message),
    };
  }

  static AppError _fromStatusCode(int? statusCode, String message) {
    // Un mensaje fabricado ('Error 502') cuenta como vacío: mejor el texto
    // amigable por status que mostrarle el código pelón al usuario.
    if (message.isEmpty || _mensajeFabricado.hasMatch(message)) {
      return switch (statusCode) {
        400 => const ValidationAppError(
          message: 'Datos inválidos. Revisa la información ingresada.',
        ),
        401 => const UnauthorizedAppError(),
        403 => const ServerAppError(
          message: 'No tienes permiso para realizar esta acción.',
        ),
        404 => const NotFoundAppError(),
        409 => const ConflictAppError(),
        500 => const ServerAppError(),
        _ => ServerAppError(
          message: 'Error del servidor ($statusCode).',
          statusCode: statusCode,
        ),
      };
    }
    return ServerAppError(message: message, statusCode: statusCode);
  }
}
