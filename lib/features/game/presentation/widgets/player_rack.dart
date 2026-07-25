import 'package:flutter/material.dart';

import '../../domain/entities/okey_tile.dart';
import 'animation_speed.dart';
import 'okey_tile_widget.dart';

/// Gerçek oyuncunun iki sıralı, sürükle-bırakla yeniden sıralanabilen
/// ıstakası.
///
/// Taşlar tek bir mantıksal sıra (liste) olarak tutulur; görsel olarak
/// ilk yarısı üst sıraya, ikinci yarısı alt sıraya bölünür. Bir taşı
/// başka bir taşın üzerine sürüklemek, onu o taşın önüne taşır.
class PlayerRack extends StatelessWidget {
  const PlayerRack({
    super.key,
    required this.hand,
    required this.selectedTileIds,
    required this.onTileTap,
    required this.onReorder,
    required this.tileWidth,
    required this.tileHeight,
  });

  final List<OkeyTile> hand;
  final Set<String> selectedTileIds;
  final ValueChanged<OkeyTile> onTileTap;
  final ValueChanged<List<String>> onReorder;
  final double tileWidth;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return SizedBox(height: tileHeight * 2 + 12);
    }
    final mid = (hand.length / 2).ceil();
    final topRow = hand.sublist(0, mid);
    final bottomRow = hand.sublist(mid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RackRow(
          tiles: topRow,
          fullHand: hand,
          selectedTileIds: selectedTileIds,
          onTileTap: onTileTap,
          onReorder: onReorder,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
        ),
        SizedBox(height: tileHeight * 0.1),
        _RackRow(
          tiles: bottomRow,
          fullHand: hand,
          selectedTileIds: selectedTileIds,
          onTileTap: onTileTap,
          onReorder: onReorder,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
        ),
      ],
    );
  }
}

class _RackRow extends StatelessWidget {
  const _RackRow({
    required this.tiles,
    required this.fullHand,
    required this.selectedTileIds,
    required this.onTileTap,
    required this.onReorder,
    required this.tileWidth,
    required this.tileHeight,
  });

  final List<OkeyTile> tiles;
  final List<OkeyTile> fullHand;
  final Set<String> selectedTileIds;
  final ValueChanged<OkeyTile> onTileTap;
  final ValueChanged<List<String>> onReorder;
  final double tileWidth;
  final double tileHeight;

  List<String> _reordered(String draggedId, String targetId) {
    final ids = fullHand.map((t) => t.id).toList();
    ids.remove(draggedId);
    final targetIndex = ids.indexOf(targetId);
    ids.insert(targetIndex, draggedId);
    return ids;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tile in tiles)
            Padding(
              key: ValueKey('rack_tile_${tile.id}'),
              padding: EdgeInsets.symmetric(horizontal: tileWidth * 0.035),
              child: DragTarget<OkeyTile>(
                onWillAcceptWithDetails: (details) =>
                    details.data.id != tile.id,
                onAcceptWithDetails: (details) {
                  onReorder(_reordered(details.data.id, tile.id));
                },
                builder: (context, candidateData, rejectedData) {
                  final isDropTarget =
                      candidateData.isNotEmpty &&
                      GameUiPreferences.dropHighlightsEnabledOf(context);
                  return AnimatedScale(
                    scale: isDropTarget ? 1.08 : 1.0,
                    duration: GameUiPreferences.scaleOf(
                      context,
                      const Duration(milliseconds: 100),
                    ),
                    child: Draggable<OkeyTile>(
                      data: tile,
                      feedback: Material(
                        color: Colors.transparent,
                        child: OkeyTileWidget(
                          tile: tile,
                          width: tileWidth * 1.1,
                          height: tileHeight * 1.1,
                          isDragging: true,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: OkeyTileWidget(
                          tile: tile,
                          width: tileWidth,
                          height: tileHeight,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => onTileTap(tile),
                        onLongPress: () => _showTileInfo(context, tile),
                        child: OkeyTileWidget(
                          tile: tile,
                          width: tileWidth,
                          height: tileHeight,
                          isSelected: selectedTileIds.contains(tile.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showTileInfo(BuildContext context, OkeyTile tile) {
    final label = tile.isFalseOkey
        ? 'Sahte Okey — herhangi bir taş yerine kullanılabilir.'
        : '${tile.color.label} ${tile.number}'
              '${tile.isOkey ? ' — bu elin OKEY taşı!' : ''}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label), duration: const Duration(seconds: 2)));
  }
}
