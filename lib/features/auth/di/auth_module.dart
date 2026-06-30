import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../../../core/socket/socket_module.dart';
import '../data/auth_repository_impl.dart';
import '../data/auth_session_service.dart';
import '../data/device_registration_service.dart';
import '../data/remote/auth_api.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/services/mock_location_detector.dart';
import '../data/platform/mock_location_detector_impl.dart';
import '../data/platform/usb_debug_detector_impl.dart';
import '../domain/services/usb_debug_detector.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(
      ref.watch(apiClientProvider),
    ));

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      ref.watch(authApiProvider),
      ref.watch(authStorageProvider),
    ));

final authSessionServiceProvider = Provider<AuthSessionService>((ref) => AuthSessionService(
      ref.watch(authApiProvider),
      ref.watch(authStorageProvider),
      ref.watch(socketServiceProvider),
    ));

final deviceRegistrationServiceProvider =
    Provider<DeviceRegistrationService>((ref) {
  throw UnimplementedError(
    'DeviceRegistrationService debe ser overriden desde main.dart',
  );
});

final mockLocationDetectorProvider =
    Provider<MockLocationDetector>((ref) => MockLocationDetectorImpl());

final usbDebugDetectorProvider =
    Provider<UsbDebugDetector>((ref) => UsbDebugDetectorImpl());
