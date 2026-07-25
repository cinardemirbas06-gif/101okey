import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/storage/hive_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService.init();
  runApp(const ProviderScope(child: OkeyProApp()));
}
