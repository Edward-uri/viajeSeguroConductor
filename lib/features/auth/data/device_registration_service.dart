import 'package:flutter/foundation.dart';

import '../../../core/messaging/firebase_push_messaging_service.dart';
import '../../rides/domain/repositories/rides_repository.dart';

class DeviceRegistrationService {
  DeviceRegistrationService(this._messaging, this._repository);

  final FirebasePushMessagingService _messaging;
  final RidesRepository _repository;

  Future<void> registerCurrentDevice() async {
    try {
      final token = await _messaging.getDeviceToken();
      if (token == null) return;

      await _repository.registerDevice(
        tokenFcm: token,
        plataforma: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      );

      if (kDebugMode) {
        // Enmascarado: nunca loguear el token FCM completo.
        final masked = '${token.length > 8 ? token.substring(0, 8) : token}…';
        debugPrint('[DeviceRegistration] Token FCM registrado: $masked');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeviceRegistration] Error registrando token FCM: $e');
      }
    }
  }
}
