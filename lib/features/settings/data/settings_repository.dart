import 'dart:convert';

import '../../../services/storage/hive_storage_service.dart';
import '../domain/app_settings.dart';

/// [AppSettings] için kalıcı depolama.
abstract final class SettingsRepository {
  const SettingsRepository._();

  static const _key = 'app_settings';

  static Future<void> save(AppSettings settings) async {
    final box = HiveStorageService.settingsBox;
    await box.put(_key, jsonEncode(settings.toJson()));
  }

  static AppSettings load() {
    final box = HiveStorageService.settingsBox;
    final raw = box.get(_key) as String?;
    if (raw == null) return AppSettings.defaults;
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults;
    }
  }
}
