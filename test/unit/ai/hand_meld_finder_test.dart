import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/ai/hand_meld_finder.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

import '../../helpers/test_state.dart';

void main() {
  group('HandMeldFinder.findRunCandidates', () {
    test('tam bir seriyi eksiksiz (missingFromOutside=0) olarak bulur', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r6', TileColor.red, 6),
        normalTile('r7', TileColor.red, 7),
      ];

      final candidates = HandMeldFinder.findRunCandidates(hand);
      final complete = candidates.where(
        (c) => c.isComplete && c.naturalTiles.length == 3,
      );

      expect(complete, isNotEmpty);
    });

    test('tek eksik taşlı seri missingFromOutside=1 olarak işaretlenir', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r7', TileColor.red, 7),
      ];

      final candidates = HandMeldFinder.findRunCandidates(hand);
      final almostRun = candidates.where(
        (c) =>
            c.naturalTiles.length == 2 &&
            c.jokersUsedFromHand == 0 &&
            c.missingFromOutside == 1,
      );

      expect(almostRun, isNotEmpty);
    });

    test('joker eksik sayıyı doldurur', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r7', TileColor.red, 7),
        okeyJoker('okey1', TileColor.blue, 2),
      ];

      final candidates = HandMeldFinder.findRunCandidates(hand);
      final completed = candidates.where(
        (c) =>
            c.naturalTiles.length == 2 &&
            c.jokersUsedFromHand == 1 &&
            c.isComplete,
      );

      expect(completed, isNotEmpty);
    });
  });

  group('HandMeldFinder.findGroupCandidates', () {
    test('tam bir grubu eksiksiz bulur', () {
      final hand = [
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        normalTile('m8', TileColor.blue, 8),
      ];

      final candidates = HandMeldFinder.findGroupCandidates(hand);
      final complete = candidates.where(
        (c) => c.isComplete && c.naturalTiles.length == 3,
      );

      expect(complete, isNotEmpty);
    });

    test('eksik renk joker ile tamamlanabiliyorsa işaretlenir', () {
      final hand = [
        normalTile('r8', TileColor.red, 8),
        normalTile('bl8', TileColor.black, 8),
        okeyJoker('okey1', TileColor.blue, 3),
      ];

      final candidates = HandMeldFinder.findGroupCandidates(hand);
      final completed = candidates.where(
        (c) => c.jokersUsedFromHand == 1 && c.isComplete,
      );

      expect(completed, isNotEmpty);
    });
  });

  group('MeldCandidate.containsTile', () {
    test('doğal taş için doğru sonuç döner', () {
      final hand = [
        normalTile('r5', TileColor.red, 5),
        normalTile('r6', TileColor.red, 6),
        normalTile('r7', TileColor.red, 7),
      ];
      final candidate = HandMeldFinder.findRunCandidates(
        hand,
      ).firstWhere((c) => c.naturalTiles.length == 3);

      expect(candidate.containsTile(hand[0]), isTrue);
      expect(
        candidate.containsTile(normalTile('y1', TileColor.yellow, 1)),
        isFalse,
      );
    });
  });
}
