import '../../../../core/constants/game_constants.dart';
import '../entities/okey_tile.dart';
import '../enums/tile_color.dart';
import '../enums/tile_type.dart';

/// Standart 106 taşlık 101 Okey setini oluşturur.
///
/// Bu servis saf ve deterministiktir: rastgelelik içermez, her çağrıda
/// aynı 106 taşı aynı sırada üretir (karıştırma [TileShufflerService]'in
/// sorumluluğundadır).
abstract final class TileFactoryService {
  const TileFactoryService._();

  /// 4 renk × 1-13 arası sayı × 2 kopya (104 normal taş) + 2 sahte okey
  /// olmak üzere toplam [GameConstants.totalTileCount] taş üretir.
  static List<OkeyTile> createFullSet() {
    final tiles = <OkeyTile>[];

    for (final color in TileColor.values) {
      for (
        var number = GameConstants.tileNumberMin;
        number <= GameConstants.tileNumberMax;
        number++
      ) {
        for (
          var copy = 1;
          copy <= GameConstants.copiesPerNormalTile;
          copy++
        ) {
          tiles.add(
            OkeyTile(
              id: '${color.name}_${number}_$copy',
              color: color,
              number: number,
              type: TileType.normal,
            ),
          );
        }
      }
    }

    for (var copy = 1; copy <= GameConstants.falseOkeyCount; copy++) {
      tiles.add(
        OkeyTile(
          id: 'false_okey_$copy',
          // Sahte okeyin rengi/sayısı anlamsızdır; bkz.
          // GameConstants.falseOkeyPlaceholderNumber dokümantasyonu.
          color: TileColor.red,
          number: GameConstants.falseOkeyPlaceholderNumber,
          type: TileType.falseOkey,
          isFalseOkey: true,
        ),
      );
    }

    assert(
      tiles.length == GameConstants.totalTileCount,
      'Taş seti ${GameConstants.totalTileCount} yerine ${tiles.length} '
      'taş üretti.',
    );
    assert(
      tiles.map((t) => t.id).toSet().length == tiles.length,
      'Üretilen taş kimlikleri benzersiz değil.',
    );

    return List.unmodifiable(tiles);
  }
}
