import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/okey_tile.dart';
import 'package:okey_101_pro/features/game/domain/enums/tile_color.dart';
import 'package:okey_101_pro/features/game/domain/enums/tile_type.dart';
import 'package:okey_101_pro/features/game/presentation/widgets/player_rack.dart';

OkeyTile _tile(String id, int number) => OkeyTile(
  id: id,
  color: TileColor.red,
  number: number,
  type: TileType.normal,
);

void main() {
  group('PlayerRack', () {
    testWidgets('taşa dokunma onTileTap\'i doğru taşla tetikler', (
      tester,
    ) async {
      final hand = [_tile('t0', 1), _tile('t1', 2), _tile('t2', 3)];
      OkeyTile? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRack(
              hand: hand,
              selectedTileIds: const {},
              onTileTap: (t) => tapped = t,
              onReorder: (_) {},
              tileWidth: 40,
              tileHeight: 58,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('rack_tile_t1')));
      await tester.pump();

      expect(tapped?.id, 't1');
    });

    testWidgets('bir taşı başka bir taşın üzerine sürüklemek onReorder\'ı '
        'doğru yeni sırayla tetikler', (tester) async {
      final hand = [_tile('t0', 1), _tile('t1', 2), _tile('t2', 3)];
      List<String>? newOrder;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRack(
              hand: hand,
              selectedTileIds: const {},
              onTileTap: (_) {},
              onReorder: (order) => newOrder = order,
              tileWidth: 40,
              tileHeight: 58,
            ),
          ),
        ),
      );

      // t2 (alt sırada tek başına, mid=ceil(3/2)=2) taşını t0'ın üzerine
      // sürükle: beklenen yeni sıra [t2, t0, t1].
      final fromCenter = tester.getCenter(
        find.byKey(const ValueKey('rack_tile_t2')),
      );
      final toCenter = tester.getCenter(
        find.byKey(const ValueKey('rack_tile_t0')),
      );

      final gesture = await tester.startGesture(fromCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(toCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(newOrder, ['t2', 't0', 't1']);
    });
  });
}
