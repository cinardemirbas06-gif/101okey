/// Görsel ve ses varlıklarının merkezi yol tanımları.
abstract final class AssetPaths {
  static const String _tilesBase = 'assets/images/tiles';
  static const String _avatarsBase = 'assets/images/avatars';
  static const String _backgroundsBase = 'assets/images/backgrounds';
  static const String _sfxBase = 'assets/audio/sfx';
  static const String _musicBase = 'assets/audio/music';

  static String tileFace(String colorId, int number) =>
      '$_tilesBase/${colorId}_$number.png';

  static const String okeyGlow = '$_tilesBase/okey_glow.png';
  static const String falseOkey = '$_tilesBase/false_okey.png';
  static const String tileBack = '$_tilesBase/tile_back.png';

  static String avatar(String avatarId) => '$_avatarsBase/$avatarId.png';

  static const String tableFeltGreen = '$_backgroundsBase/felt_green.png';
  static const String tableFeltBlue = '$_backgroundsBase/felt_blue.png';
  static const String menuBackground = '$_backgroundsBase/menu_bg.png';

  static const String sfxDrawTile = '$_sfxBase/draw_tile.mp3';
  static const String sfxPlaceTile = '$_sfxBase/place_tile.mp3';
  static const String sfxDiscardTile = '$_sfxBase/discard_tile.mp3';
  static const String sfxOpenMeld = '$_sfxBase/open_meld.mp3';
  static const String sfxMeldTile = '$_sfxBase/meld_tile.mp3';
  static const String sfxUseOkey = '$_sfxBase/use_okey.mp3';
  static const String sfxInvalidMove = '$_sfxBase/invalid_move.mp3';
  static const String sfxTurnWarning = '$_sfxBase/turn_warning.mp3';
  static const String sfxHandWin = '$_sfxBase/hand_win.mp3';
  static const String sfxHandLose = '$_sfxBase/hand_lose.mp3';
  static const String sfxAchievement = '$_sfxBase/achievement.mp3';

  static const String musicMenuTheme = '$_musicBase/menu_theme.mp3';
  static const String musicTableAmbience = '$_musicBase/table_ambience.mp3';

  const AssetPaths._();
}
