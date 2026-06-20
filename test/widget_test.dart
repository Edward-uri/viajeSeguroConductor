import 'package:flutter_test/flutter_test.dart';

import 'package:viajeseguroconductor/app.dart';

void main() {
  testWidgets('App loads and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const JalaApp());
    expect(find.byType(JalaApp), findsOneWidget);
  });
}
