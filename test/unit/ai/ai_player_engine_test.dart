import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/ai/ai_player_engine.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_state.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/services/game_setup_service.dart';

import '../../helpers/test_players.dart';
import '../../helpers/test_state.dart';

void main() {
  group('AiPlayerEngine.playTurn', () {
    test('AI olmayan oyuncu için çağrılırsa hata fırlatır', () {
      final human = Player(id: 'p1', name: 'Çınar', avatarId: 'a1');
      final state = buildTestGameState(players: [human, buildTestPlayers()[1]]);

      expect(
        () => AiPlayerEngine.playTurn(state, random: SeededRandomProvider(1)),
        throwsArgumentError,
      );
    });

    test('AI turu sonunda elindeki taş sayısı kurallara uygun kalır', () {
      final aiPlayer = Player(
        id: 'ai1',
        name: 'AI',
        avatarId: 'a1',
        isAI: true,
        aiDifficulty: AiDifficulty.easy,
        aiPersonality: AiPersonality.cautious,
        hand: [
          normalTile('r1', TileColor.red, 1),
          normalTile('r2', TileColor.red, 2),
          normalTile('y9', TileColor.yellow, 9),
          normalTile('bl3', TileColor.black, 3),
        ],
      );
      final other = Player(
        id: 'p2',
        name: 'Diğer',
        avatarId: 'a2',
        hand: [normalTile('m4', TileColor.blue, 4)],
      );
      final drawPile = [normalTile('drawn', TileColor.yellow, 5)];
      final state = buildTestGameState(
        players: [aiPlayer, other],
        phase: GamePhase.waitingForDraw,
        hasDrawnThisTurn: false,
        drawPile: drawPile,
      );

      final result = AiPlayerEngine.playTurn(
        state,
        random: SeededRandomProvider(7),
      );

      final aiAfter = result.players.firstWhere((p) => p.id == 'ai1');
      // Başlangıçta 4 taş + 1 çekilen - 1 atılan = 4.
      expect(aiAfter.hand.length, 4);
      expect(result.discardPile.length, 1);
      expect(result.phase, GamePhase.waitingForDraw);
    });

    test('yeterli puanlı el ile AI otomatik açılış yapar', () {
      final aiPlayer = Player(
        id: 'ai1',
        name: 'AI',
        avatarId: 'a1',
        isAI: true,
        aiDifficulty: AiDifficulty.hard,
        hand: [
          normalTile('r13', TileColor.red, 13),
          normalTile('bl13', TileColor.black, 13),
          normalTile('m13', TileColor.blue, 13),
          normalTile('y13_a', TileColor.yellow, 13),
          normalTile('y9', TileColor.yellow, 9),
          normalTile('y10', TileColor.yellow, 10),
          normalTile('y11', TileColor.yellow, 11),
          normalTile('y12', TileColor.yellow, 12),
          normalTile('y13_b', TileColor.yellow, 13),
          normalTile('bl2', TileColor.black, 2),
        ],
      );
      final other = Player(id: 'p2', name: 'Diğer', avatarId: 'a2');
      final drawPile = [normalTile('drawn', TileColor.red, 1)];
      final state = buildTestGameState(
        players: [aiPlayer, other],
        phase: GamePhase.waitingForDraw,
        hasDrawnThisTurn: false,
        drawPile: drawPile,
      );

      final result = AiPlayerEngine.playTurn(
        state,
        random: SeededRandomProvider(3),
      );

      final aiAfter = result.players.firstWhere((p) => p.id == 'ai1');
      expect(aiAfter.hasOpened, isTrue);
      expect(result.tableMelds, isNotEmpty);
    });

    test('tam bir oyunda birbirini izleyen AI turları hatasız çalışır', () {
      final players = buildTestPlayers()
          .map(
            (p) => p.copyWith(
              isAI: true,
              aiDifficulty: AiDifficulty.medium,
              aiPersonality: AiPersonality.cautious,
            ),
          )
          .toList();
      var state = GameSetupService.createNewGame(
        gameId: 'ai_smoke_test',
        seed: 42,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: players,
        random: SeededRandomProvider(42),
        startingPlayerIndex: 0,
      );

      final random = SeededRandomProvider(99);
      for (var i = 0; i < 40 && state.phase != GamePhase.finished; i++) {
        final totalBefore = _totalTileCount(state);
        state = AiPlayerEngine.playTurn(state, random: random);
        final totalAfter = _totalTileCount(state);
        expect(
          totalAfter,
          totalBefore,
          reason: 'tur $i sonrası toplam taş sayısı değişmemeli',
        );
        if (state.phase == GamePhase.calculatingScore) break;
      }
    });
  });
}

int _totalTileCount(GameState state) {
  final handTiles = state.players.fold<int>(0, (sum, p) => sum + p.hand.length);
  final tableTiles = state.tableMelds.fold<int>(
    0,
    (sum, m) => sum + m.tileCount,
  );
  return handTiles + tableTiles + state.drawPile.length + state.discardPile.length;
}
