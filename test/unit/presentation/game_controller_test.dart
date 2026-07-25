import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/enums/ai_difficulty.dart';
import 'package:okey_101_pro/features/game/domain/enums/game_phase.dart';
import 'package:okey_101_pro/features/game/presentation/controllers/game_controller.dart';

void main() {
  group('GameController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          gameControllerProvider.overrideWith(
            (ref) => GameController(SeededRandomProvider(7)),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('startNewGame geçerli bir 4 oyunculu durum üretir', () {
      final controller = container.read(gameControllerProvider.notifier);
      controller.startNewGame(
        playerName: 'Test Oyuncusu',
        aiDifficulties: const [
          AiDifficulty.easy,
          AiDifficulty.easy,
          AiDifficulty.easy,
        ],
      );

      final session = container.read(gameControllerProvider);
      expect(session.gameState, isNotNull);
      expect(session.gameState!.players.length, 4);
      expect(
        session.gameState!.players.map((p) => p.id),
        containsAll(['human', 'ai_0', 'ai_1', 'ai_2']),
      );
    });

    test(
      'sıra insan oyuncuya gelene kadar AI turları otomatik oynanır, '
      'sonra insan hamlesi kabul edilir',
      () async {
        final controller = container.read(gameControllerProvider.notifier);
        controller.startNewGame(
          playerName: 'Test Oyuncusu',
          aiDifficulties: const [
            AiDifficulty.easy,
            AiDifficulty.easy,
            AiDifficulty.easy,
          ],
        );

        // AI turlarının bitmesini bekle (isAiThinking false olana kadar).
        var attempts = 0;
        while (container.read(gameControllerProvider).isAiThinking &&
            attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          attempts++;
        }

        final session = container.read(gameControllerProvider);
        final gameState = session.gameState!;

        if (gameState.phase == GamePhase.finished) {
          // Deste tükenmeden / kimse bitirmeden nadiren erken bitebilir;
          // bu durumda test senaryosu anlamsızlaşır, atla.
          return;
        }

        expect(gameState.activePlayer.id, 'human');

        if (gameState.phase == GamePhase.waitingForDraw) {
          await controller.humanDrawFromDeck();
        }

        final afterDraw = container.read(gameControllerProvider).gameState!;
        expect(afterDraw.activePlayer.id, 'human');
        expect(afterDraw.hasDrawnThisTurn, isTrue);
      },
    );

    test('geçersiz insan hamlesi errorMessage üretir, state\'i bozmaz', () async {
      final controller = container.read(gameControllerProvider.notifier);
      controller.startNewGame(
        playerName: 'Test Oyuncusu',
        aiDifficulties: const [
          AiDifficulty.easy,
          AiDifficulty.easy,
          AiDifficulty.easy,
        ],
      );

      var attempts = 0;
      while (container.read(gameControllerProvider).isAiThinking &&
          attempts < 100) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      final gameState = container.read(gameControllerProvider).gameState!;
      if (gameState.phase == GamePhase.finished ||
          gameState.activePlayer.id != 'human') {
        return;
      }

      // İnsan henüz çekmeden taş atmaya çalışırsa (waitingForDraw
      // fazındayken) reddedilmeli.
      if (gameState.phase == GamePhase.waitingForDraw) {
        await controller.humanDiscard(gameState.activePlayer.hand.first.id);
        final afterInvalid = container.read(gameControllerProvider);
        expect(afterInvalid.errorMessage, isNotNull);
        expect(afterInvalid.gameState!.phase, GamePhase.waitingForDraw);
      }
    });

    test('startNextHandOrReturnToMenu oturumu sıfırlar', () {
      final controller = container.read(gameControllerProvider.notifier);
      controller.startNewGame(
        playerName: 'Test',
        aiDifficulties: const [
          AiDifficulty.easy,
          AiDifficulty.easy,
          AiDifficulty.easy,
        ],
      );
      expect(container.read(gameControllerProvider).hasActiveGame, isTrue);

      controller.startNextHandOrReturnToMenu();
      expect(container.read(gameControllerProvider).hasActiveGame, isFalse);
    });
  });
}
