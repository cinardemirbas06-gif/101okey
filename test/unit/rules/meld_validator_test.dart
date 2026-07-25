import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/rules/meld_validator.dart';

import '../../helpers/test_state.dart';

void main() {
  group('MeldValidator.validateRun', () {
    test('geçerli bir seriyi kabul eder', () {
      final result = MeldValidator.validateRun([
        normalTile('r3', TileColor.red, 3),
        normalTile('r4', TileColor.red, 4),
        normalTile('r5', TileColor.red, 5),
      ]);

      expect(result.isValid, isTrue);
      expect(result.type, MeldType.run);
      expect(result.points, 12);
    });

    test('okeyli seri, jokerin temsil ettiği değeri doğru çözer', () {
      final result = MeldValidator.validateRun([
        normalTile('b10', TileColor.blue, 10),
        okeyJoker('okey1', TileColor.red, 6), // gösterge->okey: kırmızı 6
        normalTile('b12', TileColor.blue, 12),
      ]);

      expect(result.isValid, isTrue);
      final jokerSlot = result.resolvedTiles![1];
      expect(jokerSlot.representedColor, TileColor.blue);
      expect(jokerSlot.representedNumber, 11);
      expect(result.points, 10 + 11 + 12);
    });

    test('farklı renkler seri olarak reddedilir', () {
      final result = MeldValidator.validateRun([
        normalTile('r3', TileColor.red, 3),
        normalTile('b4', TileColor.blue, 4),
        normalTile('r5', TileColor.red, 5),
      ]);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('aynı renkte'));
    });

    test('ardışık olmayan taşlar seri olarak reddedilir', () {
      final result = MeldValidator.validateRun([
        normalTile('r3', TileColor.red, 3),
        normalTile('r4', TileColor.red, 4),
        normalTile('r9', TileColor.red, 9),
      ]);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('devamı değil'));
    });

    test('varsayılan olarak 13\'ten sonra 1\'e sarma kapalıdır', () {
      final result = MeldValidator.validateRun([
        normalTile('r12', TileColor.red, 12),
        normalTile('r13', TileColor.red, 13),
        normalTile('r1', TileColor.red, 1),
      ]);

      expect(result.isValid, isFalse);
    });

    test('wrapAroundRunsEnabled açıkken 12-13-1 serisi geçerlidir', () {
      final result = MeldValidator.validateRun(
        [
          normalTile('r12', TileColor.red, 12),
          normalTile('r13', TileColor.red, 13),
          normalTile('r1', TileColor.red, 1),
        ],
        wrapAroundRunsEnabled: true,
      );

      expect(result.isValid, isTrue);
      expect(result.points, 12 + 13 + 1);
    });

    test('2 taşlık seri reddedilir (minimum 3 taş)', () {
      final result = MeldValidator.validateRun([
        normalTile('r3', TileColor.red, 3),
        normalTile('r4', TileColor.red, 4),
      ]);

      expect(result.isValid, isFalse);
    });

    test('yalnızca joker içeren seri reddedilir (çıpa taş gerekir)', () {
      final result = MeldValidator.validateRun([
        okeyJoker('o1', TileColor.red, 6),
        falseOkeyJoker('fo1'),
        okeyJoker('o2', TileColor.red, 6),
      ]);

      expect(result.isValid, isFalse);
    });
  });

  group('MeldValidator.validateGroup', () {
    test('geçerli bir grubu kabul eder', () {
      final result = MeldValidator.validateGroup([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m8', TileColor.blue, 8),
      ]);

      expect(result.isValid, isTrue);
      expect(result.type, MeldType.group);
      expect(result.points, 24);
    });

    test('okeyli grup, eksik rengi doğru tamamlar', () {
      final result = MeldValidator.validateGroup([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        okeyJoker('okey1', TileColor.red, 6),
      ]);

      expect(result.isValid, isTrue);
      final jokerSlot = result.resolvedTiles!.last;
      expect(jokerSlot.representedNumber, 8);
      expect(
        {TileColor.blue, TileColor.yellow}.contains(jokerSlot.representedColor),
        isTrue,
      );
    });

    test('farklı sayılar grup olarak reddedilir', () {
      final result = MeldValidator.validateGroup([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m9', TileColor.blue, 9),
      ]);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('aynı sayıda'));
    });

    test('aynı renk grupta iki kez kullanılamaz', () {
      final result = MeldValidator.validateGroup([
        normalTile('r8_1', TileColor.red, 8),
        normalTile('r8_2', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
      ]);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('iki kez kullanılamaz'));
    });

    test('5 taşlık grup reddedilir (en fazla 4 renk)', () {
      final result = MeldValidator.validateGroup([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m8', TileColor.blue, 8),
        normalTile('y8', TileColor.yellow, 8),
        okeyJoker('okey1', TileColor.red, 6),
      ]);

      expect(result.isValid, isFalse);
    });
  });

  group('MeldValidator.validate (otomatik tür tespiti)', () {
    test('per en az 3 taş kuralını her iki tür için de uygular', () {
      final result = MeldValidator.validate([
        normalTile('r3', TileColor.red, 3),
        normalTile('r4', TileColor.red, 4),
      ]);

      expect(result.isValid, isFalse);
      expect(result.reason, contains('en az 3 taş'));
    });

    test('geçerli bir grubu doğru tanır', () {
      final result = MeldValidator.validate([
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m8', TileColor.blue, 8),
      ]);

      expect(result.isValid, isTrue);
      expect(result.type, MeldType.group);
    });
  });
}
