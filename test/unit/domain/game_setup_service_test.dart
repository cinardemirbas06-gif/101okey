import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/services/game_setup_service.dart';

import '../../helpers/test_players.dart';

void main() {
  group('GameSetupService.createNewGame', () {
    test('başlayan oyuncu taş çekmeden 22 taşla oynanabilir duruma gelir',
        () {
      final state = GameSetupService.createNewGame(
        gameId: 'game_1',
        seed: 42,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(42),
        startingPlayerIndex: 0,
      );

      expect(state.activePlayerIndex, 0);
      expect(state.activePlayer.hand.length, 22);
      expect(state.hasDrawnThisTurn, isTrue);
      expect(state.phase, GamePhase.waitingForMeld);
      expect(state.players[1].hand.length, 21);
      expect(state.players[2].hand.length, 21);
      expect(state.players[3].hand.length, 21);
    });

    test('gösterge ve okey ayarlanır, okey taşı işaretlenmiş taşlardan biridir',
        () {
      final state = GameSetupService.createNewGame(
        gameId: 'game_2',
        seed: 99,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(99),
        startingPlayerIndex: 1,
      );

      expect(state.indicatorTile, isNotNull);
      expect(state.okeyTile, isNotNull);
      expect(state.okeyTile!.isOkey, isTrue);
      expect(state.okeyTile!.color, state.indicatorTile!.color);
    });

    test('toplam taş sayısı (eller + deste + gösterge) 106\'dır', () {
      final state = GameSetupService.createNewGame(
        gameId: 'game_3',
        seed: 7,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(7),
        startingPlayerIndex: 3,
      );

      final handTotal = state.players.fold<int>(
        0,
        (sum, p) => sum + p.hand.length,
      );
      expect(handTotal + state.drawPile.length + 1, 106);
    });

    test('aynı seed aynı taş dağılımını üretir (tekrarlanabilirlik)', () {
      final stateA = GameSetupService.createNewGame(
        gameId: 'game_a',
        seed: 555,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(555),
        startingPlayerIndex: 0,
      );
      final stateB = GameSetupService.createNewGame(
        gameId: 'game_b',
        seed: 555,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(555),
        startingPlayerIndex: 0,
      );

      expect(
        stateA.players.map((p) => p.hand.map((t) => t.id).toList()),
        stateB.players.map((p) => p.hand.map((t) => t.id).toList()),
      );
      expect(stateA.indicatorTile!.id, stateB.indicatorTile!.id);
      expect(
        stateA.drawPile.map((t) => t.id),
        stateB.drawPile.map((t) => t.id),
      );
    });

    test('kural setiyle uyuşmayan oyuncu sayısında hata fırlatır', () {
      expect(
        () => GameSetupService.createNewGame(
          gameId: 'game_bad',
          seed: 1,
          gameMode: GameMode.singleHand,
          rules: GameRulesConfig.standard,
          players: buildTestPlayers().sublist(0, 2),
          random: SeededRandomProvider(1),
        ),
        throwsArgumentError,
      );
    });
  });
}
