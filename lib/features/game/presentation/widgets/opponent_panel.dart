import 'package:flutter/material.dart';

import '../../domain/entities/player_public_state.dart';

/// Bir rakip (yapay zekâ) oyuncunun masadaki kompakt görünümü.
///
/// Rakibin taşlarının yüzü hiçbir zaman gösterilmez; yalnızca kalan taş
/// sayısı, açılma durumu ve sırası gelip gelmediği görünür. Yatay
/// (landscape) düzende dikey alan kısıtlı olduğundan tek satırlık, yatay
/// bir "hap" (chip) olarak çizilir.
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.amberAccent : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blueGrey.shade700,
            child: Text(
              opponent.name.isNotEmpty ? opponent.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 70),
            child: Text(
              opponent.name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.style, color: Colors.white70, size: 12),
          const SizedBox(width: 2),
          Text(
            '${opponent.remainingTileCount}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          if (opponent.hasOpened) ...[
            const SizedBox(width: 4),
            Icon(
              opponent.hasOpenedWithPairs ? Icons.join_full : Icons.lock_open,
              color: Colors.greenAccent,
              size: 12,
            ),
          ],
        ],
      ),
    );
  }
}
