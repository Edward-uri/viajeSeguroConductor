import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viajeseguroconductor/app.dart';
import 'package:viajeseguroconductor/core/session/session_service.dart';
import 'package:viajeseguroconductor/features/auth/di/auth_module.dart';

// Sin sesión: evita que el splash construya el ApiClient real (dotenv/red).
class _FakeSessionService implements SessionService {
  @override
  Future<bool> hasSession() async => false;

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('App loads and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWithValue(_FakeSessionService()),
        ],
        child: const JalaApp(),
      ),
    );
    expect(find.byType(JalaApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(JalaApp), findsOneWidget);
  });
}
