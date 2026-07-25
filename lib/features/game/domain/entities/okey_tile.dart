import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/tile_color.dart';
import '../enums/tile_type.dart';

part 'okey_tile.freezed.dart';
part 'okey_tile.g.dart';

/// Tek bir 101 Okey taşını temsil eder.
///
/// Her taş [id] ile benzersiz biçimde tanımlanır; aynı renk/sayı
/// kombinasyonundan iki fiziksel kopya bulunduğu için eşitlik kontrolü
/// [id] üzerinden yapılır, [color]/[number] üzerinden değil.
///
/// [isOkey], taş oluşturulduğunda değil; gösterge belirlendikten sonra
/// `TileIndicatorService` tarafından ilgili taşlar işaretlenerek atanır.
@freezed
class OkeyTile with _$OkeyTile {
  const OkeyTile._();

  const factory OkeyTile({
    required String id,
    required TileColor color,
    required int number,
    required TileType type,
    @Default(false) bool isOkey,
    @Default(false) bool isFalseOkey,
  }) = _OkeyTile;

  factory OkeyTile.fromJson(Map<String, dynamic> json) =>
      _$OkeyTileFromJson(json);

  bool get isNormal => type == TileType.normal;

  /// Sahte okey, elinde bulunduğu oyuncu için her zaman okey gibi davranır
  /// ancak masaya normal taş yerine konulduğunda gerçek değerini temsil
  /// etmek zorundadır (bkz. [MeldTile]).
  bool get actsAsJoker => isOkey || isFalseOkey;
}
