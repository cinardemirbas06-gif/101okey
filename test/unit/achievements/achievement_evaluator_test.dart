import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/achievements/domain/achievement_definition.dart';
import 'package:okey_101_pro/features/achievements/domain/achievement_evaluator.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld_tile.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/statistics/domain/player_statistics.dart';

import '../../helpers/test_state.dart';

const _humanId = 'human';

Player _player(String id, {AiDifficulty? aiDifficulty}) => Player(
  id: id,
  name: id,
  avatarId: 'a',
  isAI: id != _humanId,
  aiDifficulty: aiDifficulty,
);

void main() {
  group('AchievementEvaluator.evaluate', () {
    test('ilk galibiyet ve okeyle bitiş kazanılan bir elde birlikte açılır', () {
      final state = buildTestGameState(
        players: [_player(_humanId), _player('ai_0')],
        phase: GamePhase.finished,
      ).copyWith(winnerPlayerId: _humanId, finishType: FinishType.okeyFinish);

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(handsWon: 1),
        tilesAddedToTableThisHand: 0,
        humanPlayerId: _humanId,
      );

      expect(unlocked, contains(AchievementId.firstWin));
      expect(unlocked, contains(AchievementId.okeyFinish));
    });

    test('kaybedilen elde kazanma-bağımlı başarımlar açılmaz', () {
      final state = buildTestGameState(
        players: [_player(_humanId), _player('ai_0')],
        phase: GamePhase.finished,
      ).copyWith(winnerPlayerId: 'ai_0', finishType: FinishType.normal);

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(handsPlayed: 1),
        tilesAddedToTableThisHand: 0,
        humanPlayerId: _humanId,
      );

      expect(unlocked, isNot(contains(AchievementId.firstWin)));
      expect(unlocked, isNot(contains(AchievementId.okeyFinish)));
    });

    test('150 üzeri açılış, kazanılmasa bile açılır', () {
      final state = buildTestGameState(
        players: [_player(_humanId), _player('ai_0')],
        phase: GamePhase.finished,
      ).copyWith(winnerPlayerId: 'ai_0');

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(highestOpeningScore: 160),
        tilesAddedToTableThisHand: 0,
        humanPlayerId: _humanId,
      );

      expect(unlocked, contains(AchievementId.highOpening150));
    });

    test('masaya 10 taş işlenmesi bağımsız olarak açılır', () {
      final state = buildTestGameState(
        players: [_player(_humanId), _player('ai_0')],
        phase: GamePhase.finished,
      ).copyWith(winnerPlayerId: 'ai_0');

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(),
        tilesAddedToTableThisHand: 10,
        humanPlayerId: _humanId,
      );

      expect(unlocked, contains(AchievementId.tenTilesToTable));
    });

    test('masada Uzman AI varken kazanınca "Uzman AI\'ı Yen" açılır', () {
      final state = buildTestGameState(
        players: [
          _player(_humanId),
          _player('ai_0', aiDifficulty: AiDifficulty.expert),
        ],
        phase: GamePhase.finished,
      ).copyWith(winnerPlayerId: _humanId, finishType: FinishType.normal);

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(handsWon: 1),
        tilesAddedToTableThisHand: 0,
        humanPlayerId: _humanId,
      );

      expect(unlocked, contains(AchievementId.beatExpertAi));
    });

    test('hiç okey kullanmadan kazanınca ilgili başarım açılır', () {
      final ownMeld = Meld(
        id: 'm1',
        type: MeldType.run,
        openedByPlayerId: _humanId,
        tiles: [
          MeldTile(tile: normalTile('r1', TileColor.red, 1)),
          MeldTile(tile: normalTile('r2', TileColor.red, 2)),
          MeldTile(tile: normalTile('r3', TileColor.red, 3)),
        ],
      );
      final state = buildTestGameState(
        players: [_player(_humanId), _player('ai_0')],
        phase: GamePhase.finished,
        tableMelds: [ownMeld],
      ).copyWith(winnerPlayerId: _humanId, finishType: FinishType.normal);

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(handsWon: 1),
        tilesAddedToTableThisHand: 0,
        humanPlayerId: _humanId,
      );

      expect(unlocked, contains(AchievementId.noJokerWin));
    });

    test('perlerinde okey kullanarak kazanınca o başarım açılmaz', () {
      final ownMeld = Meld(
        id: 'm1',
        type: MeldType.run,
        openedByPlayerId: _humanId,
        tiles: [
          MeldTile(tile: normalTile('r1', TileColor.red, 1)),
          MeldTile(tile: normalTile('r2', TileColor.red, 2)),
          MeldTile(
            tile: okeyJoker('okey1', TileColor.blue, 9),
            representedColor: TileColor.red,
            representedNumber: 3,
          ),
        ],
      );
      final state = buildTestGameState(
        players: [_player(_humanId), _player('ai_0')],
        phase: GamePhase.finished,
        tableMelds: [ownMeld],
      ).copyWith(winnerPlayerId: _humanId, finishType: FinishType.normal);

      final unlocked = AchievementEvaluator.evaluate(
        finishedState: state,
        statisticsAfterHand: const PlayerStatistics(handsWon: 1),
        tilesAddedToTableThisHand: 0,
        humanPlayerId: _humanId,
      );

      expect(unlocked, isNot(contains(AchievementId.noJokerWin)));
    });
  });
}
