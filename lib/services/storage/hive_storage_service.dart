import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/storage_keys.dart';

/// Uygulamanın kalıcı depolama (Hive) altyapısını başlatan ve kutulara
/// (box) erişim sağlayan merkezi servis.
///
/// Üretimde [init] platform belgeler dizinini kullanır; testlerde
/// [overridePath] ile geçici bir dizin verilerek platform kanalları
/// (path_provider) hiç çağrılmadan çalıştırılabilir.
abstract final class HiveStorageService {
  const HiveStorageService._();

  static bool _initialized = false;

  static Future<void> init({String? overridePath}) async {
    if (_initialized) return;
    final path = overridePath ?? (await getApplicationDocumentsDirectory()).path;
    Hive.init(path);
    await Future.wait([
      Hive.openBox<dynamic>(StorageKeys.savedGameBox),
      Hive.openBox<dynamic>(StorageKeys.settingsBox),
      Hive.openBox<dynamic>(StorageKeys.statisticsBox),
      Hive.openBox<dynamic>(StorageKeys.achievementsBox),
    ]);
    _initialized = true;
  }

  /// Yalnızca testlerde: kutuları kapatıp yeniden başlatılabilir hale
  /// getirir.
  static Future<void> resetForTesting() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
  }

  static Box<dynamic> get savedGameBox => Hive.box(StorageKeys.savedGameBox);
  static Box<dynamic> get settingsBox => Hive.box(StorageKeys.settingsBox);
  static Box<dynamic> get statisticsBox => Hive.box(StorageKeys.statisticsBox);
  static Box<dynamic> get achievementsBox =>
      Hive.box(StorageKeys.achievementsBox);
}
