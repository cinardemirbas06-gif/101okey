import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/constants/game_constants.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_factory_service.dart';

void main() {
  group('TileFactoryService.createFullSet', () {
    test('toplam 106 taş üretir', () {
      final tiles = TileFactoryService.createFullSet();
      expect(tiles.length, 106);
      expect(tiles.length, GameConstants.totalTileCount);
    });

    test('her normal taştan (renk+sayı) tam olarak 2 kopya bulunur', () {
      final tiles = TileFactoryService.createFullSet();
      final normalTiles = tiles.where((t) => t.type == TileType.normal);

      for (final color in TileColor.values) {
        for (var number = 1; number <= 13; number++) {
          final matching = normalTiles.where(
            (t) => t.color == color && t.number == number,
          );
          expect(
            matching.length,
            2,
            reason: '${color.label} $number taşından 2 kopya olmalı',
          );
        }
      }
    });

    test('tam olarak 2 sahte okey taşı içerir', () {
      final tiles = TileFactoryService.createFullSet();
      final falseOkeys = tiles.where((t) => t.isFalseOkey);

      expect(falseOkeys.length, 2);
      expect(falseOkeys.every((t) => t.type == TileType.falseOkey), isTrue);
      expect(falseOkeys.every((t) => t.actsAsJoker), isTrue);
    });

    test('tüm taş kimlikleri benzersizdir', () {
      final tiles = TileFactoryService.createFullSet();
      final ids = tiles.map((t) => t.id).toSet();

      expect(ids.length, tiles.length);
    });

    test('üretilen liste değiştirilemez (unmodifiable)', () {
      final tiles = TileFactoryService.createFullSet();
      expect(() => tiles.add(tiles.first), throwsUnsupportedError);
    });
  });
}
