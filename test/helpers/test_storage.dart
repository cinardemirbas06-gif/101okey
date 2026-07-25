import 'dart:io';

import 'package:okey_101_pro/services/storage/hive_storage_service.dart';

/// Testlerde Hive'ı gerçek platform kanalları (path_provider) olmadan,
/// temiz bir durumda başlatır/sıfırlar.
///
/// Bir test dosyasındaki İLK çağrı, geçici bir dizinle gerçek [Hive.init]
/// yapar. Aynı dosyadaki SONRAKİ çağrılar yalnızca kutu içeriklerini
/// temizler (`Hive.close()` + yeniden açma YAPMAZ) — bkz.
/// `HiveStorageService.clearAllForTesting` dokümantasyonu: bir önceki
/// testte tetiklenmiş ama `await` edilmemiş bir yazma işlemi varken
/// `Hive.close()` çağırmak widget testlerinde süresiz asılı kalabilir.
Future<void> resetTestStorage() async {
  if (HiveStorageService.isInitializedForTesting) {
    await HiveStorageService.clearAllForTesting();
    return;
  }
  final dir = await Directory.systemTemp.createTemp('okey_test_');
  await HiveStorageService.init(overridePath: dir.path);
}
