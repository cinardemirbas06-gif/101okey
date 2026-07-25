import 'package:flutter/material.dart';

import '../data/achievements_repository.dart';
import '../domain/achievement_definition.dart';

/// Tüm başarımları ve açılma durumlarını gösteren ekran.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = AchievementsRepository.loadUnlocked();

    return Scaffold(
      appBar: AppBar(title: const Text('Başarımlar')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: AchievementCatalog.all.length,
        itemBuilder: (context, index) {
          final def = AchievementCatalog.all[index];
          final isUnlocked = unlocked.contains(def.id);
          return Card(
            color: isUnlocked ? null : Theme.of(context).disabledColor.withValues(alpha: 0.05),
            child: ListTile(
              leading: Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                color: isUnlocked ? Colors.amber.shade700 : Colors.grey,
              ),
              title: Text(
                def.title,
                style: TextStyle(
                  color: isUnlocked ? null : Colors.grey,
                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(def.description),
            ),
          );
        },
      ),
    );
  }
}
