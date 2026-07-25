import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/rules/meld_validator.dart';
import 'package:okey_101_pro/features/game/domain/rules/opening_score_calculator.dart';

import '../../helpers/test_state.dart';

void main() {
  group('OpeningScoreCalculator', () {
    test('joker taşlar temsil ettikleri değer kadar puan katar', () {
      final runResult = MeldValidator.validateRun([
        normalTile('b10', TileColor.blue, 10),
        okeyJoker('okey1', TileColor.red, 6),
        normalTile('b12', TileColor.blue, 12),
      ]);
      final groupResult = MeldValidator.validateGroup([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m8', TileColor.blue, 8),
      ]);

      final melds = [
        _meldFrom(runResult, 'meld_1'),
        _meldFrom(groupResult, 'meld_2'),
      ];

      final total = OpeningScoreCalculator.calculateMeldsScore(melds);
      expect(total, (10 + 11 + 12) + 24);
    });

    test('eşik altında kalan açılış "yetersiz" olarak işaretlenir', () {
      final groupResult = MeldValidator.validateGroup([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m8', TileColor.blue, 8),
      ]);
      final melds = [_meldFrom(groupResult, 'meld_1')];

      final check = OpeningScoreCalculator.check(
        proposedMelds: melds,
        requiredScore: 101,
      );

      expect(check.isSufficient, isFalse);
      expect(check.missingPoints, 101 - 24);
      expect(check.userMessage, contains('77 puan daha gerekiyor'));
    });

    test('eşiği geçen açılış "yeterli" olarak işaretlenir', () {
      // Tek bir per hiçbir zaman 101'e ulaşamaz (en yüksek grup 4x13=52,
      // en yüksek seri 1..13 toplamı 91'dir); bu yüzden gerçekçi bir
      // açılış her zaman birden fazla per gerektirir.
      final groupResult = MeldValidator.validateGroup([
        normalTile('r13', TileColor.red, 13),
        normalTile('bl13', TileColor.black, 13),
        normalTile('m13', TileColor.blue, 13),
        normalTile('y13_a', TileColor.yellow, 13),
      ]);
      final runResult = MeldValidator.validateRun([
        normalTile('y9', TileColor.yellow, 9),
        normalTile('y10', TileColor.yellow, 10),
        normalTile('y11', TileColor.yellow, 11),
        normalTile('y12', TileColor.yellow, 12),
        normalTile('y13_b', TileColor.yellow, 13),
      ]);

      final melds = [
        _meldFrom(groupResult, 'meld_1'),
        _meldFrom(runResult, 'meld_2'),
      ];

      final check = OpeningScoreCalculator.check(
        proposedMelds: melds,
        requiredScore: 101,
      );

      expect(check.totalScore, (13 * 4) + (9 + 10 + 11 + 12 + 13));
      expect(check.isSufficient, isTrue);
      expect(check.missingPoints, 0);
    });
  });
}

Meld _meldFrom(MeldValidationResult result, String id) {
  return Meld(
    id: id,
    type: result.type!,
    openedByPlayerId: 'p1',
    tiles: result.resolvedTiles!,
  );
}
