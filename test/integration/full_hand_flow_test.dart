import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/constants/game_constants.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/ai/ai_player_engine.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/ai_difficulty.dart';
import 'package:okey_101_pro/features/game/domain/enums/ai_personality.dart';
import 'package:okey_101_pro/features/game/domain/enums/game_mode.dart';
import 'package:okey_101_pro/features/game/domain/enums/game_phase.dart';
import 'package:okey_101_pro/features/game/domain/services/game_setup_service.dart';
import 'package:okey_101_pro/features/game/domain/services/scoring_engine.dart';

/// Kontrolör/UI katmanı olmadan, yalnızca oyun motoru katmanlarını
/// (`GameSetupService` → `AiPlayerEngine` → `TurnEngine`/`MeldEngine`/
/// `FinishEngine` → `ScoringEngine`) uçtan uca zincirleyen entegrasyon
/// testi. Diğer testler bu motorları küçük, elle kurulmuş durumlarla tek
/// tek doğrular; bu test gerçek uzunlukta bir elin (dağıtımdan
/// puanlamaya, mümkün olduğunca çok tur boyunca) hiçbir kural ihlaline
/// uğramadan, taş kaybetmeden/çoğaltmadan oynanabildiğini ve her zaman
/// (doğal bitiş, deste tükenmesi veya `maxTurnsPerHand` güvenlik ağı
/// yoluyla) bir sonuca ulaştığını garanti eder.
List<Player> _allAiPlayers() => const [
  Player(
    id: 'ai_0',
    name: 'AI Bir',
    avatarId: 'a0',
    isAI: true,
    aiDifficulty: AiDifficulty.easy,
    aiPersonality: AiPersonality.cautious,
  ),
  Player(
    id: 'ai_1',
    name: 'AI İki',
    avatarId: 'a1',
    isAI: true,
    aiDifficulty: AiDifficulty.medium,
    aiPersonality: AiPersonality.aggressive,
  ),
  Player(
    id: 'ai_2',
    name: 'AI Üç',
    avatarId: 'a2',
    isAI: true,
    aiDifficulty: AiDifficulty.medium,
    aiPersonality: AiPersonality.runFocused,
  ),
  Player(
    id: 'ai_3',
    name: 'AI Dört',
    avatarId: 'a3',
    isAI: true,
    aiDifficulty: AiDifficulty.hard,
    aiPersonality: AiPersonality.fastOpener,
  ),
];

void main() {
  group('Tam el akışı (entegrasyon)', () {
    test(
      'baştan sona 4 AI oyuncuyla oynanan bir el, taş korunumunu bozmadan '
      'bitiş fazına ulaşır ve tutarlı bir puanlama üretir',
      () {
        var state = GameSetupService.createNewGame(
          gameId: 'integration_full_hand',
          seed: 42,
          gameMode: GameMode.singleHand,
          rules: GameRulesConfig.quick,
          players: _allAiPlayers(),
          random: SeededRandomProvider(42),
        );

        // GameConstants.maxTurnsPerHand, TurnEngine tarafından zaten
        // uygulanan bir güvenlik ağıdır (bkz. o sabitteki dokümantasyon):
        // deste küçük olduğundan (~20 taş) ve AI'lar sık sık ortadaki açık
        // taşı tercih edebildiğinden, tüm oyuncular AI ise ve hiçbiri 101
        // açamıyorsa deste hiç tükenmeden el teorik olarak çok uzayabilir.
        // Bu döngü bu nedenle motor tarafından garanti edilen üst sınırdan
        // yalnızca küçük bir güvenlik payıyla (+50 tur) fazla dener.
        final maxTurns = GameConstants.maxTurnsPerHand + 50;
        var turns = 0;
        while (state.phase != GamePhase.finished && turns < maxTurns) {
          state = AiPlayerEngine.playTurn(
            state,
            random: SeededRandomProvider(100 + turns),
          );
          turns++;
        }

        expect(
          state.phase,
          GamePhase.finished,
          reason:
              '$maxTurns turda bitmedi; TurnEngine.maxTurnsPerHand güvenlik '
              'ağı beklendiği gibi devreye girmemiş olabilir.',
        );

        // Fiziksel taş korunumu: hiçbir taş kaybolmamalı/çoğalmamalı.
        final tileIdsEverywhere = <String>{
          ...state.drawPile.map((t) => t.id),
          ...state.discardPile.map((t) => t.id),
          for (final p in state.players) ...p.hand.map((t) => t.id),
          for (final m in state.tableMelds)
            ...m.tiles.map((mt) => mt.tile.id),
          if (state.indicatorTile != null) state.indicatorTile!.id,
        };
        expect(tileIdsEverywhere.length, 106);

        final result = ScoringEngine.calculate(state);
        expect(result.playerScores.length, 4);

        if (result.winnerPlayerId != null) {
          final winnerScore = result.playerScores.firstWhere(
            (s) => s.playerId == result.winnerPlayerId,
          );
          expect(winnerScore.finishBonus, greaterThan(0));

          final losersTotalPenalty = result.playerScores
              .where((s) => s.playerId != result.winnerPlayerId)
              .fold<int>(0, (sum, s) => sum + s.totalPenalty);
          expect(winnerScore.finishBonus, losersTotalPenalty);
        }
      },
    );
  });
}
