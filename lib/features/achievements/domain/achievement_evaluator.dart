import '../../game/domain/entities/game_state.dart';
import '../../game/domain/enums/ai_difficulty.dart';
import '../../game/domain/enums/finish_type.dart';
import '../../statistics/domain/player_statistics.dart';
import 'achievement_definition.dart';

/// Bir elin sonunda hangi başarımların kazanıldığını değerlendiren saf
/// fonksiyon.
///
/// Kazanılan başarımların KÜMESİNİ döndürür; çağıran taraf bunu daha
/// önce açılmış başarımlarla karşılaştırıp YENİ olanları belirler ve
/// kalıcı olarak saklar.
abstract final class AchievementEvaluator {
  const AchievementEvaluator._();

  static Set<AchievementId> evaluate({
    required GameState finishedState,
    required PlayerStatistics statisticsAfterHand,
    required int tilesAddedToTableThisHand,
    required String humanPlayerId,
  }) {
    final unlocked = <AchievementId>{};
    final won = finishedState.winnerPlayerId == humanPlayerId;

    if (won) {
      if (statisticsAfterHand.handsWon >= 1) {
        unlocked.add(AchievementId.firstWin);
      }
      if (statisticsAfterHand.currentWinStreak >= 3) {
        unlocked.add(AchievementId.winStreak3);
      }
      if (statisticsAfterHand.currentWinStreak >= 10) {
        unlocked.add(AchievementId.winStreak10);
      }

      switch (finishedState.finishType) {
        case FinishType.okeyFinish:
          unlocked.add(AchievementId.okeyFinish);
        case FinishType.pairFinish:
          unlocked.add(AchievementId.pairFinish);
        case FinishType.handFinish:
          unlocked.add(AchievementId.handFinish);
        case FinishType.normal:
        case FinishType.indicatorFinish:
        case null:
          break;
      }

      final opponentsHaveExpert = finishedState.players
          .where((p) => p.id != humanPlayerId)
          .any((p) => p.aiDifficulty == AiDifficulty.expert);
      if (opponentsHaveExpert) {
        unlocked.add(AchievementId.beatExpertAi);
      }

      final ownMelds = finishedState.tableMelds.where(
        (m) => m.openedByPlayerId == humanPlayerId,
      );
      final usedAnyJoker = ownMelds.any(
        (m) => m.tiles.any((mt) => mt.tile.actsAsJoker),
      );
      if (ownMelds.isNotEmpty && !usedAnyJoker) {
        unlocked.add(AchievementId.noJokerWin);
      }
    }

    if (statisticsAfterHand.highestOpeningScore >= 150) {
      unlocked.add(AchievementId.highOpening150);
    }
    if (tilesAddedToTableThisHand >= 10) {
      unlocked.add(AchievementId.tenTilesToTable);
    }

    return unlocked;
  }
}
