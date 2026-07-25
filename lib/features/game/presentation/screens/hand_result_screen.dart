import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/player_hand_score.dart';
import '../controllers/game_controller.dart';

/// Bir elin sonunda kazananı, bitiş türünü ve her oyuncunun puan
/// dökümünü gösteren sonuç ekranı.
class HandResultScreen extends ConsumerWidget {
  const HandResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final result = session.lastHandScore;
    final gameState = session.gameState;

    if (result == null || gameState == null) {
      return const Scaffold(body: Center(child: Text('Sonuç bulunamadı.')));
    }

    final winnerName = result.winnerPlayerId == null
        ? null
        : gameState.players
              .firstWhere((p) => p.id == result.winnerPlayerId)
              .name;

    return Scaffold(
      appBar: AppBar(title: const Text('El Sonucu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Text(
              winnerName == null
                  ? 'El sonuçsuz kaldı (berabere)'
                  : '$winnerName kazandı!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (winnerName != null)
            Center(
              child: Text(
                _finishTypeLabel(result.finishType.name),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 24),
          for (final score in result.playerScores)
            _PlayerScoreCard(
              playerName: gameState.players
                  .firstWhere((p) => p.id == score.playerId)
                  .name,
              score: score,
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  ref.read(gameControllerProvider.notifier).startNextHandOrReturnToMenu();
                  context.go('/');
                },
                icon: const Icon(Icons.home),
                label: const Text('Ana Menü'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _finishTypeLabel(String raw) {
    return switch (raw) {
      'normal' => 'Normal bitiş',
      'okeyFinish' => 'Okeyle bitiş',
      'pairFinish' => 'Çiftten bitiş',
      'handFinish' => 'Elden bitiş',
      'indicatorFinish' => 'Göstergeyle bitiş',
      _ => raw,
    };
  }
}

class _PlayerScoreCard extends StatelessWidget {
  const _PlayerScoreCard({required this.playerName, required this.score});

  final String playerName;
  final PlayerHandScore score;

  @override
  Widget build(BuildContext context) {
    final isWinnerRow = score.finishBonus > 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (isWinnerRow)
              Text('Kazanç: +${score.finishBonus}')
            else ...[
              Text('Elde kalan taşlar: ${score.remainingTileValue}'),
              if (score.penaltyMultiplier != 1)
                Text('Çarpan: x${score.penaltyMultiplier}'),
              if (score.okeyRemainingPenalty > 0)
                Text('Elde kalan okey cezası: +${score.okeyRemainingPenalty}'),
              if (score.falseOkeyRemainingPenalty > 0)
                Text(
                  'Elde kalan sahte okey cezası: +${score.falseOkeyRemainingPenalty}',
                ),
              Text(
                'Toplam ceza: ${score.totalPenalty}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
