import 'dart:io';

import 'package:okey_101_pro/services/storage/hive_storage_service.dart';

/// Testlerde Hive'ı gerçek platform kanalları (path_provider) olmadan,
/// her test için temiz bir geçici dizinle başlatır.
Future<void> resetTestStorage() async {
  await HiveStorageService.resetForTesting();
  final dir = await Directory.systemTemp.createTemp('okey_test_');
  await HiveStorageService.init(overridePath: dir.path);
}
