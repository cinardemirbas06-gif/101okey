import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/statistics/data/statistics_repository.dart';
import 'package:okey_101_pro/features/statistics/domain/player_statistics.dart';
import 'package:okey_101_pro/features/statistics/presentation/statistics_screen.dart';

import '../helpers/test_storage.dart';

void main() {
  Widget wrap() => const MaterialApp(home: StatisticsScreen());

  group('StatisticsScreen', () {
    testWidgets('kayıt yokken varsayılan (sıfır) istatistikleri gösterir', (
      tester,
    ) async {
      // NOT: Hive'ın gerçek dosya G/Ç'si, `testWidgets`'ın fake-async test
      // alanı içinde `tester.runAsync` olmadan asla tamamlanmıyor (bu,
      // bu proje için deneyerek doğrulanmış bir ortam kısıtıdır); bu
      // yüzden sıfırlama burada `setUp` yerine her testin içinde,
      // `runAsync` ile çağrılır.
      await tester.runAsync(() => resetTestStorage());
      await tester.pumpWidget(wrap());

      expect(find.text('Oynanan el'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('kaydedilmiş istatistikleri doğru gösterir', (tester) async {
      await tester.runAsync(() async {
        await resetTestStorage();
        await StatisticsRepository.save(
          PlayerStatistics.empty.copyWith(
            handsPlayed: 12,
            handsWon: 5,
            okeyFinishCount: 2,
          ),
        );
      });

      await tester.pumpWidget(wrap());

      expect(find.text('12'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
