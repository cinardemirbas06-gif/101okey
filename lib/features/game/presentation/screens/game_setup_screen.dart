import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/game_rules_config.dart';
import '../../domain/enums/ai_difficulty.dart';
import '../controllers/game_controller.dart';

/// Oyuna başlamadan önce oyuncu adı, AI zorluk seviyeleri ve ev kuralı
/// profilinin seçildiği kurulum ekranı.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  final _nameController = TextEditingController(text: 'Oyuncu');
  AiDifficulty _aiLevel = AiDifficulty.medium;
  _RulesPreset _rulesPreset = _RulesPreset.standard;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Kurulumu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Oyuncu adı',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Adınızı girin',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Yapay zekâ zorluğu (3 rakip için)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AiDifficulty>(
            segments: const [
              ButtonSegment(value: AiDifficulty.easy, label: Text('Kolay')),
              ButtonSegment(value: AiDifficulty.medium, label: Text('Orta')),
              ButtonSegment(value: AiDifficulty.hard, label: Text('Zor')),
              ButtonSegment(
                value: AiDifficulty.expert,
                label: Text('Uzman'),
              ),
            ],
            selected: {_aiLevel},
            onSelectionChanged: (selection) {
              setState(() => _aiLevel = selection.first);
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Ev kuralı profili',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_RulesPreset>(
            segments: const [
              ButtonSegment(
                value: _RulesPreset.standard,
                label: Text('Standart'),
              ),
              ButtonSegment(
                value: _RulesPreset.quick,
                label: Text('Hızlı'),
              ),
              ButtonSegment(
                value: _RulesPreset.professional,
                label: Text('Profesyonel'),
              ),
            ],
            selected: {_rulesPreset},
            onSelectionChanged: (selection) {
              setState(() => _rulesPreset = selection.first);
            },
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              final playerName = _nameController.text.trim().isEmpty
                  ? 'Oyuncu'
                  : _nameController.text.trim();
              final settings = ref.read(settingsControllerProvider);
              final baseRules = _resolveRules(_rulesPreset);
              ref
                  .read(gameControllerProvider.notifier)
                  .startNewGame(
                    playerName: playerName,
                    rules: baseRules.copyWith(
                      timerEnabled: settings.turnTimerEnabled,
                      turnDuration: Duration(
                        seconds: settings.turnDurationSeconds,
                      ),
                    ),
                    aiDifficulties: [_aiLevel, _aiLevel, _aiLevel],
                  );
              context.go('/game');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Oyunu Başlat'),
          ),
        ],
      ),
    );
  }

  GameRulesConfig _resolveRules(_RulesPreset preset) {
    return switch (preset) {
      _RulesPreset.standard => GameRulesConfig.standard,
      _RulesPreset.quick => GameRulesConfig.quick,
      _RulesPreset.professional => GameRulesConfig.professional,
    };
  }
}

enum _RulesPreset { standard, quick, professional }
