import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/errors/game_exceptions.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/rules/finish_engine.dart';

import '../../helpers/test_state.dart';

Player _player(
  String id, {
  List<dynamic> hand = const [],
  bool hasOpened = false,
  bool hasOpenedWithPairs = false,
}) {
  return Player(
    id: id,
    name: id,
    avatarId: 'avatar',
    hand: hand.cast(),
    hasOpened: hasOpened,
    hasOpenedWithPairs: hasOpenedWithPairs,
  );
}

void main() {
  group('FinishEngine.finishHand (normal/okey/gösterge bitişi)', () {
    test('açılmış oyuncu kalan taşları perleyip son taşı atarak biter', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          normalTile('y1', TileColor.yellow, 1),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      final result = FinishEngine.finishHand(state, 'p1', FinishType.normal, [
        ['r10', 'r11', 'r12'],
      ]);

      expect(result.phase, GamePhase.calculatingScore);
      expect(result.winnerPlayerId, 'p1');
      expect(result.finishType, FinishType.normal);
      expect(result.discardPile.single.id, 'y1');
      expect(
        result.players.firstWhere((p) => p.id == 'p1').hand,
        isEmpty,
      );
      expect(result.tableMelds.single.tileCount, 3);
    });

    test('okeyle bitirmede son atılan taş okey olmalı', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          normalTile('y1', TileColor.yellow, 1),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.okeyFinish, [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<InvalidFinishException>()),
      );
    });

    test('okey atılarak bitirme kabul edilir', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          okeyJoker('okey1', TileColor.blue, 5),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      final result = FinishEngine.finishHand(
        state,
        'p1',
        FinishType.okeyFinish,
        [
          ['r10', 'r11', 'r12'],
        ],
      );

      expect(result.winnerPlayerId, 'p1');
      expect(result.finishType, FinishType.okeyFinish);
      expect(result.discardPile.single.id, 'okey1');
    });

    test('gruplanan taşlar dışında birden fazla taş kalırsa reddedilir', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          normalTile('y1', TileColor.yellow, 1),
          normalTile('y2', TileColor.yellow, 2),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.normal, [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<InvalidFinishException>()),
      );
    });

    test('henüz açılmamış oyuncu, aynı turda açıp bitirme kapalıysa '
        'bitiremiyor', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          normalTile('y1', TileColor.yellow, 1),
        ],
      );
      final rules = GameRulesConfig.standard.copyWith(
        allowOpenAndFinishSameTurn: false,
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        rules: rules,
      );

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.normal, [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<PlayerNotOpenedException>()),
      );
    });

    test('devre dışı bırakılan bitiş türü reddedilir', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          okeyJoker('okey1', TileColor.blue, 5),
        ],
      );
      final rules = GameRulesConfig.standard.copyWith(
        okeyFinishEnabled: false,
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        rules: rules,
      );

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.okeyFinish, [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<InvalidFinishException>()),
      );
    });
  });

  group('FinishEngine.finishHand (çiftten bitiş)', () {
    test('çiftten açılmış oyuncu tüm çiftleri tamamlayıp bitirebilir', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hasOpenedWithPairs: true,
        hand: [
          normalTile('r5_1', TileColor.red, 5),
          normalTile('r5_2', TileColor.red, 5),
          normalTile('y2', TileColor.yellow, 2),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      final result = FinishEngine.finishHand(
        state,
        'p1',
        FinishType.pairFinish,
        [
          ['r5_1', 'r5_2'],
        ],
      );

      expect(result.winnerPlayerId, 'p1');
      expect(result.finishType, FinishType.pairFinish);
      expect(result.tableMelds.single.type, MeldType.pair);
    });

    test('daha önce çiftten açılmamış oyuncu çiftten bitiremez', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r5_1', TileColor.red, 5),
          normalTile('r5_2', TileColor.red, 5),
          normalTile('y2', TileColor.yellow, 2),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.pairFinish, [
          ['r5_1', 'r5_2'],
        ]),
        throwsA(isA<InvalidFinishException>()),
      );
    });
  });

  group('FinishEngine.finishHand (elden bitiş)', () {
    test('hiç açılmamış oyuncu tüm eliyle elden bitirebilir', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          normalTile('b8', TileColor.blue, 8),
          normalTile('bl8', TileColor.black, 8),
          normalTile('y8', TileColor.yellow, 8),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      final result = FinishEngine.finishHand(state, 'p1', FinishType.handFinish, [
        ['r10', 'r11', 'r12'],
        ['b8', 'bl8', 'y8'],
      ]);

      expect(result.winnerPlayerId, 'p1');
      expect(result.finishType, FinishType.handFinish);
      expect(result.players.firstWhere((p) => p.id == 'p1').hand, isEmpty);
      expect(result.discardPile, isEmpty);
      expect(result.tableMelds.length, 2);
    });

    test('daha önce açılmış oyuncu elden bitiremez', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.handFinish, [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<InvalidFinishException>()),
      );
    });

    test('elin tamamını kapsamayan grup elden bitirmeyi reddeder', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
          normalTile('y1', TileColor.yellow, 1),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => FinishEngine.finishHand(state, 'p1', FinishType.handFinish, [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<InvalidFinishException>()),
      );
    });
  });
}
