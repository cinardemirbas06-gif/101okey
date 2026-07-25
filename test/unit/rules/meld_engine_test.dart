import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/errors/game_exceptions.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld_tile.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/rules/meld_engine.dart';

import '../../helpers/test_state.dart';

Player _player(
  String id, {
  List<dynamic> hand = const [],
  bool hasOpened = false,
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
  group('MeldEngine.openMelds (seri/grup ile açılış)', () {
    test('101 ve üzeri toplamla açılış kabul edilir, taşlar masaya geçer', () {
      // Tek bir per 101'e ulaşamayacağından (en yüksek grup 52, en
      // yüksek seri 91 puandır) açılış iki per ile kurgulanır: 13'ler
      // grubu (52) + sarı 9-13 serisi (55) = 107 puan.
      final active = _player(
        'p1',
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
      final state = buildTestGameState(players: [active, _player('p2')]);

      final result = MeldEngine.openMelds(state, 'p1', [
        ['r13', 'bl13', 'm13', 'y13_a'],
        ['y9', 'y10', 'y11', 'y12', 'y13_b'],
      ]);

      final updatedActive = result.players.firstWhere((p) => p.id == 'p1');
      expect(updatedActive.hasOpened, isTrue);
      expect(updatedActive.hand.map((t) => t.id), ['bl2']);
      expect(result.tableMelds.length, 2);
      expect(
        result.tableMelds.map((m) => m.type),
        containsAll(<MeldType>[MeldType.run, MeldType.group]),
      );
    });

    test('eşiğin altında kalan açılış reddedilir', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r8', TileColor.red, 8),
          normalTile('bl8', TileColor.black, 8),
          normalTile('m8', TileColor.blue, 8),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => MeldEngine.openMelds(state, 'p1', [
          ['r8', 'bl8', 'm8'],
        ]),
        throwsA(isA<InsufficientOpeningScoreException>()),
      );
    });

    test('geçersiz per yapısı InvalidMeldException fırlatır', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r8', TileColor.red, 8),
          normalTile('bl9', TileColor.black, 9),
          normalTile('m10', TileColor.blue, 10),
        ],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => MeldEngine.openMelds(state, 'p1', [
          ['r8', 'bl9', 'm10'],
        ]),
        throwsA(isA<InvalidMeldException>()),
      );
    });

    test('elde olmayan taş ile açılış denemesi reddedilir', () {
      final active = _player('p1', hand: [normalTile('r8', TileColor.red, 8)]);
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => MeldEngine.openMelds(state, 'p1', [
          ['r8', 'olmayan_id', 'baska_id'],
        ]),
        throwsA(isA<TileNotInHandException>()),
      );
    });

    test('zaten açılmış oyuncu OpenMelds ile tekrar açamaz', () {
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
        () => MeldEngine.openMelds(state, 'p1', [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('sırası olmayan oyuncu açılış yapamaz', () {
      final active = _player('p1');
      final other = _player(
        'p2',
        hand: [
          normalTile('r10', TileColor.red, 10),
          normalTile('r11', TileColor.red, 11),
          normalTile('r12', TileColor.red, 12),
        ],
      );
      final state = buildTestGameState(players: [active, other]);

      expect(
        () => MeldEngine.openMelds(state, 'p2', [
          ['r10', 'r11', 'r12'],
        ]),
        throwsA(isA<NotPlayersTurnException>()),
      );
    });
  });

  group('MeldEngine.openMelds (çiftten açılış)', () {
    test('yeterli doğal çiftle çiftten açılış kabul edilir', () {
      final pairHand = <dynamic>[];
      final groups = <List<String>>[];
      for (var i = 0; i < 5; i++) {
        final idA = 'p${i}_a';
        final idB = 'p${i}_b';
        pairHand
          ..add(normalTile(idA, TileColor.values[i % 4], i + 1))
          ..add(normalTile(idB, TileColor.values[i % 4], i + 1));
        groups.add([idA, idB]);
      }

      final rules = GameRulesConfig.standard.copyWith(requiredPairCount: 5);
      final active = _player('p1', hand: pairHand);
      final state = buildTestGameState(
        players: [active, _player('p2')],
        rules: rules,
      );

      final result = MeldEngine.openMelds(state, 'p1', groups);

      final updatedActive = result.players.firstWhere((p) => p.id == 'p1');
      expect(updatedActive.hasOpened, isTrue);
      expect(updatedActive.hasOpenedWithPairs, isTrue);
      expect(result.tableMelds.length, 5);
      expect(result.tableMelds.every((m) => m.type == MeldType.pair), isTrue);
    });

    test('gerekli çift sayısına ulaşılamazsa reddedilir', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r5_1', TileColor.red, 5),
          normalTile('r5_2', TileColor.red, 5),
        ],
      );
      final rules = GameRulesConfig.standard.copyWith(requiredPairCount: 5);
      final state = buildTestGameState(
        players: [active, _player('p2')],
        rules: rules,
      );

      expect(
        () => MeldEngine.openMelds(state, 'p1', [
          ['r5_1', 'r5_2'],
        ]),
        throwsA(isA<InsufficientPairCountException>()),
      );
    });

    test('eşleşmeyen çift (farklı renk/sayı) reddedilir', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r5', TileColor.red, 5),
          normalTile('b6', TileColor.blue, 6),
        ],
      );
      final rules = GameRulesConfig.standard.copyWith(requiredPairCount: 1);
      final state = buildTestGameState(
        players: [active, _player('p2')],
        rules: rules,
      );

      expect(
        () => MeldEngine.openMelds(state, 'p1', [
          ['r5', 'b6'],
        ]),
        throwsA(isA<InvalidMeldException>()),
      );
    });

    test('naturalOnly politikasında jokerli çift reddedilir', () {
      final active = _player(
        'p1',
        hand: [
          normalTile('r5', TileColor.red, 5),
          okeyJoker('okey1', TileColor.blue, 9),
        ],
      );
      final rules = GameRulesConfig.standard.copyWith(
        requiredPairCount: 1,
        pairJokerPolicy: PairJokerPolicy.naturalOnly,
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        rules: rules,
      );

      expect(
        () => MeldEngine.openMelds(state, 'p1', [
          ['r5', 'okey1'],
        ]),
        throwsA(isA<InvalidMeldException>()),
      );
    });
  });

  group('MeldEngine.addTileToMeld', () {
    test('açılmış oyuncu masadaki seriye taş ekleyebilir', () {
      final existingMeld = Meld(
        id: 'meld_1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r10', TileColor.red, 10)),
          MeldTile(tile: normalTile('r11', TileColor.red, 11)),
          MeldTile(tile: normalTile('r12', TileColor.red, 12)),
        ],
      );
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [normalTile('r13', TileColor.red, 13)],
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        tableMelds: [existingMeld],
      );

      final result = MeldEngine.addTileToMeld(
        state,
        'p1',
        'r13',
        'meld_1',
        3,
      );

      final updatedMeld = result.tableMelds.single;
      expect(updatedMeld.tileCount, 4);
      expect(updatedMeld.tiles.last.tile.id, 'r13');
      expect(
        result.players.firstWhere((p) => p.id == 'p1').hand,
        isEmpty,
      );
    });

    test('henüz açılmamış oyuncu masaya taş işleyemez', () {
      final existingMeld = Meld(
        id: 'meld_1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r10', TileColor.red, 10)),
          MeldTile(tile: normalTile('r11', TileColor.red, 11)),
          MeldTile(tile: normalTile('r12', TileColor.red, 12)),
        ],
      );
      final active = _player(
        'p1',
        hand: [normalTile('r13', TileColor.red, 13)],
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        tableMelds: [existingMeld],
      );

      expect(
        () => MeldEngine.addTileToMeld(state, 'p1', 'r13', 'meld_1', 3),
        throwsA(isA<PlayerNotOpenedException>()),
      );
    });

    test('serinin devamı olmayan taş eklenemez', () {
      final existingMeld = Meld(
        id: 'meld_1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r10', TileColor.red, 10)),
          MeldTile(tile: normalTile('r11', TileColor.red, 11)),
          MeldTile(tile: normalTile('r12', TileColor.red, 12)),
        ],
      );
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [normalTile('r7', TileColor.red, 7)],
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        tableMelds: [existingMeld],
      );

      expect(
        () => MeldEngine.addTileToMeld(state, 'p1', 'r7', 'meld_1', 3),
        throwsA(isA<InvalidMeldException>()),
      );
    });

    test('olmayan per kimliğiyle işleme denemesi reddedilir', () {
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [normalTile('r13', TileColor.red, 13)],
      );
      final state = buildTestGameState(players: [active, _player('p2')]);

      expect(
        () => MeldEngine.addTileToMeld(state, 'p1', 'r13', 'yok', 0),
        throwsA(isA<InvalidActionException>()),
      );
    });
  });

  group('MeldEngine.swapTileWithTableOkey', () {
    test('gerçek taş, masadaki okeyle takas edilebilir', () {
      final okeyOnTable = okeyJoker('okey_table', TileColor.blue, 11);
      final existingMeld = Meld(
        id: 'meld_1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r10', TileColor.blue, 10)),
          MeldTile(
            tile: okeyOnTable,
            representedColor: TileColor.blue,
            representedNumber: 11,
          ),
          MeldTile(tile: normalTile('r12', TileColor.blue, 12)),
        ],
      );
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [normalTile('b11_real', TileColor.blue, 11)],
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        tableMelds: [existingMeld],
      );

      final result = MeldEngine.swapTileWithTableOkey(
        state,
        'p1',
        'b11_real',
        'meld_1',
        1,
      );

      final updatedMeld = result.tableMelds.single;
      expect(updatedMeld.tiles[1].tile.id, 'b11_real');
      expect(updatedMeld.tiles[1].isJokerSubstitute, isFalse);

      final updatedHand = result.players
          .firstWhere((p) => p.id == 'p1')
          .hand;
      expect(updatedHand.single.id, 'okey_table');
    });

    test('eşleşmeyen gerçek taşla takas reddedilir', () {
      final okeyOnTable = okeyJoker('okey_table', TileColor.blue, 11);
      final existingMeld = Meld(
        id: 'meld_1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r10', TileColor.blue, 10)),
          MeldTile(
            tile: okeyOnTable,
            representedColor: TileColor.blue,
            representedNumber: 11,
          ),
          MeldTile(tile: normalTile('r12', TileColor.blue, 12)),
        ],
      );
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [normalTile('y5', TileColor.yellow, 5)],
      );
      final state = buildTestGameState(
        players: [active, _player('p2')],
        tableMelds: [existingMeld],
      );

      expect(
        () => MeldEngine.swapTileWithTableOkey(
          state,
          'p1',
          'y5',
          'meld_1',
          1,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('jokerSwapEnabled kapalıyken takas reddedilir', () {
      final okeyOnTable = okeyJoker('okey_table', TileColor.blue, 11);
      final existingMeld = Meld(
        id: 'meld_1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r10', TileColor.blue, 10)),
          MeldTile(
            tile: okeyOnTable,
            representedColor: TileColor.blue,
            representedNumber: 11,
          ),
          MeldTile(tile: normalTile('r12', TileColor.blue, 12)),
        ],
      );
      final active = _player(
        'p1',
        hasOpened: true,
        hand: [normalTile('b11_real', TileColor.blue, 11)],
      );
      final rules = GameRulesConfig.standard.copyWith(jokerSwapEnabled: false);
      final state = buildTestGameState(
        players: [active, _player('p2')],
        tableMelds: [existingMeld],
        rules: rules,
      );

      expect(
        () => MeldEngine.swapTileWithTableOkey(
          state,
          'p1',
          'b11_real',
          'meld_1',
          1,
        ),
        throwsA(isA<InvalidActionException>()),
      );
    });
  });
}
