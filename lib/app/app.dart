import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/tile_palette.dart';

/// Uygulamanın kök widget'ı: tema ve GoRouter yönlendirmesini kurar.
class OkeyProApp extends StatelessWidget {
  const OkeyProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '101 Okey Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: TilePalette.tableFeltGreen,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
