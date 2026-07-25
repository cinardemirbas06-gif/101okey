import '../entities/okey_tile.dart';
import 'meld_combination_search.dart';

/// Bir elin, en fazla [allowedLeftover] taş dışında TAMAMEN geçerli
/// perlere bölünüp bölünemeyeceğini arar.
///
/// Bitirme denemelerinde kullanılır:
/// - `allowedLeftover: 0` → elden bitirme (tüm el perlenir, atılacak
///   taş yoktur).
/// - `allowedLeftover: 1` → normal/okeyle/göstergeyle bitiş (bir taş
///   dışında her şey perlenir, o taş atılır).
///
/// [MeldCombinationSearch] üzerine kuruludur; hedefi "kapsanmayan taş
/// sayısı ≤ allowedLeftover" olarak tanımlar.
abstract final class HandCoverageFinder {
  const HandCoverageFinder._();

  static List<List<OkeyTile>>? findFullCoverage(
    List<OkeyTile> hand,
    int allowedLeftover, {
    required int combinationBudget,
  }) {
    final totalTiles = hand.length;
    return MeldCombinationSearch.search(
      hand: hand,
      combinationBudget: combinationBudget,
      isGoalReached: (_, covered) => totalTiles - covered <= allowedLeftover,
    );
  }
}
