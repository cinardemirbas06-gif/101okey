import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../achievements/domain/achievement_definition.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
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
    final animationsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.animationsEnabled),
    );

    if (result == null || gameState == null) {
      return const Scaffold(body: Center(child: Text('Sonuç bulunamadı.')));
    }

    final winnerName = result.winnerPlayerId == null
        ? null
        : gameState.players
              .firstWhere((p) => p.id == result.winnerPlayerId)
              .name;

    var entranceIndex = 0;

    return Scaffold(
      appBar: AppBar(title: const Text('El Sonucu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _CelebrationHeader(
            winnerName: winnerName,
            animationsEnabled: animationsEnabled,
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
            _StaggeredEntrance(
              index: entranceIndex++,
              enabled: animationsEnabled,
              child: _PlayerScoreCard(
                playerName: gameState.players
                    .firstWhere((p) => p.id == score.playerId)
                    .name,
                score: score,
              ),
            ),
          if (session.newlyUnlockedAchievements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Yeni Başarımlar!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            for (final id in session.newlyUnlockedAchievements)
              _StaggeredEntrance(
                index: entranceIndex++,
                enabled: animationsEnabled,
                child: Card(
                  color: Colors.amber.shade50,
                  child: ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.amber.shade700),
                    title: Text(_achievementTitle(id)),
                  ),
                ),
              ),
          ],
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

  String _achievementTitle(AchievementId id) {
    return AchievementCatalog.all.firstWhere((a) => a.id == id).title;
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

/// Kazananı büyük bir başlık ve (animasyonlar açıksa) yaylanan bir
/// kupa ikonuyla vurgulayan üst bölüm.
class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader({
    required this.winnerName,
    required this.animationsEnabled,
  });

  final String? winnerName;
  final bool animationsEnabled;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      winnerName == null ? 'El sonuçsuz kaldı (berabere)' : '$winnerName kazandı!',
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );

    if (winnerName == null) {
      return Center(child: title);
    }

    final trophy = Icon(
      Icons.emoji_events,
      color: Colors.amber.shade700,
      size: 56,
    );

    return Center(
      child: Column(
        children: [
          if (!animationsEnabled)
            trophy
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: trophy,
            ),
          const SizedBox(height: 8),
          title,
        ],
      ),
    );
  }
}

/// Bir listedeki öğeleri sırayla (kademeli gecikmeyle) belirip kayarak
/// içeri sokan sarmalayıcı. `enabled` kapalıyken (kullanıcı animasyonları
/// kapattıysa) içerik anında görünür.
class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({
    required this.index,
    required this.enabled,
    required this.child,
  });

  final int index;
  final bool enabled;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> {
  late bool _visible = !widget.enabled;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      // `Future.delayed` taahhüdü doğrudan iptal edilemez; alttaki
      // gerçek zamanlı `Timer`'ı elde tutup `dispose`da iptal etmek,
      // widget testin ortasında elenirse (örn. sayfa değişirse) sarkan
      // bir zamanlayıcı bırakmamak için gereklidir.
      _timer = Timer(Duration(milliseconds: 80 * widget.index), () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: widget.child,
      ),
    );
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
