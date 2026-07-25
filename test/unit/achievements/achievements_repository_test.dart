import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/achievements/data/achievements_repository.dart';
import 'package:okey_101_pro/features/achievements/domain/achievement_definition.dart';

import '../../helpers/test_storage.dart';

void main() {
  setUp(() async {
    await resetTestStorage();
  });

  group('AchievementsRepository', () {
    test('kayıt yokken boş küme döner', () {
      expect(AchievementsRepository.loadUnlocked(), isEmpty);
    });

    test('save/load round-trip açılan başarımları korur', () async {
      const unlocked = {
        AchievementId.firstWin,
        AchievementId.okeyFinish,
        AchievementId.winStreak3,
      };

      await AchievementsRepository.saveUnlocked(unlocked);
      final loaded = AchievementsRepository.loadUnlocked();

      expect(loaded, unlocked);
    });
  });
}
