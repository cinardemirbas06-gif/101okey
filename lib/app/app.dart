import 'package:flutter/material.dart';

/// Uygulamanın kök widget'ı.
///
/// Bu, Aşama 2 (temel domain modelleri) için geçici bir yer tutucudur.
/// Gerçek ana menü, GoRouter yönlendirmesi ve tema sistemi Aşama 6'da
/// (kullanıcı arayüzü) eklenecektir.
class OkeyProApp extends StatelessWidget {
  const OkeyProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '101 Okey Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
      ),
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '101 Okey Pro\n\n'
            'Oyun motoru geliştirme aşamasında.\n'
            'Ana menü ve oyun masası bir sonraki aşamalarda eklenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
