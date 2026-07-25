import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/achievements/data/achievements_repository.dart';
import 'package:okey_101_pro/features/achievements/domain/achievement_definition.dart';
import 'package:okey_101_pro/features/achievements/presentation/achievements_screen.dart';

import '../helpers/test_storage.dart';

void main() {
  Widget wrap() => const MaterialApp(home: AchievementsScreen());

  group('AchievementsScreen', () {
    testWidgets('kayıt yokken tüm başarımlar kilitli ikonla gösterilir', (
      tester,
    ) async {
      // NOT: Hive'ın gerçek dosya G/Ç'si, `testWidgets`'ın fake-async test
      // alanı içinde `tester.runAsync` olmadan asla tamamlanmıyor (bu,
      // bu proje için deneyerek doğrulanmış bir ortam kısıtıdır); bu
      // yüzden sıfırlama burada `setUp` yerine her testin içinde,
      // `runAsync` ile çağrılır.
      await tester.runAsync(() => resetTestStorage());
      await tester.pumpWidget(wrap());

      // Liste ListView.builder ile tembel (lazy) çizildiği için test
      // görünümüne yalnızca ilk birkaç kart sığar; bu yüzden tam sayı
      // yerine (a) en az bir kilit ikonunun göründüğünü ve (b) hiçbir
      // kupa ikonunun görünmediğini doğrulamak yeterli ve daha
      // dayanıklıdır.
      expect(
        find.text(AchievementCatalog.all.first.title),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      expect(find.byIcon(Icons.emoji_events), findsNothing);
    });

    testWidgets('açılan başarım kilit yerine kupa ikonuyla gösterilir', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await resetTestStorage();
        await AchievementsRepository.saveUnlocked({AchievementId.firstWin});
      });

      await tester.pumpWidget(wrap());

      // firstWin katalogdaki ilk öğe, dolayısıyla listenin en üstünde
      // (her zaman görünür alanda) yer alır.
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
    });
  });
}
