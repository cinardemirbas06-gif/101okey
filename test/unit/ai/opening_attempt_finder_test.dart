import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/ai/opening_attempt_finder.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

import '../../helpers/test_state.dart';

void main() {
  group('OpeningAttemptFinder.findOpeningMelds', () {
    test('eşiğe ulaşan bir kombinasyon bulunca per gruplarını döndürür', () {
      final hand = [
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
      ];

      final result = OpeningAttemptFinder.findOpeningMelds(
        hand,
        GameRulesConfig.standard,
        combinationBudget: 1000,
      );

      expect(result, isNotNull);
      final totalPoints = result!
          .expand((g) => g)
          .fold<int>(0, (sum, t) => sum + t.number);
      expect(totalPoints, greaterThanOrEqualTo(101));

      // Aynı fiziksel taş iki farklı grupta kullanılmamalı.
      final allIds = result.expand((g) => g).map((t) => t.id).toList();
      expect(allIds.toSet().length, allIds.length);
    });

    test('eşiğe ulaşacak kombinasyon yoksa null döner', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r6', TileColor.red, 6),
        normalTile('r7', TileColor.red, 7),
        normalTile('y1', TileColor.yellow, 1),
      ];

      final result = OpeningAttemptFinder.findOpeningMelds(
        hand,
        GameRulesConfig.standard,
        combinationBudget: 1000,
      );

      expect(result, isNull);
    });

    test('düşük eşikli özel kuralda daha kolay açılış bulunur', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r6', TileColor.red, 6),
        normalTile('r7', TileColor.red, 7),
      ];
      final rules = GameRulesConfig.standard.copyWith(openingThreshold: 10);

      final result = OpeningAttemptFinder.findOpeningMelds(
        hand,
        rules,
        combinationBudget: 1000,
      );

      expect(result, isNotNull);
    });
  });
}
