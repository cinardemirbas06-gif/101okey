import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/entities/scoring_rules.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/services/scoring_engine.dart';

import '../../helpers/test_state.dart';

Player _player(
  String id, {
  List<dynamic> hand = const [],
  bool hasOpened = true,
}) {
  return Player(
    id: id,
    name: id,
    avatarId: 'avatar',
    hand: hand.cast(),
    hasOpened: hasOpened,
  );
}

void main() {
  group('ScoringEngine.calculate (normal kazanç)', () {
    test('kazanan, kaybedenlerin toplam cezasını sıfır-toplamlı kazanır', () {
      final winner = _player('p1');
      final loserA = _player(
        'p2',
        hand: [normalTile('r5', TileColor.red, 5)],
      );
      final loserB = _player(
        'p3',
        hand: [normalTile('b8', TileColor.blue, 8)],
      );
      final state = buildTestGameState(
        players: [winner, loserA, loserB],
        phase: GamePhase.calculatingScore,
      ).copyWith(winnerPlayerId: 'p1', finishType: FinishType.normal);

      final result = ScoringEngine.calculate(state);

      final winnerScore = result.playerScores.firstWhere(
        (s) => s.playerId == 'p1',
      );
      final scoreA = result.playerScores.firstWhere((s) => s.playerId == 'p2');
      final scoreB = result.playerScores.firstWhere((s) => s.playerId == 'p3');

      expect(scoreA.totalPenalty, 5);
      expect(scoreB.totalPenalty, 8);
      expect(winnerScore.totalPenalty, 0);
      expect(winnerScore.roundScoreDelta, 13);
      expect(scoreA.roundScoreDelta, -5);
      expect(scoreB.roundScoreDelta, -8);
    });

    test('açılmamış oyuncuya çarpan uygulanır', () {
      final winner = _player('p1');
      final unopenedLoser = _player(
        'p2',
        hasOpened: false,
        hand: [normalTile('r5', TileColor.red, 5)],
      );
      final state = buildTestGameState(
        players: [winner, unopenedLoser],
        phase: GamePhase.calculatingScore,
      ).copyWith(winnerPlayerId: 'p1', finishType: FinishType.normal);

      final result = ScoringEngine.calculate(state);
      final loserScore = result.playerScores.firstWhere(
        (s) => s.playerId == 'p2',
      );

      expect(
        loserScore.totalPenalty,
        5 * GameRulesConfig.standard.scoringRules.unopenedPenaltyMultiplier,
      );
    });

    test('elde kalan okey/sahte okey için sabit ceza eklenir', () {
      final winner = _player('p1');
      final loser = _player(
        'p2',
        hand: [
          normalTile('r5', TileColor.red, 5),
          okeyJoker('okey1', TileColor.blue, 9),
          falseOkeyJoker('fo1'),
        ],
      );
      final state = buildTestGameState(
        players: [winner, loser],
        phase: GamePhase.calculatingScore,
      ).copyWith(winnerPlayerId: 'p1', finishType: FinishType.normal);

      final result = ScoringEngine.calculate(state);
      final loserScore = result.playerScores.firstWhere(
        (s) => s.playerId == 'p2',
      );

      const rules = ScoringRules.standard;
      final expectedBase = 5 + rules.okeyRemainingPenalty + rules.falseOkeyRemainingPenalty;
      expect(loserScore.totalPenalty, expectedBase);
      expect(loserScore.okeyRemainingPenalty, rules.okeyRemainingPenalty);
      expect(loserScore.falseOkeyRemainingPenalty, rules.falseOkeyRemainingPenalty);
    });

    test('ceza maxHandPenalty ile sınırlandırılır', () {
      final winner = _player('p1');
      final loser = _player(
        'p2',
        hasOpened: false,
        hand: List.generate(
          10,
          (i) => normalTile('r$i', TileColor.red, 13),
        ),
      );
      final rules = GameRulesConfig.standard.copyWith(
        scoringRules: GameRulesConfig.standard.scoringRules.copyWith(
          maxHandPenalty: 50,
        ),
      );
      final state = buildTestGameState(
        players: [winner, loser],
        phase: GamePhase.calculatingScore,
        rules: rules,
      ).copyWith(winnerPlayerId: 'p1', finishType: FinishType.normal);

      final result = ScoringEngine.calculate(state);
      final loserScore = result.playerScores.firstWhere(
        (s) => s.playerId == 'p2',
      );

      expect(loserScore.totalPenalty, 50);
    });

    test('okeyle bitiş çarpanı tüm kaybedenlerin cezasını katlar', () {
      final winner = _player('p1');
      final loser = _player(
        'p2',
        hand: [normalTile('r5', TileColor.red, 5)],
      );
      final state = buildTestGameState(
        players: [winner, loser],
        phase: GamePhase.calculatingScore,
      ).copyWith(winnerPlayerId: 'p1', finishType: FinishType.okeyFinish);

      final result = ScoringEngine.calculate(state);
      final loserScore = result.playerScores.firstWhere(
        (s) => s.playerId == 'p2',
      );

      expect(
        loserScore.totalPenalty,
        5 * GameRulesConfig.standard.scoringRules.okeyFinishMultiplier,
      );
    });
  });

  group('ScoringEngine.calculate (kazanan yok / deste tükenmesi)', () {
    test('handIsDraw politikasında kimse kazanmaz, herkes kendi cezasını '
        'alır', () {
      final playerA = _player(
        'p1',
        hand: [normalTile('r5', TileColor.red, 5)],
      );
      final playerB = _player(
        'p2',
        hand: [normalTile('b8', TileColor.blue, 8)],
      );
      final state = buildTestGameState(
        players: [playerA, playerB],
        phase: GamePhase.finished,
      );

      final result = ScoringEngine.calculate(state);

      expect(result.winnerPlayerId, isNull);
      expect(
        result.playerScores.firstWhere((s) => s.playerId == 'p1').roundScoreDelta,
        -5,
      );
      expect(
        result.playerScores.firstWhere((s) => s.playerId == 'p2').roundScoreDelta,
        -8,
      );
    });

    test('awardToLowestHandValue politikasında en düşük elli oyuncu '
        'kazanır', () {
      final playerA = _player(
        'p1',
        hand: [normalTile('r10', TileColor.red, 10)],
      );
      final playerB = _player(
        'p2',
        hand: [normalTile('b2', TileColor.blue, 2)],
      );
      final rules = GameRulesConfig.standard.copyWith(
        deckExhaustionPolicy: DeckExhaustionPolicy.awardToLowestHandValue,
      );
      final state = buildTestGameState(
        players: [playerA, playerB],
        phase: GamePhase.finished,
        rules: rules,
      );

      final result = ScoringEngine.calculate(state);

      expect(result.winnerPlayerId, 'p2');
      final winnerScore = result.playerScores.firstWhere(
        (s) => s.playerId == 'p2',
      );
      expect(winnerScore.totalPenalty, 0);
      expect(winnerScore.roundScoreDelta, 10);
    });
  });
}
