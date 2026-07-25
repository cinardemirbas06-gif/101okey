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

  // --- Masa teması: koyu lacivert (bkz. oyun masası ekranı) ---
  static const Color tableNavyDarkest = Color(0xFF07182A);
  static const Color tableNavyDark = Color(0xFF0C2A42);
  static const Color tableNavyMid = Color(0xFF15436A);
  static const Color tableNavyLight = Color(0xFF1E5480);
  static const Color meldAreaBackground = Color(0xFF123553);
  static const Color meldAreaGridLine = Color(0x1AFFFFFF);

  // --- Istaka tepsisi: ahşap doku (gradient ile taklit edilir, görsel
  // varlık kullanılmaz — bkz. proje kapsam notları) ---
  static const Color woodLight = Color(0xFFA9762E);
  static const Color woodMid = Color(0xFF8A5C22);
  static const Color woodDark = Color(0xFF5E3E17);

  // --- Sağ eylem rayı ve kural rozetleri ---
  static const Color actionRailButton = Color(0xFF3C5A78);
  static const Color ruleBadgePaired = Color(0xFF7A2E2E);
  static const Color ruleBadgeAssisted = Color(0xFF2E6B4F);
  static const Color ruleBadgeMultiplied = Color(0xFF16283C);
  static const Color ruleBadgeHandCounter = Color(0xFF3E7CA6);

  static Color colorFor(TileColor color) => switch (color) {
    TileColor.red => red,
    TileColor.black => black,
    TileColor.blue => blue,
    TileColor.yellow => yellow,
  };
}
