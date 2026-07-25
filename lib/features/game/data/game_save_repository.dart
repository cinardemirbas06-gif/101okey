import 'dart:convert';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/game_exceptions.dart';
import '../../../../services/storage/hive_storage_service.dart';
import '../domain/entities/game_state.dart';

/// Devam eden elin otomatik kaydını ve geri yüklenmesini yöneten
/// depolama katmanı.
///
/// Kayıt, [GameState.toJson] üzerinden JSON'a çevrilip Hive'a metin
/// olarak yazılır (domain modelleri zaten `json_serializable` ile tam
/// serileştirilebilir olduğundan ayrı bir Hive `TypeAdapter` yazmaya
/// gerek yoktur). Şema sürümü uyuşmazlığında veya bozuk veri
/// durumunda kayıt güvenle temizlenir ve ilgili [GameException] alt
/// türü fırlatılır (bkz. proje gereksinimleri #32).
abstract final class GameSaveRepository {
  const GameSaveRepository._();

  static Future<void> save(GameState state) async {
    final box = HiveStorageService.savedGameBox;
    await box.put(StorageKeys.currentGameStateKey, jsonEncode(state.toJson()));
    await box.put(
      StorageKeys.saveSchemaVersionKey,
      GameConstants.currentSaveSchemaVersion,
    );
  }

  static Future<bool> hasSavedGame() async {
    final box = HiveStorageService.savedGameBox;
    return box.containsKey(StorageKeys.currentGameStateKey);
  }

  /// Kayıtlı eli yükler. Kayıt yoksa `null` döner.
  ///
  /// Şema sürümü uyuşmazlığı veya bozuk veri durumunda kaydı temizler ve
  /// [SaveVersionMismatchException]/[SaveDataCorruptedException]
  /// fırlatır — bu durumlarda çağıran taraf yeni bir oyun başlatmalıdır.
  static Future<GameState?> load() async {
    final box = HiveStorageService.savedGameBox;
    final rawJson = box.get(StorageKeys.currentGameStateKey) as String?;
    if (rawJson == null) return null;

    final savedVersion =
        box.get(StorageKeys.saveSchemaVersionKey) as int? ?? -1;
    if (savedVersion != GameConstants.currentSaveSchemaVersion) {
      await clear();
      throw SaveVersionMismatchException(
        savedVersion: savedVersion,
        expectedVersion: GameConstants.currentSaveSchemaVersion,
      );
    }

    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return GameState.fromJson(map);
    } catch (e) {
      await clear();
      throw SaveDataCorruptedException(debugDetail: e.toString());
    }
  }

  static Future<void> clear() async {
    await HiveStorageService.savedGameBox.clear();
  }
}
