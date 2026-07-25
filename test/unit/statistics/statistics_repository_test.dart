import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/statistics/data/statistics_repository.dart';
import 'package:okey_101_pro/features/statistics/domain/player_statistics.dart';

import '../../helpers/test_storage.dart';

void main() {
  setUp(() async {
    await resetTestStorage();
  });

  group('StatisticsRepository', () {
    test('kayıt yokken boş istatistik döner', () {
      expect(StatisticsRepository.load(), PlayerStatistics.empty);
    });

    test('save/load round-trip istatistikleri korur', () async {
      const stats = PlayerStatistics(
        handsPlayed: 10,
        handsWon: 4,
        okeyFinishCount: 1,
        highestOpeningScore: 132,
        totalOpeningScore: 400,
        openingCount: 4,
        longestWinStreak: 3,
        currentWinStreak: 2,
      );

      await StatisticsRepository.save(stats);
      expect(StatisticsRepository.load(), stats);
    });

    test('reset istatistikleri varsayılana döndürür', () async {
      await StatisticsRepository.save(
        PlayerStatistics.empty.copyWith(handsPlayed: 5),
      );
      await StatisticsRepository.reset();

      expect(StatisticsRepository.load(), PlayerStatistics.empty);
    });

    test('winRate ve averageOpeningScore doğru hesaplanır', () {
      const stats = PlayerStatistics(
        handsPlayed: 4,
        handsWon: 1,
        totalOpeningScore: 300,
        openingCount: 3,
      );

      expect(stats.winRate, 0.25);
      expect(stats.averageOpeningScore, 100);
    });
  });
}
