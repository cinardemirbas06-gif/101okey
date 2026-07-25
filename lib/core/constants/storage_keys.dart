/// Hive kutuları ve SharedPreferences anahtarları tek noktadan yönetilir.
abstract final class StorageKeys {
  static const String savedGameBox = 'saved_game_box';
  static const String settingsBox = 'settings_box';
  static const String statisticsBox = 'statistics_box';
  static const String achievementsBox = 'achievements_box';

  static const String currentGameStateKey = 'current_game_state';
  static const String saveSchemaVersionKey = 'save_schema_version';
  static const String playerProfileKey = 'player_profile';

  const StorageKeys._();
}
