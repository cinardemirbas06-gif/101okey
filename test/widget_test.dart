import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:okey_101_pro/app/app.dart';

void main() {
  testWidgets('OkeyProApp açılışta ana menüyü gösterir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: OkeyProApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('101 Okey Pro'), findsOneWidget);
    expect(find.text('Oyuna Başla'), findsOneWidget);
  });
}
