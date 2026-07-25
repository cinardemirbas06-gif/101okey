import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/settings/data/settings_repository.dart';
import 'package:okey_101_pro/features/settings/presentation/screens/settings_screen.dart';

import '../helpers/test_storage.dart';

void main() {
  Widget wrap() => const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      );

  group('SettingsScreen', () {
    testWidgets('titreşim anahtarını kapatmak kalıcı ayarı günceller', (
      tester,
    ) async {
      // NOT: Hive'ın gerçek dosya G/Ç'si, `testWidgets`'ın fake-async test
      // alanı içinde `tester.runAsync` olmadan asla tamamlanmıyor (bu,
      // bu proje için deneyerek doğrulanmış bir ortam kısıtıdır); bu
      // yüzden hem sıfırlama hem de gerçek bir Hive yazması tetikleyen
      // etkileşimler burada `runAsync` ile çağrılır.
      await tester.runAsync(() => resetTestStorage());
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(SettingsRepository.load().hapticFeedbackEnabled, isTrue);

      await tester.runAsync(() async {
        await tester.tap(find.text('Titreşim geri bildirimi'));
        await tester.pumpAndSettle();
      });

      expect(SettingsRepository.load().hapticFeedbackEnabled, isFalse);
    });

    testWidgets('sıra süresi kapalıyken süre seçenekleri gizlenir', (
      tester,
    ) async {
      await tester.runAsync(() => resetTestStorage());
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<int>), findsOneWidget);

      // Bu etkileşim, tetiklediği (fire-and-forget) gerçek Hive yazmasıyla
      // birlikte `SegmentedButton` alt ağacını da kaldırır; bu ekranın asıl
      // amacı olan görünür davranışı (süre seçeneklerinin kaybolması)
      // doğrulamak yeterlidir — kalıcılığın doğruluğu zaten
      // `settings_repository_test.dart`'ta ayrıca test edilir.
      await tester.runAsync(() async {
        await tester.tap(find.text('Tur süresi sınırı'));
        await tester.pumpAndSettle();
      });

      expect(find.byType(SegmentedButton<int>), findsNothing);
    });
  });
}
