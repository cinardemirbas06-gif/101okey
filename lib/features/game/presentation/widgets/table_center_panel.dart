import 'package:flutter/material.dart';

import '../../domain/entities/okey_tile.dart';
import '../../domain/enums/tile_color.dart';
import '../../domain/enums/tile_type.dart';
import 'okey_tile_widget.dart';

/// Masanın ortasındaki alan: kapalı çekme destesi, gösterge, okey ve
/// atılan son taş.
class TableCenterPanel extends StatelessWidget {
  const TableCenterPanel({
    super.key,
    required this.drawPileCount,
    required this.indicatorTile,
    required this.okeyTile,
    required this.discardTopTile,
    required this.canDrawFromDeck,
    required this.onDrawFromDeck,
    required this.onTakeDiscard,
    required this.onDiscardDropped,
    required this.tileWidth,
    required this.tileHeight,
  });

  final int drawPileCount;
  final OkeyTile? indicatorTile;
  final OkeyTile? okeyTile;
  final OkeyTile? discardTopTile;
  final bool canDrawFromDeck;
  final VoidCallback onDrawFromDeck;
  final VoidCallback onTakeDiscard;
  final ValueChanged<OkeyTile> onDiscardDropped;
  final double tileWidth;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LabeledSlot(
          label: 'Gösterge',
          child: indicatorTile == null
              ? _placeholder(tileWidth, tileHeight)
              : OkeyTileWidget(
                  tile: indicatorTile!,
                  width: tileWidth,
                  height: tileHeight,
                ),
        ),
        SizedBox(width: tileWidth * 0.4),
        _LabeledSlot(
          label: 'Okey',
          child: okeyTile == null
              ? _placeholder(tileWidth, tileHeight)
              : OkeyTileWidget(
                  tile: okeyTile!,
                  width: tileWidth,
                  height: tileHeight,
                ),
        ),
        SizedBox(width: tileWidth * 0.7),
        _LabeledSlot(
          label: 'Deste ($drawPileCount)',
          child: GestureDetector(
            onTap: canDrawFromDeck ? onDrawFromDeck : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (drawPileCount > 0)
                  OkeyTileWidget(
                    tile: _dummy,
                    width: tileWidth,
                    height: tileHeight,
                    faceDown: true,
                  )
                else
                  _placeholder(tileWidth, tileHeight),
              ],
            ),
          ),
        ),
        SizedBox(width: tileWidth * 0.4),
        _LabeledSlot(
          label: 'Ortadaki Taş',
          child: DragTarget<OkeyTile>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) => onDiscardDropped(details.data),
            builder: (context, candidateData, rejectedData) {
              final active = candidateData.isNotEmpty;
              return GestureDetector(
                onTap: discardTopTile != null ? onTakeDiscard : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tileWidth * 0.2),
                    border: active
                        ? Border.all(color: Colors.greenAccent, width: 2)
                        : null,
                  ),
                  child: discardTopTile == null
                      ? _placeholder(tileWidth, tileHeight)
                      : OkeyTileWidget(
                          tile: discardTopTile!,
                          width: tileWidth,
                          height: tileHeight,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder(double w, double h) => SizedBox(width: w, height: h);
}

final OkeyTile _dummy = OkeyTile(
  id: '_deck_back',
  color: TileColor.red,
  number: 1,
  type: TileType.normal,
);

class _LabeledSlot extends StatelessWidget {
  const _LabeledSlot({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
