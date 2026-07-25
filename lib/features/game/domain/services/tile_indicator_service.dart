import '../../../../core/constants/game_constants.dart';
import '../entities/okey_tile.dart';
import '../enums/tile_color.dart';
import '../enums/tile_type.dart';

/// [TileIndicatorService.drawIndicator] sonucu: seçilen gösterge taşı ve
/// gösterge çıkarıldıktan sonra oyuna devam edecek geri kalan taşlar.
final class IndicatorDrawResult {
  const IndicatorDrawResult({
    required this.indicatorTile,
    required this.remainingTiles,
  });

  final OkeyTile indicatorTile;
  final List<OkeyTile> remainingTiles;
}

/// Bir elde geçerli olan okeyin renk/sayı tanımı.
final class OkeyDesignation {
  const OkeyDesignation({required this.color, required this.number});

  final TileColor color;
  final int number;

  @override
  String toString() => '${color.label} $number';
}

/// Gösterge taşının belirlenmesi ve buna göre okeyin hesaplanması.
///
/// Bu iki adım bilinçli olarak ayrı fonksiyonlarda tutulur (bkz. proje
/// gereksinimleri #4) ve her biri bağımsız olarak unit test edilir.
abstract final class TileIndicatorService {
  const TileIndicatorService._();

  /// Karıştırılmış desteden göstergeyi çeker.
  ///
  /// Sahte okey taşlarının basılı bir sayısı olmadığı için gösterge
  /// olamazlar: destenin sonundan başlanarak ilk NORMAL taş gösterge
  /// olarak seçilir; aradan atlanan sahte okey taşları (varsa) desteye
  /// geri konur.
  static IndicatorDrawResult drawIndicator(List<OkeyTile> shuffledDeck) {
    if (shuffledDeck.isEmpty) {
      throw ArgumentError('Boş desteden gösterge çekilemez.');
    }

    final remaining = List<OkeyTile>.of(shuffledDeck);
    for (var i = remaining.length - 1; i >= 0; i--) {
      final candidate = remaining[i];
      if (!candidate.isFalseOkey) {
        remaining.removeAt(i);
        return IndicatorDrawResult(
          indicatorTile: candidate,
          remainingTiles: remaining,
        );
      }
    }

    throw StateError(
      'Destede sahte okey dışında gösterge olabilecek taş bulunamadı.',
    );
  }

  /// Gösterge taşına göre okeyin renk/sayısını hesaplar.
  ///
  /// Okey, göstergeyle aynı renkte ve bir fazla sayıdadır; 13'ten sonra
  /// 1'e sarar (13 → 1).
  static OkeyDesignation calculateOkey(OkeyTile indicatorTile) {
    final wrappedNumber = indicatorTile.number == GameConstants.tileNumberMax
        ? GameConstants.tileNumberMin
        : indicatorTile.number + 1;
    return OkeyDesignation(color: indicatorTile.color, number: wrappedNumber);
  }

  /// Verilen taş listesindeki, [designation] ile eşleşen normal taşları
  /// `TileType.okey` olarak işaretler.
  ///
  /// Sahte okey taşları bu fonksiyondan etkilenmez; onlar zaten
  /// `isFalseOkey` alanı sayesinde her zaman joker olarak davranır
  /// (bkz. [OkeyTile.actsAsJoker]).
  static List<OkeyTile> applyOkeyDesignation(
    List<OkeyTile> tiles,
    OkeyDesignation designation,
  ) {
    return tiles
        .map((tile) {
          final isDesignatedOkey =
              tile.type == TileType.normal &&
              tile.color == designation.color &&
              tile.number == designation.number;
          if (!isDesignatedOkey) return tile;
          return tile.copyWith(type: TileType.okey, isOkey: true);
        })
        .toList(growable: false);
  }
}
