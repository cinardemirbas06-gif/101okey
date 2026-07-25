import 'package:flutter/material.dart';

import '../../domain/entities/player_public_state.dart';

/// Bir rakip (yapay zekâ) oyuncunun masadaki kompakt görünümü.
///
/// Rakibin taşlarının yüzü hiçbir zaman gösterilmez; yalnızca kalan taş
/// sayısı, açılma durumu ve sırası gelip gelmediği görünür.
class OpponentPanel extends StatelessWidget {
  const OpponentPanel({
    super.key,
    required this.opponent,
    required this.isActive,
  });

  final PlayerPublicState opponent;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.amberAccent : Colors.transparent,
              width: 3,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.amberAccent.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blueGrey.shade700,
            child: Text(
              opponent.name.isNotEmpty ? opponent.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          opponent.name,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style, color: Colors.white70, size: 12),
            const SizedBox(width: 2),
            Text(
              '${opponent.remainingTileCount}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (opponent.hasOpened) ...[
              const SizedBox(width: 6),
              Icon(
                opponent.hasOpenedWithPairs
                    ? Icons.join_full
                    : Icons.lock_open,
                color: Colors.greenAccent,
                size: 12,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
