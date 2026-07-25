import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/ai/discard_advisor.dart';
import 'package:okey_101_pro/features/game/domain/entities/ai_visible_game_state.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld_tile.dart';
import 'package:okey_101_pro/features/game/domain/entities/player_public_state.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

import '../../helpers/test_state.dart';

AiVisibleGameState _visible({
  required List<dynamic> ownHand,
  List<dynamic> discardHistory = const [],
  List<Meld> tableMelds = const [],
  List<PlayerPublicState> opponents = const [],
  dynamic currentDiscardTopTile,
  bool selfHasOpened = false,
}) {
  return AiVisibleGameState(
    selfPlayerId: 'ai1',
    ownHand: ownHand.cast(),
    discardHistory: discardHistory.cast(),
    tableMelds: tableMelds,
    indicatorTile: normalTile('ind', TileColor.black, 4),
    okeyTile: okeyJoker('okeyref', TileColor.black, 5),
    remainingDeckCount: 20,
    opponents: opponents,
    currentDiscardTopTile: currentDiscardTopTile,
    selfHasOpened: selfHasOpened,
  );
}

void main() {
  group('DiscardAdvisor', () {
    test('tamamen izole (ölü) taş, aktif per parçası olan taştan daha '
        'yüksek atma skoru alır', () {
      final deadTile = normalTile('y1', TileColor.yellow, 1);
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r6', TileColor.red, 6),
        normalTile('r7', TileColor.red, 7),
        deadTile,
      ];
      final visible = _visible(ownHand: hand);

      final deadScore = DiscardAdvisor.scoreDiscardCandidate(
        tile: deadTile,
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.medium,
        personality: AiPersonality.cautious,
      );
      final meldTileScore = DiscardAdvisor.scoreDiscardCandidate(
        tile: hand[0],
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.medium,
        personality: AiPersonality.cautious,
      );

      expect(deadScore, greaterThan(meldTileScore));
    });

    test('chooseDiscard, tamamlanmış seriyi bozmadan ölü taşı seçer', () {
      final deadTile = normalTile('y1', TileColor.yellow, 1);
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r6', TileColor.red, 6),
        normalTile('r7', TileColor.red, 7),
        deadTile,
      ];
      final visible = _visible(ownHand: hand);

      final chosen = DiscardAdvisor.chooseDiscard(
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.medium,
        personality: AiPersonality.cautious,
      );

      expect(chosen.id, 'y1');
    });

    test('okeyHoarder kişiliği jokerin atılma skorunu düşürür', () {
      final joker = okeyJoker('okey1', TileColor.blue, 9);
      final hand = [
        joker,
        normalTile('y1', TileColor.yellow, 1),
        normalTile('y2', TileColor.yellow, 2),
      ];
      final visible = _visible(ownHand: hand);

      final hoarderScore = DiscardAdvisor.scoreDiscardCandidate(
        tile: joker,
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.medium,
        personality: AiPersonality.okeyHoarder,
      );
      final cautiousScore = DiscardAdvisor.scoreDiscardCandidate(
        tile: joker,
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.medium,
        personality: AiPersonality.cautious,
      );

      expect(hoarderScore, lessThan(cautiousScore));
    });

    test('kolay zorluk, masaya oynanabilir riskli taşı rakip risk cezası '
        'olmadan değerlendirir', () {
      final riskyTile = normalTile('r10', TileColor.red, 10);
      final hand = [
        riskyTile,
        normalTile('y1', TileColor.yellow, 1),
        normalTile('y2', TileColor.yellow, 2),
      ];
      final tableMeld = Meld(
        id: 'meld1',
        type: MeldType.run,
        openedByPlayerId: 'p2',
        tiles: [
          MeldTile(tile: normalTile('r11', TileColor.red, 11)),
          MeldTile(tile: normalTile('r12', TileColor.red, 12)),
          MeldTile(tile: normalTile('r13', TileColor.red, 13)),
        ],
      );
      final visible = _visible(
        ownHand: hand,
        tableMelds: [tableMeld],
        opponents: [
          const PlayerPublicState(
            playerId: 'p2',
            name: 'Rakip',
            remainingTileCount: 10,
            hasOpened: true,
            hasOpenedWithPairs: false,
          ),
        ],
      );

      final easyScore = DiscardAdvisor.scoreDiscardCandidate(
        tile: riskyTile,
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.easy,
        personality: AiPersonality.cautious,
      );
      final expertScore = DiscardAdvisor.scoreDiscardCandidate(
        tile: riskyTile,
        hand: hand,
        visibleState: visible,
        difficulty: AiDifficulty.expert,
        personality: AiPersonality.cautious,
      );

      // Expert seviye rakip riskini ciddiye alıp skoru düşürmeli; kolay
      // seviye bu cezayı hiç uygulamaz, bu yüzden skoru daha yüksek
      // kalır.
      expect(easyScore, greaterThan(expertScore));
    });
  });
}
