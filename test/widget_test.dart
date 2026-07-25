import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:okey_101_pro/app/app.dart';

import 'helpers/test_storage.dart';

void main() {
  testWidgets('OkeyProApp açılışta ana menüyü gösterir', (
    WidgetTester tester,
  ) async {
    // NOT: Hive'ın gerçek dosya G/Ç'si, `testWidgets`'ın fake-async test
    // alanı içinde `tester.runAsync` olmadan asla tamamlanmıyor (bu, bu
    // proje için deneyerek doğrulanmış bir ortam kısıtıdır); bu yüzden
    // sıfırlama burada `setUp` yerine testin içinde, `runAsync` ile
    // çağrılır.
    await tester.runAsync(() => resetTestStorage());
    await tester.pumpWidget(
      const ProviderScope(child: OkeyProApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('101 Okey Pro'), findsOneWidget);
    expect(find.text('Oyuna Başla'), findsOneWidget);
  });
}
