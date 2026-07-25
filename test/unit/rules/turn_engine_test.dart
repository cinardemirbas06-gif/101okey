import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/errors/game_exceptions.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_state.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/rules/turn_engine.dart';
import 'package:okey_101_pro/features/game/domain/services/game_setup_service.dart';

import '../../helpers/test_players.dart';

void main() {
  group('TurnEngine tur akışı', () {
    late final random = SeededRandomProvider(123);

    GameState freshGame() => GameSetupService.createNewGame(
      gameId: 'turn_engine_test',
      seed: 123,
      gameMode: GameMode.singleHand,
      rules: GameRulesConfig.standard,
      players: buildTestPlayers(),
      random: SeededRandomProvider(123),
      startingPlayerIndex: 0,
    );

    test('başlayan oyuncu doğrudan taş atabilir (çekmeye gerek yok)', () {
      final state = freshGame();
      final tileToDiscard = state.activePlayer.hand.first;

      final afterDiscard = TurnEngine.discardTile(
        state,
        'p1',
        tileToDiscard.id,
      );

      expect(afterDiscard.discardPile.single.id, tileToDiscard.id);
      expect(afterDiscard.players[0].hand.length, 21);
      expect(afterDiscard.activePlayerIndex, isNot(0));
      expect(afterDiscard.turnNumber, 2);
      expect(afterDiscard.phase, GamePhase.waitingForDraw);
      expect(afterDiscard.hasDrawnThisTurn, isFalse);
    });

    test('sırası olmayan oyuncu taş atamaz', () {
      final state = freshGame();

      expect(
        () => TurnEngine.discardTile(
          state,
          'p2',
          state.players[1].hand.first.id,
        ),
        throwsA(isA<NotPlayersTurnException>()),
      );
    });

    test('ikinci oyuncu önce desteden çekmeden taş atamaz', () {
      final started = freshGame();
      final afterFirstDiscard = TurnEngine.discardTile(
        started,
        'p1',
        started.activePlayer.hand.first.id,
      );
      final secondPlayerId = afterFirstDiscard.activePlayer.id;

      expect(
        () => TurnEngine.discardTile(
          afterFirstDiscard,
          secondPlayerId,
          afterFirstDiscard.activePlayer.hand.first.id,
        ),
        throwsA(isA<InvalidGamePhaseException>()),
      );
    });

    test('kapalı desteden çekme, taş sayısını 22\'ye çıkarır', () {
      final started = freshGame();
      final afterFirstDiscard = TurnEngine.discardTile(
        started,
        'p1',
        started.activePlayer.hand.first.id,
      );
      final secondPlayerId = afterFirstDiscard.activePlayer.id;
      final deckSizeBefore = afterFirstDiscard.drawPile.length;

      final afterDraw = TurnEngine.drawFromDeck(
        afterFirstDiscard,
        secondPlayerId,
        random: random,
      );

      expect(afterDraw.activePlayer.hand.length, 22);
      expect(afterDraw.drawPile.length, deckSizeBefore - 1);
      expect(afterDraw.hasDrawnThisTurn, isTrue);
      expect(afterDraw.phase, GamePhase.waitingForMeld);
    });

    test('ortadaki açık taş alınabilir ve tileTakenFromDiscardId izlenir',
        () {
      final started = freshGame();
      final discardedTile = started.activePlayer.hand.first;
      final afterFirstDiscard = TurnEngine.discardTile(
        started,
        'p1',
        discardedTile.id,
      );
      final secondPlayerId = afterFirstDiscard.activePlayer.id;

      final afterTake = TurnEngine.takeDiscardedTile(
        afterFirstDiscard,
        secondPlayerId,
      );

      expect(afterTake.discardPile, isEmpty);
      expect(afterTake.tileTakenFromDiscardId, discardedTile.id);
      expect(
        afterTake.activePlayer.hand.any((t) => t.id == discardedTile.id),
        isTrue,
      );
    });

    test('elde olmayan taş atılamaz', () {
      final state = freshGame();

      expect(
        () => TurnEngine.discardTile(state, 'p1', 'olmayan_tas_id'),
        throwsA(isA<TileNotInHandException>()),
      );
    });

    test('rearrangeHand yalnızca sırayı değiştirir, taş kümesi aynı kalır',
        () {
      final state = freshGame();
      final originalHand = state.activePlayer.hand;
      final reversedOrder = originalHand.reversed
          .map((t) => t.id)
          .toList(growable: false);

      final rearranged = TurnEngine.rearrangeHand(state, 'p1', reversedOrder);

      expect(
        rearranged.activePlayer.hand.map((t) => t.id).toList(),
        reversedOrder,
      );
      expect(
        rearranged.activePlayer.hand.map((t) => t.id).toSet(),
        originalHand.map((t) => t.id).toSet(),
      );
    });

    test('rearrangeHand farklı bir taş kümesiyle reddedilir', () {
      final state = freshGame();
      final tamperedOrder = [
        ...state.activePlayer.hand.skip(1).map((t) => t.id),
        'gecersiz_tas_id',
      ];

      expect(
        () => TurnEngine.rearrangeHand(state, 'p1', tamperedOrder),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('counterClockwise yönde sıra bir önceki index\'e geçer', () {
      final state = freshGame(); // varsayılan: counterClockwise
      final afterDiscard = TurnEngine.discardTile(
        state,
        'p1',
        state.activePlayer.hand.first.id,
      );

      expect(afterDiscard.activePlayerIndex, 3);
    });

    test('deste tükenince handIsDraw politikası eli sonlandırır', () {
      final state = freshGame();
      final almostEmptyDeck = state.copyWith(drawPile: const []);
      final afterFirstDiscard = TurnEngine.discardTile(
        almostEmptyDeck,
        'p1',
        almostEmptyDeck.activePlayer.hand.first.id,
      );

      final result = TurnEngine.drawFromDeck(
        afterFirstDiscard,
        afterFirstDiscard.activePlayer.id,
        random: random,
      );

      expect(result.phase, GamePhase.finished);
    });

    test('deste tükenince reshuffleDiscardPile politikası desteyi yeniler',
        () {
      final customRules = GameRulesConfig.standard.copyWith(
        deckExhaustionPolicy: DeckExhaustionPolicy.reshuffleDiscardPile,
      );
      var state = GameSetupService.createNewGame(
        gameId: 'reshuffle_test',
        seed: 321,
        gameMode: GameMode.singleHand,
        rules: customRules,
        players: buildTestPlayers(),
        random: SeededRandomProvider(321),
        startingPlayerIndex: 0,
      );

      // Deste ve atılanları yapay olarak, tükenmiş desteyi simüle edecek
      // şekilde ayarla: birkaç taş discard'a, deste boş, oyuncu yeni
      // turun başında (henüz çekmedi).
      final someTiles = state.activePlayer.hand.take(5).toList();
      state = state.copyWith(
        drawPile: const [],
        discardPile: someTiles,
        phase: GamePhase.waitingForDraw,
        hasDrawnThisTurn: false,
      );

      final result = TurnEngine.drawFromDeck(
        state,
        state.activePlayer.id,
        random: random,
      );

      expect(result.drawPile.length, someTiles.length - 1);
      expect(result.discardPile.single.id, someTiles.last.id);
      expect(result.phase, GamePhase.waitingForDraw);
    });
  });
}
