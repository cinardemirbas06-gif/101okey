import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/tile_color.dart';
import 'okey_tile.dart';

part 'meld_tile.freezed.dart';
part 'meld_tile.g.dart';

/// Bir per içindeki tek bir taş yuvası.
///
/// [tile] joker (okey/sahte okey) ise, [representedColor] ve
/// [representedNumber] o anda hangi gerçek taşın yerine geçtiğini açıkça
/// saklar. Normal taşlarda bu alanlar null'dır ve taşın kendi rengi/sayısı
/// geçerlidir.
@freezed
class MeldTile with _$MeldTile {
  const MeldTile._();

  const factory MeldTile({
    required OkeyTile tile,
    TileColor? representedColor,
    int? representedNumber,
  }) = _MeldTile;

  factory MeldTile.fromJson(Map<String, dynamic> json) =>
      _$MeldTileFromJson(json);

  /// Joker kullanılıp kullanılmadığından bağımsız, bu yuvanın perdeki
  /// efektif rengi.
  TileColor get effectiveColor => representedColor ?? tile.color;

  /// Joker kullanılıp kullanılmadığından bağımsız, bu yuvanın perdeki
  /// efektif sayısı.
  int get effectiveNumber => representedNumber ?? tile.number;

  /// Bu yuvada joker bir taşın gerçek bir taş yerine kullanılıp
  /// kullanılmadığı.
  bool get isJokerSubstitute => tile.actsAsJoker;
}
