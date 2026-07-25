import 'package:flutter/material.dart';

import '../../domain/entities/meld.dart';
import '../../domain/entities/meld_tile.dart';
import '../../domain/entities/okey_tile.dart';
import '../../domain/enums/meld_type.dart';
import 'animation_speed.dart';
import 'okey_tile_widget.dart';

/// Masaya açılmış tek bir perin (seri/grup/çift) görünümü.
///
/// Seriler için başına/sonuna, gruplar için sonuna sürükle-bırak ile
/// taş eklenebilecek bir alan gösterir (geçerlilik gerçek doğrulama
/// [MeldEngine.addTileToMeld] tarafından yapılır; burada yalnızca
/// bırakmayı kabul edip callback'i tetikleriz).
class TableMeldView extends StatelessWidget {
  const TableMeldView({
    super.key,
    required this.meld,
    required this.tileWidth,
    required this.tileHeight,
    required this.onDropAtStart,
    required this.onDropAtEnd,
    required this.onDropOnJokerSlot,
  });

  final Meld meld;
  final double tileWidth;
  final double tileHeight;
  final ValueChanged<OkeyTile> onDropAtStart;
  final ValueChanged<OkeyTile> onDropAtEnd;
  final void Function(OkeyTile handTile, int position) onDropOnJokerSlot;

  @override
  Widget build(BuildContext context) {
    final canExtendBothEnds = meld.type == MeldType.run && !meld.isLocked;
    final canAppend = !meld.isLocked && meld.type != MeldType.pair;

    return Container(
      padding: EdgeInsets.all(tileWidth * 0.06),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(tileWidth * 0.16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canExtendBothEnds)
            _DropZone(
              width: tileWidth * 0.5,
              height: tileHeight,
              onAccept: onDropAtStart,
            ),
          for (var i = 0; i < meld.tiles.length; i++) ...[
            if (i > 0) SizedBox(width: tileWidth * 0.04),
            _MeldSlot(
              meldTile: meld.tiles[i],
              position: i,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
              onDropOnJokerSlot: onDropOnJokerSlot,
            ),
          ],
          if (canAppend)
            _DropZone(
              width: tileWidth * 0.5,
              height: tileHeight,
              onAccept: onDropAtEnd,
            ),
        ],
      ),
    );
  }
}

class _MeldSlot extends StatelessWidget {
  const _MeldSlot({
    required this.meldTile,
    required this.position,
    required this.tileWidth,
    required this.tileHeight,
    required this.onDropOnJokerSlot,
  });

  final MeldTile meldTile;
  final int position;
  final double tileWidth;
  final double tileHeight;
  final void Function(OkeyTile handTile, int position) onDropOnJokerSlot;

  @override
  Widget build(BuildContext context) {
    final tileView = OkeyTileWidget(
      tile: meldTile.tile,
      width: tileWidth,
      height: tileHeight,
    );

    if (!meldTile.isJokerSubstitute) return tileView;

    return DragTarget<OkeyTile>(
      onWillAcceptWithDetails: (details) =>
          details.data.color == meldTile.effectiveColor &&
          details.data.number == meldTile.effectiveNumber &&
          !details.data.actsAsJoker,
      onAcceptWithDetails: (details) =>
          onDropOnJokerSlot(details.data, position),
      builder: (context, candidateData, rejectedData) {
        final highlighted =
            candidateData.isNotEmpty &&
            GameUiPreferences.dropHighlightsEnabledOf(context);
        return AnimatedContainer(
          duration: GameUiPreferences.scaleOf(
            context,
            const Duration(milliseconds: 120),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tileWidth * 0.18),
            border: highlighted
                ? Border.all(color: Colors.greenAccent, width: 2)
                : null,
          ),
          child: tileView,
        );
      },
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.width,
    required this.height,
    required this.onAccept,
  });

  final double width;
  final double height;
  final ValueChanged<OkeyTile> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<OkeyTile>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final active =
            candidateData.isNotEmpty &&
            GameUiPreferences.dropHighlightsEnabledOf(context);
        return AnimatedContainer(
          duration: GameUiPreferences.scaleOf(
            context,
            const Duration(milliseconds: 120),
          ),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: active
                ? Colors.greenAccent.withValues(alpha: 0.35)
                : Colors.white10,
            borderRadius: BorderRadius.circular(width * 0.3),
            border: Border.all(
              color: active ? Colors.greenAccent : Colors.white24,
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(
            Icons.add,
            color: Colors.white.withValues(alpha: 0.6),
            size: width * 0.6,
          ),
        );
      },
    );
  }
}
