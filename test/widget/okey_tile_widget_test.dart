import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/okey_tile.dart';
import 'package:okey_101_pro/features/game/domain/enums/tile_color.dart';
import 'package:okey_101_pro/features/game/domain/enums/tile_type.dart';
import 'package:okey_101_pro/features/game/presentation/widgets/okey_tile_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('OkeyTileWidget', () {
    testWidgets('normal taşın sayısını gösterir', (tester) async {
      const tile = OkeyTile(
        id: 'r5',
        color: TileColor.red,
        number: 5,
        type: TileType.normal,
      );

      await tester.pumpWidget(
        _wrap(const OkeyTileWidget(tile: tile, width: 40, height: 58)),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('sahte okey "OK" olarak gösterilir', (tester) async {
      const tile = OkeyTile(
        id: 'fo1',
        color: TileColor.red,
        number: 0,
        type: TileType.falseOkey,
        isFalseOkey: true,
      );

      await tester.pumpWidget(
        _wrap(const OkeyTileWidget(tile: tile, width: 40, height: 58)),
      );

      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('faceDown iken taşın yüzü gösterilmez', (tester) async {
      const tile = OkeyTile(
        id: 'r5',
        color: TileColor.red,
        number: 5,
        type: TileType.normal,
      );

      await tester.pumpWidget(
        _wrap(
          const OkeyTileWidget(
            tile: tile,
            width: 40,
            height: 58,
            faceDown: true,
          ),
        ),
      );

      expect(find.text('5'), findsNothing);
    });
  });
}
