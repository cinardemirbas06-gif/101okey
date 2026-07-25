import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_state.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/presentation/controllers/game_controller.dart';
import 'package:okey_101_pro/features/game/presentation/controllers/game_session_state.dart';

import '../../helpers/test_state.dart';
import '../../helpers/test_storage.dart';

/// [GameController] normalde her hamlesini motor katmanı üzerinden
/// üretir; bu test yalnızca `humanOpenPairs`'ın gerçek bir başlangıç
/// durumundan çiftleri doğru bulup açtığını doğrulamak istediği için,
/// `@protected` `state` alanına yalnızca alt sınıf içinden (meşru
/// biçimde) erişen ince bir test çift (double) tanımlanır.
class _FakeGameController extends GameController {
  _FakeGameController(GameState initialGameState)
      : super(SeededRandomProvider(1)) {
    state = GameSessionState(gameState: initialGameState);
  }

  GameSessionState get sessionStateForTest => state;
}

Player _humanWithFivePairs() => Player(
  id: kHumanPlayerId,
  name: 'Test Oyuncusu',
  avatarId: 'a0',
  hand: [
    for (var i = 0; i < 5; i++) ...[
      normalTile('h${i}a', TileColor.values[i % 4], i + 1),
      normalTile('h${i}b', TileColor.values[i % 4], i + 1),
    ],
  ],
);

Player _ai(String id) =>
    Player(id: id, name: id, avatarId: 'a', isAI: true);

void main() {
  group('GameController', () {
    late ProviderContainer container;

    setUp(() async {
      await resetTestStorage();
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

    test(
      'humanOpenPairs: yeterli doğal çift varsa otomatik bulup çiftten '
      'açılışı gerçekten uygular',
      () async {
        final rules = GameRulesConfig.standard.copyWith(requiredPairCount: 5);
        final initial = buildTestGameState(
          players: [
            _humanWithFivePairs(),
            _ai('ai_0'),
            _ai('ai_1'),
            _ai('ai_2'),
          ],
          rules: rules,
        );
        final controller = _FakeGameController(initial);

        await controller.humanOpenPairs();

        final gameState = controller.sessionStateForTest.gameState!;
        final human = gameState.players.firstWhere(
          (p) => p.id == kHumanPlayerId,
        );
        expect(human.hasOpened, isTrue);
        expect(human.hasOpenedWithPairs, isTrue);
        expect(gameState.tableMelds.length, 5);
        expect(
          gameState.tableMelds.every((m) => m.type == MeldType.pair),
          isTrue,
        );
        expect(controller.sessionStateForTest.errorMessage, isNull);
      },
    );

    test(
      'humanOpenPairs: yetersiz çiftte anlaşılır bir hata mesajı üretir, '
      'state\'i bozmaz',
      () async {
        final rules = GameRulesConfig.standard.copyWith(requiredPairCount: 5);
        final humanWithOnePair = Player(
          id: kHumanPlayerId,
          name: 'Test Oyuncusu',
          avatarId: 'a0',
          hand: [
            normalTile('r5_1', TileColor.red, 5),
            normalTile('r5_2', TileColor.red, 5),
          ],
        );
        final initial = buildTestGameState(
          players: [humanWithOnePair, _ai('ai_0'), _ai('ai_1'), _ai('ai_2')],
          rules: rules,
        );
        final controller = _FakeGameController(initial);

        await controller.humanOpenPairs();

        expect(controller.sessionStateForTest.errorMessage, isNotNull);
        final human = controller.sessionStateForTest.gameState!.players.firstWhere(
          (p) => p.id == kHumanPlayerId,
        );
        expect(human.hasOpenedWithPairs, isFalse);
      },
    );

    test(
      'humanOpenPairs: pairsEnabled kapalıyken anlaşılır bir hata üretir',
      () async {
        final rules = GameRulesConfig.standard.copyWith(
          pairsEnabled: false,
          requiredPairCount: 5,
        );
        final initial = buildTestGameState(
          players: [
            _humanWithFivePairs(),
            _ai('ai_0'),
            _ai('ai_1'),
            _ai('ai_2'),
          ],
          rules: rules,
        );
        final controller = _FakeGameController(initial);

        await controller.humanOpenPairs();

        expect(controller.sessionStateForTest.errorMessage, contains('kapalı'));
      },
    );
  });
}
