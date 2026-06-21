import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viajeseguroconductor/app.dart';

void main() {
  testWidgets('App loads and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: JalaApp()),
    );
    expect(find.byType(JalaApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(JalaApp), findsOneWidget);
  });
}
