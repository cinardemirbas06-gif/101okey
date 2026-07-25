import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/entities.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

void main() {
  group('OkeyTile', () {
    test('aynı id\'ye sahip taşlar eşittir, farklı id\'ler eşit değildir',
        () {
      const tileA = OkeyTile(
        id: 'red_5_a',
        color: TileColor.red,
        number: 5,
        type: TileType.normal,
      );
      const tileB = OkeyTile(
        id: 'red_5_a',
        color: TileColor.red,
        number: 5,
        type: TileType.normal,
      );
      const tileC = OkeyTile(
        id: 'red_5_b',
        color: TileColor.red,
        number: 5,
        type: TileType.normal,
      );

      expect(tileA, equals(tileB));
      expect(tileA == tileC, isFalse);
    });

    test('copyWith yalnızca belirtilen alanları değiştirir', () {
      const tile = OkeyTile(
        id: 'blue_9_a',
        color: TileColor.blue,
        number: 9,
        type: TileType.normal,
      );

      final okeyTile = tile.copyWith(type: TileType.okey, isOkey: true);

      expect(okeyTile.id, tile.id);
      expect(okeyTile.color, tile.color);
      expect(okeyTile.number, tile.number);
      expect(okeyTile.isOkey, isTrue);
      expect(okeyTile.type, TileType.okey);
    });

    test('JSON round-trip taşın tüm alanlarını korur', () {
      const tile = OkeyTile(
        id: 'yellow_13_a',
        color: TileColor.yellow,
        number: 13,
        type: TileType.normal,
      );

      final json = tile.toJson();
      final restored = OkeyTile.fromJson(json);

      expect(restored, equals(tile));
    });

    test('falseOkey taşı actsAsJoker olarak işaretlenir', () {
      const falseOkey = OkeyTile(
        id: 'false_okey_1',
        color: TileColor.red,
        number: 1,
        type: TileType.falseOkey,
        isFalseOkey: true,
      );

      expect(falseOkey.actsAsJoker, isTrue);
      expect(falseOkey.isNormal, isFalse);
    });
  });
}
