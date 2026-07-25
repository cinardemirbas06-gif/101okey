import '../../../../core/constants/game_constants.dart';
import '../entities/okey_tile.dart';
import 'hand_meld_finder.dart';

/// [OpeningAttemptFinder] (101 açılış) ve `HandCoverageFinder` (bitirme
/// denemesi) tarafından paylaşılan, sınırlı (bounded) geri izlemeli
/// per kombinasyonu arama motoru.
///
/// [HandMeldFinder] ile üretilen TAMAMLANMIŞ (elde tamamen kurulabilir)
/// aday perler arasından, aynı fiziksel taşı veya jokeri iki kez
/// kullanmadan, [isGoalReached] tarafından tanımlanan hedefe ulaşan bir
/// alt küme arar. [combinationBudget] aşılırsa arama durur ve `null`
/// döner (cihazı kilitlememek için).
abstract final class MeldCombinationSearch {
  const MeldCombinationSearch._();

  static List<List<OkeyTile>>? search({
    required List<OkeyTile> hand,
    required int combinationBudget,
    required bool Function(int accumulatedPoints, int coveredTileCount)
    isGoalReached,
  }) {
    final completeCandidates =
        HandMeldFinder.findAllCandidates(hand)
            .where(
              (c) =>
                  c.isComplete && c.filledSlots >= GameConstants.minMeldSize,
            )
            .toList()
          ..sort((a, b) => b.potentialPoints.compareTo(a.potentialPoints));

    final jokerPool = hand.where((t) => t.actsAsJoker).toList();

    var attempts = 0;
    List<List<OkeyTile>>? bestResult;

    void backtrack(
      int index,
      List<List<OkeyTile>> chosen,
      Set<String> usedNaturalIds,
      int usedJokers,
      int accumulatedPoints,
      int coveredTileCount,
    ) {
      if (bestResult != null || attempts >= combinationBudget) return;
      attempts++;

      if (isGoalReached(accumulatedPoints, coveredTileCount)) {
        bestResult = chosen;
        return;
      }
      if (index >= completeCandidates.length) return;

      final candidate = completeCandidates[index];
      final conflictsNatural = candidate.naturalTiles.any(
        (t) => usedNaturalIds.contains(t.id),
      );
      final jokersNeeded = candidate.jokersUsedFromHand;

      if (!conflictsNatural && usedJokers + jokersNeeded <= jokerPool.length) {
        final tileGroup = [
          ...candidate.naturalTiles,
          ...jokerPool.sublist(usedJokers, usedJokers + jokersNeeded),
        ];
        backtrack(
          index + 1,
          [...chosen, tileGroup],
          {...usedNaturalIds, ...candidate.naturalTiles.map((t) => t.id)},
          usedJokers + jokersNeeded,
          accumulatedPoints + candidate.potentialPoints,
          coveredTileCount + candidate.filledSlots,
        );
      }
      if (bestResult != null) return;

      // Bu adayı dahil etmeden devam et.
      backtrack(
        index + 1,
        chosen,
        usedNaturalIds,
        usedJokers,
        accumulatedPoints,
        coveredTileCount,
      );
    }

    backtrack(0, const [], const {}, 0, 0, 0);
    return bestResult;
  }
}
