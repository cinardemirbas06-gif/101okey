import 'package:flutter/material.dart';

import '../../domain/entities/okey_tile.dart';
import 'okey_tile_widget.dart';

/// Oyuncunun açılış veya bitiriş denemesi için hazırladığı, henüz motora
/// gönderilmemiş per gruplarının gösterildiği alan.
///
/// Her grup kendi sürükle-bırak hedefidir: ıstakadan bir taş buraya
/// sürüklenirse o gruba eklenir. Sondaki "+" alanı YENİ bir grup başlatır.
class MeldStagingTray extends StatelessWidget {
  const MeldStagingTray({
    super.key,
    required this.groups,
    required this.tileWidth,
    required this.tileHeight,
    required this.onDropIntoGroup,
    required this.onDropIntoNewGroup,
    required this.onRemoveTileFromGroup,
  });

  final List<List<OkeyTile>> groups;
  final double tileWidth;
  final double tileHeight;
  final void Function(OkeyTile tile, int groupIndex) onDropIntoGroup;
  final ValueChanged<OkeyTile> onDropIntoNewGroup;
  final void Function(int groupIndex, String tileId) onRemoveTileFromGroup;

  @override
  Widget build(BuildContext context) {
    final smallWidth = tileWidth * 0.8;
    final smallHeight = tileHeight * 0.8;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var g = 0; g < groups.length; g++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DragTarget<OkeyTile>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) =>
                    onDropIntoGroup(details.data, g),
                builder: (context, candidateData, rejectedData) {
                  final active = candidateData.isNotEmpty;
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.greenAccent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(smallWidth * 0.2),
                      border: Border.all(
                        color: active ? Colors.greenAccent : Colors.white30,
                      ),
                    ),
                    constraints: BoxConstraints(minWidth: smallWidth + 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final tile in groups[g])
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  onRemoveTileFromGroup(g, tile.id),
                              child: OkeyTileWidget(
                                tile: tile,
                                width: smallWidth,
                                height: smallHeight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          DragTarget<OkeyTile>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) =>
                onDropIntoNewGroup(details.data),
            builder: (context, candidateData, rejectedData) {
              final active = candidateData.isNotEmpty;
              return Container(
                width: smallWidth,
                height: smallHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.greenAccent.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(smallWidth * 0.2),
                  border: Border.all(color: Colors.white24),
                ),
                child: Icon(
                  Icons.add_box_outlined,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
