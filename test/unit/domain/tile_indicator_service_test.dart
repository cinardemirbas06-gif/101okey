import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/entities/okey_tile.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_factory_service.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_indicator_service.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_shuffler_service.dart';

void main() {
  group('TileIndicatorService.drawIndicator', () {
    test('gösterge olarak asla sahte okey seçilmez', () {
      final random = SeededRandomProvider(7);
      final tiles = TileShufflerService.shuffle(
        TileFactoryService.createFullSet(),
        random,
      );

      final result = TileIndicatorService.drawIndicator(tiles);

      expect(result.indicatorTile.isFalseOkey, isFalse);
      expect(result.indicatorTile.type, TileType.normal);
    });

    test('gösterge çıkarıldıktan sonra 105 taş kalır ve hiçbiri kaybolmaz',
        () {
      final tiles = TileFactoryService.createFullSet();
      final result = TileIndicatorService.drawIndicator(tiles);

      expect(result.remainingTiles.length, tiles.length - 1);
      final remainingIds = result.remainingTiles.map((t) => t.id).toSet();
      expect(remainingIds.contains(result.indicatorTile.id), isFalse);

      final allIdsAfter = {
        result.indicatorTile.id,
        ...remainingIds,
      };
      expect(allIdsAfter.length, tiles.length);
    });

    test('boş desteden gösterge çekilemez', () {
      expect(
        () => TileIndicatorService.drawIndicator(const []),
        throwsArgumentError,
      );
    });
  });

  group('TileIndicatorService.calculateOkey', () {
    test('normal durumda okey, göstergenin bir fazlasıdır', () {
      const indicator = OkeyTile(
        id: 'red_5_1',
        color: TileColor.red,
        number: 5,
        type: TileType.normal,
      );

      final okey = TileIndicatorService.calculateOkey(indicator);

      expect(okey.color, TileColor.red);
      expect(okey.number, 6);
    });

    test('gösterge 13 ise okey aynı renkte 1 olur (13 -> 1 sarması)', () {
      const indicator = OkeyTile(
        id: 'blue_13_1',
        color: TileColor.blue,
        number: 13,
        type: TileType.normal,
      );

      final okey = TileIndicatorService.calculateOkey(indicator);

      expect(okey.color, TileColor.blue);
      expect(okey.number, 1);
    });
  });

  group('TileIndicatorService.applyOkeyDesignation', () {
    test('yalnızca eşleşen 2 normal taşı okey olarak işaretler', () {
      final tiles = TileFactoryService.createFullSet();
      const designation = OkeyDesignation(color: TileColor.yellow, number: 9);

      final marked = TileIndicatorService.applyOkeyDesignation(
        tiles,
        designation,
      );
      final okeyTiles = marked.where((t) => t.isOkey);

      expect(okeyTiles.length, 2);
      expect(
        okeyTiles.every(
          (t) => t.color == TileColor.yellow && t.number == 9,
        ),
        isTrue,
      );
    });

    test('sahte okey taşlarının isOkey alanı değişmez', () {
      final tiles = TileFactoryService.createFullSet();
      const designation = OkeyDesignation(color: TileColor.black, number: 3);

      final marked = TileIndicatorService.applyOkeyDesignation(
        tiles,
        designation,
      );
      final falseOkeys = marked.where((t) => t.isFalseOkey);

      expect(falseOkeys.every((t) => !t.isOkey), isTrue);
      expect(falseOkeys.every((t) => t.actsAsJoker), isTrue);
    });
  });
}
