import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/home/presentation/screens/rules_screen.dart';

void main() {
  group('RulesScreen', () {
    testWidgets('tüm kural bölüm başlıklarını gösterir', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RulesScreen()));

      expect(find.text('Taşlar ve Okey'), findsOneWidget);
      expect(find.text('Dağıtım ve Sıra'), findsOneWidget);

      // Liste ekrandan uzun olabileceğinden (ListView.separated tembel
      // çizer), sonraki başlıklara ulaşmak için aşağı kaydırmak gerekir;
      // bu, önceki başlıkları görünüm dışına itebileceği için onları
      // burada tekrar sorgulamıyoruz.
      await tester.dragUntilVisible(
        find.text('Seri ve Grup'),
        find.byType(Scrollable),
        const Offset(0, -200),
      );
      expect(find.text('Seri ve Grup'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('101 Açılış'),
        find.byType(Scrollable),
        const Offset(0, -200),
      );
      expect(find.text('101 Açılış'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Bitiş'),
        find.byType(Scrollable),
        const Offset(0, -200),
      );
      expect(find.text('Bitiş'), findsOneWidget);
    });
  });
}
