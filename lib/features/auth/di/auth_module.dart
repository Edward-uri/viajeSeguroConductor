import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../core/storage/auth_storage.dart';
import '../data/auth_simulator.dart';
import '../data/platform/mock_location_detector_impl.dart';
import '../data/platform/usb_debug_detector_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/services/mock_location_detector.dart';
import '../domain/services/usb_debug_detector.dart';


class AuthModule {
  const AuthModule._();

  static List<SingleChildWidget> providers() => <SingleChildWidget>[
        Provider<AuthRepository>(
          create: (ctx) => AuthSimulator(ctx.read<AuthStorage>()),
        ),
        Provider<MockLocationDetector>(
          create: (_) => MockLocationDetectorImpl(),
        ),
        Provider<UsbDebugDetector>(
          create: (_) => UsbDebugDetectorImpl(),
        ),
      ];
}
