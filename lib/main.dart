import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';
import 'core/env/api_config.dart';
import 'core/messaging/background_message_handler.dart';
import 'core/messaging/firebase_push_messaging_service.dart';
import 'core/messaging/messaging_globals.dart';
import 'core/navigation/app_navigator.dart';
import 'core/security/remote_wipe_handler.dart';
import 'core/storage/secure_auth_storage.dart';
import 'core/storage/secure_sensitive_data_storage.dart';
import 'core/storage/sensitive_data_debug.dart';
import 'core/storage/sensitive_data_seeder.dart';
import 'features/auth/data/device_registration_service.dart';
import 'features/auth/di/auth_module.dart';
import 'features/rides/di/rides_module.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Precarga Plus Jakarta Sans: google_fonts la baja en el primer arranque y
  // después la sirve de caché local; sin esto el primer texto renderea con la
  // fuente del sistema y "salta" al llegar la descarga (jank en getstarted/
  // login). La app pasajero tampoco empaqueta la fuente en assets, así que
  // esta es la mitigación compartida más barata.
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
    ]).timeout(const Duration(seconds: 2));
  } catch (e) {
    if (kDebugMode) debugPrint('[App] Fuentes no precargadas: $e');
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) debugPrint('[App] Advertencia: .env no cargado: $e');
  }

  try {
    // Acepta ambas claves: MAPBOX_ACCESS_TOKEN (app pasajero) o MAPBOX_TOKEN (histórica).
    MapboxOptions.setAccessToken(
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? dotenv.env['MAPBOX_TOKEN'] ?? '',
    );
  } catch (e) {
    if (kDebugMode) debugPrint('[App] Error configurando Mapbox: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    if (kDebugMode) debugPrint('[App] Error o Timeout en Firebase: $e');
  }

  try {
    await _initSecureDataAndRemoteWipe();
  } catch (e) {
    if (kDebugMode) debugPrint('[App] Error en servicios de seguridad: $e');
  }

  if (kDebugMode) {
    debugPrint('[Jala] API baseUrl = ${ApiConfig.baseUrl}');
  }

  runApp(
    ProviderScope(
      overrides: [
        deviceRegistrationServiceProvider.overrideWith((ref) {
          final messaging = MessagingGlobals.messaging!;
          final repository = ref.watch(ridesRepositoryProvider);
          return DeviceRegistrationService(messaging, repository);
        }),
      ],
      child: DevicePreview(
        enabled: _shouldEnableDevicePreview(),
        builder: (context) => const JalaApp(),
      ),
    ),
  );
}

/// Siembra los datos sensibles e inicializa el borrado remoto por FCM.
Future<void> _initSecureDataAndRemoteWipe() async {
  final sensitiveStorage = SecureSensitiveDataStorage();
  await SensitiveDataSeeder(sensitiveStorage).seedIfEmpty();
  await debugDumpSensitiveData(sensitiveStorage, 'arranque');

  if (!_isMessagingSupported()) return;

  // El handler de background debe registrarse antes de runApp.
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    if (kDebugMode) debugPrint('[App] No se pudo registrar el background handler: $e');
  }

  final wipeHandler = RemoteWipeHandler(sensitiveStorage, SecureAuthStorage());
  final messaging = FirebasePushMessagingService(
    wipeHandler: wipeHandler,
    sensitiveStorage: sensitiveStorage,
    onWipeCompleted: AppNavigator.goToLogin,
  );
  MessagingGlobals.init(messaging);
  
  // No esperamos (await) a que termine la inicialización de mensajería para no bloquear el UI
  // si el servicio de tokens de Google está caído.
  messaging.initialize().catchError((e) {
    if (kDebugMode) debugPrint('[App] Error asíncrono en messaging.initialize: $e');
  });
}

bool _isMessagingSupported() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

bool _shouldEnableDevicePreview() {
  if (kReleaseMode) return false;
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
