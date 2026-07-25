import 'package:flutter_test/flutter_test.dart';

import 'package:okey_101_pro/app/app.dart';

void main() {
  testWidgets('OkeyProApp açılışta yer tutucu ekranı gösterir',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OkeyProApp());

    expect(find.textContaining('101 Okey Pro'), findsOneWidget);
  });
}
