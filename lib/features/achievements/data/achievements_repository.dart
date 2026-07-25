import '../../../services/storage/hive_storage_service.dart';
import '../domain/achievement_definition.dart';

/// Açılmış başarımların kimliklerini kalıcı olarak saklar.
abstract final class AchievementsRepository {
  const AchievementsRepository._();

  static const _key = 'unlocked_achievement_ids';

  static Future<void> saveUnlocked(Set<AchievementId> unlocked) async {
    final box = HiveStorageService.achievementsBox;
    await box.put(_key, unlocked.map((a) => a.name).toList());
  }

  static Set<AchievementId> loadUnlocked() {
    final box = HiveStorageService.achievementsBox;
    final raw = box.get(_key) as List<dynamic>?;
    if (raw == null) return {};
    final names = raw.cast<String>().toSet();
    return AchievementId.values.where((a) => names.contains(a.name)).toSet();
  }
}
