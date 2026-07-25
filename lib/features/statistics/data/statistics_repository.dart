import 'dart:convert';

import '../../../services/storage/hive_storage_service.dart';
import '../domain/player_statistics.dart';

/// [PlayerStatistics] için kalıcı depolama.
abstract final class StatisticsRepository {
  const StatisticsRepository._();

  static const _key = 'player_statistics';

  static Future<void> save(PlayerStatistics statistics) async {
    final box = HiveStorageService.statisticsBox;
    await box.put(_key, jsonEncode(statistics.toJson()));
  }

  static PlayerStatistics load() {
    final box = HiveStorageService.statisticsBox;
    final raw = box.get(_key) as String?;
    if (raw == null) return PlayerStatistics.empty;
    try {
      return PlayerStatistics.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return PlayerStatistics.empty;
    }
  }

  static Future<void> reset() async {
    await HiveStorageService.statisticsBox.delete(_key);
  }
}
