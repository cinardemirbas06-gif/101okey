import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/achievements/domain/achievement_definition.dart';
import 'package:okey_101_pro/features/game/domain/entities/hand_score_result.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/entities/player_hand_score.dart';
import 'package:okey_101_pro/features/game/domain/enums/finish_type.dart';
import 'package:okey_101_pro/features/game/presentation/controllers/game_controller.dart';
import 'package:okey_101_pro/features/game/presentation/controllers/game_session_state.dart';
import 'package:okey_101_pro/features/game/presentation/screens/hand_result_screen.dart';

import '../helpers/test_state.dart';
import '../helpers/test_storage.dart';

/// [GameController] normalde her hamlesini motor katmanı üzerinden
/// üretir; bu test yalnızca sonuç ekranının bir [GameSessionState]'i
/// doğru gösterdiğini doğrulamak istediği için, `@protected` `state`
/// alanına yalnızca alt sınıf içinden (meşru biçimde) erişen ince bir
/// test çift (double) tanımlanır.
class _FakeGameController extends GameController {
  _FakeGameController(GameSessionState initialState)
      : super(SeededRandomProvider(1)) {
    state = initialState;
  }
}

void main() {
  Widget wrap(GameSessionState sessionState) {
    return ProviderScope(
      overrides: [
        gameControllerProvider.overrideWith(
          (ref) => _FakeGameController(sessionState),
        ),
      ],
      child: const MaterialApp(home: HandResultScreen()),
    );
  }

  final players = [
    const Player(id: 'human', name: 'Test Oyuncu', avatarId: 'a0'),
    const Player(id: 'ai_0', name: 'AI Bir', avatarId: 'a1', isAI: true),
  ];

  group('HandResultScreen', () {
    testWidgets('kazananı ve puan dökümünü gösterir', (tester) async {
      // NOT: Hive'ın gerçek dosya G/Ç'si, `testWidgets`'ın fake-async test
      // alanı içinde `tester.runAsync` olmadan asla tamamlanmıyor (bu,
      // bu proje için deneyerek doğrulanmış bir ortam kısıtıdır); bu
      // yüzden sıfırlama burada `setUp` yerine her testin içinde,
      // `runAsync` ile çağrılır.
      await tester.runAsync(() => resetTestStorage());
      final sessionState = GameSessionState(
        gameState: buildTestGameState(players: players),
        lastHandScore: const HandScoreResult(
          handNumber: 1,
          winnerPlayerId: 'human',
          finishType: FinishType.normal,
          playerScores: [
            PlayerHandScore(
              playerId: 'human',
              remainingTileCount: 0,
              remainingTileValue: 0,
              wasOpened: true,
              penaltyMultiplier: 1,
              finishBonus: 50,
              totalPenalty: 0,
              roundScoreDelta: 50,
            ),
            PlayerHandScore(
              playerId: 'ai_0',
              remainingTileCount: 5,
              remainingTileValue: 50,
              wasOpened: false,
              penaltyMultiplier: 1,
              totalPenalty: 50,
              roundScoreDelta: -50,
            ),
          ],
        ),
      );

      await tester.pumpWidget(wrap(sessionState));
      await tester.pump();

      expect(find.text('Test Oyuncu kazandı!'), findsOneWidget);
      expect(find.text('Kazanç: +50'), findsOneWidget);
      expect(find.textContaining('Toplam ceza: 50'), findsOneWidget);
    });

    testWidgets('yeni açılan başarımları listeler', (tester) async {
      await tester.runAsync(() => resetTestStorage());
      final sessionState = GameSessionState(
        gameState: buildTestGameState(players: players),
        lastHandScore: const HandScoreResult(
          handNumber: 1,
          winnerPlayerId: 'human',
          finishType: FinishType.okeyFinish,
          playerScores: [
            PlayerHandScore(
              playerId: 'human',
              remainingTileCount: 0,
              remainingTileValue: 0,
              wasOpened: true,
              penaltyMultiplier: 1,
              finishBonus: 50,
              totalPenalty: 0,
              roundScoreDelta: 50,
            ),
          ],
        ),
        newlyUnlockedAchievements: const [AchievementId.firstWin],
      );

      await tester.pumpWidget(wrap(sessionState));
      await tester.pump();

      expect(find.text('Yeni Başarımlar!'), findsOneWidget);
      expect(
        find.text(
          AchievementCatalog.all
              .firstWhere((a) => a.id == AchievementId.firstWin)
              .title,
        ),
        findsOneWidget,
      );
    });

    testWidgets('berabere biten elde kazanan gösterilmez', (tester) async {
      await tester.runAsync(() => resetTestStorage());
      final sessionState = GameSessionState(
        gameState: buildTestGameState(players: players),
        lastHandScore: const HandScoreResult(
          handNumber: 1,
          finishType: FinishType.normal,
          playerScores: [
            PlayerHandScore(
              playerId: 'human',
              remainingTileCount: 5,
              remainingTileValue: 40,
              wasOpened: false,
              penaltyMultiplier: 1,
              totalPenalty: 40,
              roundScoreDelta: -40,
            ),
          ],
        ),
      );

      await tester.pumpWidget(wrap(sessionState));
      await tester.pump();

      expect(find.text('El sonuçsuz kaldı (berabere)'), findsOneWidget);
    });
  });
}
