import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/storage/hive_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 101 Okey masası yatay (landscape) düzen için tasarlanmıştır (bkz.
  // GameTableScreen ve diğer ekranların boyutlandırması); bu yüzden
  // uygulama her zaman yatay konumda kilitlenir. Web'de bu API'nin
  // etkisi yoktur (tarayıcı kendi döndürme kurallarını uygular);
  // yalnızca gerçek mobil (Android/iOS) derlemelerde uygulanır.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await HiveStorageService.init();
  runApp(const ProviderScope(child: OkeyProApp()));
}
