import 'firebase_push_messaging_service.dart';

/// Acceso global al servicio de mensajería para registrar
/// el token FCM desde flujos que no tienen acceso al árbol de providers.
///
/// Se asigna durante el bootstrap en `main()`.
class MessagingGlobals {
  MessagingGlobals._();

  static FirebasePushMessagingService? _messaging;

  static FirebasePushMessagingService? get messaging => _messaging;

  static void init(FirebasePushMessagingService service) {
    _messaging = service;
  }
}
