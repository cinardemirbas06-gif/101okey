import 'package:flutter/material.dart';

import '../data/statistics_repository.dart';

/// Cihazda kalıcı olarak saklanan oyuncu istatistiklerini gösteren ekran.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = StatisticsRepository.load();

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            title: 'Genel',
            rows: [
              ('Oynanan el', '${stats.handsPlayed}'),
              ('Kazanılan el', '${stats.handsWon}'),
              ('Kaybedilen el', '${stats.handsLost}'),
              (
                'Kazanma oranı',
                '${(stats.winRate * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          _StatCard(
            title: 'Bitiş türleri',
            rows: [
              ('Normal bitiş', '${stats.normalFinishCount}'),
              ('Okeyle bitiş', '${stats.okeyFinishCount}'),
              ('Çiftten bitiş', '${stats.pairFinishCount}'),
              ('Elden bitiş', '${stats.handFinishCount}'),
            ],
          ),
          _StatCard(
            title: 'Açılış',
            rows: [
              ('En yüksek açılış puanı', '${stats.highestOpeningScore}'),
              (
                'Ortalama açılış puanı',
                stats.averageOpeningScore.toStringAsFixed(1),
              ),
            ],
          ),
          _StatCard(
            title: 'Seriler',
            rows: [
              ('En uzun galibiyet serisi', '${stats.longestWinStreak}'),
              ('Güncel galibiyet serisi', '${stats.currentWinStreak}'),
            ],
          ),
          _StatCard(
            title: 'Taş hareketleri',
            rows: [
              ('Toplam atılan taş', '${stats.totalTilesDiscarded}'),
              (
                'Toplam desteden çekilen',
                '${stats.totalTilesDrawnFromDeck}',
              ),
              (
                'Toplam ortadan alınan',
                '${stats.totalTilesTakenFromDiscard}',
              ),
              (
                'Açık taş alma oranı',
                '${(stats.discardPileTakeRate * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(label), Text(value)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
