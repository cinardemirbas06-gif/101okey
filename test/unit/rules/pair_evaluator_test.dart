import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/rules/pair_evaluator.dart';

import '../../helpers/test_state.dart';

void main() {
  group('PairEvaluator.evaluate', () {
    test('doğal çiftleri doğru sayar', () {
      final hand = [
        normalTile('r5_1', TileColor.red, 5),
        normalTile('r5_2', TileColor.red, 5),
        normalTile('b9_1', TileColor.blue, 9),
        normalTile('b9_2', TileColor.blue, 9),
        normalTile('y2', TileColor.yellow, 2),
      ];

      final result = PairEvaluator.evaluate(
        hand,
        jokerPolicy: PairJokerPolicy.unlimited,
      );

      expect(result.pairCount, 2);
      expect(result.unpairedTiles.map((t) => t.id), ['y2']);
    });

    test('naturalOnly politikasında joker hiç kullanılmaz', () {
      final hand = [
        normalTile('r5_1', TileColor.red, 5),
        okeyJoker('okey1', TileColor.blue, 9),
      ];

      final result = PairEvaluator.evaluate(
        hand,
        jokerPolicy: PairJokerPolicy.naturalOnly,
      );

      expect(result.pairCount, 0);
      expect(result.unpairedTiles.length, 2);
    });

    test('maxOne politikası en fazla 1 joker çiftine izin verir', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('b9', TileColor.blue, 9),
        okeyJoker('okey1', TileColor.black, 3),
        falseOkeyJoker('fo1'),
      ];

      final result = PairEvaluator.evaluate(
        hand,
        jokerPolicy: PairJokerPolicy.maxOne,
      );

      expect(result.pairCount, 1);
      expect(result.unpairedTiles.length, 2);
    });

    test('unlimited politikasında her tek taş bir jokerle eşleşebilir', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('b9', TileColor.blue, 9),
        okeyJoker('okey1', TileColor.black, 3),
        falseOkeyJoker('fo1'),
      ];

      final result = PairEvaluator.evaluate(
        hand,
        jokerPolicy: PairJokerPolicy.unlimited,
      );

      expect(result.pairCount, 2);
      expect(result.unpairedTiles, isEmpty);
    });
  });
}
