import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/app/app.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/presentation/controllers/game_controller.dart';

import '../helpers/test_storage.dart';

void main() {
  testWidgets(
    'Ana menü -> kurulum -> oyun masası akışı çalışır',
    (tester) async {
      // NOT: Hive'ın gerçek dosya G/Ç'si, `testWidgets`'ın fake-async test
      // alanı içinde `tester.runAsync` olmadan asla tamamlanmıyor (bu,
      // bu proje için deneyerek doğrulanmış bir ortam kısıtıdır); bu
      // yüzden sıfırlama burada `setUp` yerine testin içinde, `runAsync`
      // ile çağrılır.
      await tester.runAsync(() => resetTestStorage());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith(
              (ref) => GameController(SeededRandomProvider(11)),
            ),
          ],
          child: const OkeyProApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Oyuna Başla'), findsOneWidget);
      await tester.tap(find.text('Oyuna Başla'));
      await tester.pumpAndSettle();

      expect(find.text('Oyunu Başlat'), findsOneWidget);
      await tester.tap(find.text('Oyunu Başlat'));
      await tester.pump();

      // AI turlarının (kolay zorlukta ~400ms/tur) ilerlemesi için zamanı
      // ilerlet; sahte saat sayesinde gerçek bekleme olmadan çalışır.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      // NOT: Burada pumpAndSettle KULLANILMAZ — GameTableScreen, tur
      // süresi sayacı için her saniye tetiklenen sürekli bir
      // Timer.periodic çalıştırır; bu, pumpAndSettle'ın hiçbir zaman
      // "durulmuş" durumu görememesine (zaman aşımına) yol açar.
      await tester.pump(const Duration(milliseconds: 500));

      // Oyun masası ekranına ulaşıldığını doğrula (üst çubuktaki el/tur
      // bilgisi her zaman görünür olmalı). "El 1" tek başına artık hem üst
      // çubukta hem de kural rozetleri şeridindeki el sayacı rozetinde
      // eşleştiği için tur bilgisini de içeren daha spesifik bir metin
      // aranır.
      expect(find.textContaining('El 1 · Tur'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
