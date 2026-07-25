import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ana menü.
///
/// Yalnızca gerçekten çalışan özellikler burada bir buton olarak yer
/// alır: "İstatistikler", "Başarımlar" ve "Ayarlar" gibi henüz
/// uygulanmamış özellikler için sahte/işlevsiz butonlar EKLENMEZ (bkz.
/// proje kritik kuralları) — bunlar Aşama 7'de gerçek işlevleriyle
/// birlikte eklenecektir.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B6E4F), Color(0xFF06301F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded, color: Colors.white, size: 72),
                    const SizedBox(height: 12),
                    const Text(
                      '101 Okey Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () => context.push('/setup'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Oyuna Başla'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/rules'),
                      icon: const Icon(Icons.menu_book, color: Colors.white),
                      label: const Text(
                        'Kurallar',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
