import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

/// Uygulamanın kök widget'ı: tema ve GoRouter yönlendirmesini kurar.
class OkeyProApp extends StatelessWidget {
  const OkeyProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '101 Okey Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
