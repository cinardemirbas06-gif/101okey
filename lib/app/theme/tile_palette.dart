import 'package:flutter/material.dart';

import '../../features/game/domain/enums/tile_color.dart';

/// Domain katmanındaki [TileColor] enum'unu (bilinçli olarak Flutter'dan
/// bağımsız) gerçek görsel renklere eşler.
///
/// Bu eşleme yalnızca sunum (presentation) katmanında yaşar; domain
/// katmanı hiçbir zaman `dart:ui`/`Color` bilmez.
abstract final class TilePalette {
  const TilePalette._();

  static const Color red = Color(0xFFC1272D);
  static const Color black = Color(0xFF1A1A1A);
  static const Color blue = Color(0xFF1565C0);
  static const Color yellow = Color(0xFFF2A900);

  static const Color ivory = Color(0xFFFFFBF0);
  static const Color tableFeltGreen = Color(0xFF0B6E4F);
  static const Color tableFeltDark = Color(0xFF0A4A34);

  static Color colorFor(TileColor color) => switch (color) {
    TileColor.red => red,
    TileColor.black => black,
    TileColor.blue => blue,
    TileColor.yellow => yellow,
  };
}
