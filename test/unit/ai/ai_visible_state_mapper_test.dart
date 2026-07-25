import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/ai/ai_visible_state_mapper.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

import '../../helpers/test_state.dart';

void main() {
  group('AiVisibleStateMapper.buildVisibleState', () {
    test('KRİTİK: rakiplerin kapalı elleri hiçbir alanda görünmez', () {
      final self = Player(
        id: 'ai1',
        name: 'AI Ayşe',
        avatarId: 'a1',
        isAI: true,
        hand: [normalTile('r5', TileColor.red, 5)],
      );
      final opponent = Player(
        id: 'p2',
        name: 'Çınar',
        avatarId: 'a2',
        hand: [
          normalTile('b7', TileColor.blue, 7),
          normalTile('y3', TileColor.yellow, 3),
        ],
      );
      final state = buildTestGameState(players: [self, opponent]).copyWith(
        indicatorTile: normalTile('bl4', TileColor.black, 4),
        okeyTile: normalTile('bl5', TileColor.black, 5),
      );

      final visible = AiVisibleStateMapper.buildVisibleState(state, 'ai1');

      // Rakibin gerçek taş kimlikleri (b7, y3) hiçbir serileştirilmiş
      // alanda yer almamalı.
      final serializedOpponents = visible.opponents
          .map((o) => '${o.playerId}-${o.remainingTileCount}')
          .join();
      expect(serializedOpponents.contains('b7'), isFalse);
      expect(serializedOpponents.contains('y3'), isFalse);

      final opponentPublic = visible.opponents.single;
      expect(opponentPublic.playerId, 'p2');
      expect(opponentPublic.remainingTileCount, 2);
      expect(visible.ownHand.map((t) => t.id), ['r5']);
    });

    test('kendi eli ve masaya açık bilgiler doğru aktarılır', () {
      final self = Player(
        id: 'ai1',
        name: 'AI',
        avatarId: 'a1',
        isAI: true,
        hasOpened: true,
        hand: [normalTile('r5', TileColor.red, 5)],
      );
      final opponent = Player(
        id: 'p2',
        name: 'Çınar',
        avatarId: 'a2',
        hasOpenedWithPairs: true,
        hand: List.generate(3, (i) => normalTile('t$i', TileColor.blue, i + 1)),
      );
      final state = buildTestGameState(
        players: [self, opponent],
        discardPile: [normalTile('y9', TileColor.yellow, 9)],
      ).copyWith(
        indicatorTile: normalTile('bl4', TileColor.black, 4),
        okeyTile: normalTile('bl5', TileColor.black, 5),
      );

      final visible = AiVisibleStateMapper.buildVisibleState(state, 'ai1');

      expect(visible.selfHasOpened, isTrue);
      expect(visible.currentDiscardTopTile?.id, 'y9');
      expect(visible.remainingDeckCount, state.drawPile.length);
      expect(visible.opponents.single.hasOpenedWithPairs, isTrue);
      expect(visible.opponents.single.remainingTileCount, 3);
    });
  });
}
