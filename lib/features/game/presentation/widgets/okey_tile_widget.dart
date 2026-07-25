import 'package:flutter/material.dart';

import '../../../../app/theme/tile_palette.dart';
import '../../domain/entities/okey_tile.dart';
import 'animation_speed.dart';

/// Tek bir 101 Okey taşının görsel gösterimi.
///
/// Boyut dışarıdan [width]/[height] ile verilir (ekran genişliğine ve
/// ıstakadaki taş sayısına göre çağıran taraf hesaplar); burada sabit
/// piksel değeri kullanılmaz.
class OkeyTileWidget extends StatelessWidget {
  const OkeyTileWidget({
    super.key,
    required this.tile,
    required this.width,
    required this.height,
    this.isSelected = false,
    this.isDragging = false,
    this.faceDown = false,
  });

  final OkeyTile tile;
  final double width;
  final double height;
  final bool isSelected;
  final bool isDragging;
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(width * 0.14);

    if (faceDown) {
      return _shell(
        context: context,
        borderRadius: borderRadius,
        elevated: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TilePalette.tableFeltDark,
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white24, width: 1),
          ),
        ),
      );
    }

    final numberFontSize = height * 0.34;
    final isOkeyLike = tile.isOkey || tile.isFalseOkey;

    return Semantics(
      label: _semanticLabel(),
      selected: isSelected,
      child: _shell(
        context: context,
        borderRadius: borderRadius,
        elevated: isSelected || isDragging,
        glow: isOkeyLike,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: height * 0.06,
            horizontal: width * 0.08,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (tile.isFalseOkey)
                  Text(
                    'OK',
                    style: TextStyle(
                      fontSize: numberFontSize * 0.6,
                      fontWeight: FontWeight.w900,
                      color: TilePalette.colorFor(tile.color),
                      letterSpacing: 1,
                      height: 1,
                    ),
                  )
                else
                  Text(
                    '${tile.number}',
                    style: TextStyle(
                      fontSize: numberFontSize,
                      fontWeight: FontWeight.w800,
                      color: TilePalette.colorFor(tile.color),
                      height: 1,
                    ),
                  ),
                SizedBox(height: height * 0.08),
                _ColorMarker(
                  color: TilePalette.colorFor(tile.color),
                  symbol: tile.color.colorBlindSymbol,
                  size: width * 0.22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    if (tile.isFalseOkey) return 'Sahte okey';
    final suffix = tile.isOkey ? ' (okey)' : '';
    return '${tile.color.label} ${tile.number}$suffix';
  }

  Widget _shell({
    required BuildContext context,
    required BorderRadius borderRadius,
    required bool elevated,
    required Widget child,
    bool glow = false,
  }) {
    return AnimatedContainer(
      duration: GameUiPreferences.scaleOf(context, const Duration(milliseconds: 120)),
      curve: Curves.easeOut,
      width: width,
      height: height,
      transform: Matrix4.translationValues(
        0.0,
        elevated ? -height * 0.12 : 0.0,
        0.0,
      ),
      decoration: BoxDecoration(
        color: TilePalette.ivory,
        borderRadius: borderRadius,
        border: Border.all(
          color: glow ? const Color(0xFFFFD54F) : Colors.black12,
          width: glow ? 2 : 1,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
              blurRadius: elevated ? 14 : 8,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.35 : 0.18),
            blurRadius: elevated ? 10 : 4,
            offset: Offset(0, elevated ? 6 : 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ColorMarker extends StatelessWidget {
  const _ColorMarker({
    required this.color,
    required this.symbol,
    required this.size,
  });

  final Color color;
  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: size * 0.65,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
