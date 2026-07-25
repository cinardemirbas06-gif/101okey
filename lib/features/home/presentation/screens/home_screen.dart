import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/tile_palette.dart';
import '../../../game/data/game_save_repository.dart';
import '../../../game/presentation/controllers/game_controller.dart';

/// Ana menü.
///
/// Yalnızca gerçekten çalışan özellikler burada bir buton olarak yer
/// alır. "Devam Et" yalnızca gerçekten kayıtlı bir el varsa gösterilir.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<bool> _hasSavedGame;

  @override
  void initState() {
    super.initState();
    _hasSavedGame = GameSaveRepository.hasSavedGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TilePalette.tableNavyMid, TilePalette.tableNavyDarkest],
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
                    const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '101 Okey Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    FutureBuilder<bool>(
                      future: _hasSavedGame,
                      builder: (context, snapshot) {
                        if (snapshot.data != true) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FilledButton.icon(
                            onPressed: () async {
                              final resumed = await ref
                                  .read(gameControllerProvider.notifier)
                                  .resumeSavedGame();
                              if (resumed && context.mounted) {
                                context.push('/game');
                              }
                            },
                            icon: const Icon(Icons.restore),
                            label: const Text('Devam Et'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        );
                      },
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push('/setup'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Oyuna Başla'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuOutlinedButton(
                            icon: Icons.bar_chart,
                            label: 'İstatistikler',
                            onPressed: () => context.push('/statistics'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MenuOutlinedButton(
                            icon: Icons.emoji_events,
                            label: 'Başarımlar',
                            onPressed: () => context.push('/achievements'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MenuOutlinedButton(
                            icon: Icons.menu_book,
                            label: 'Kurallar',
                            onPressed: () => context.push('/rules'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MenuOutlinedButton(
                            icon: Icons.settings,
                            label: 'Ayarlar',
                            onPressed: () => context.push('/settings'),
                          ),
                        ),
                      ],
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

class _MenuOutlinedButton extends StatelessWidget {
  const _MenuOutlinedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Colors.white54),
      ),
    );
  }
}
