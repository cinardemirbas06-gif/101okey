import '../entities/game_rules_config.dart';
import '../entities/okey_tile.dart';
import 'meld_combination_search.dart';

/// Bir elde, açılış eşiğine (101 vb.) ulaşan bir per kombinasyonu arayan
/// sınırlı (bounded) arama.
///
/// [MeldCombinationSearch] üzerine kuruludur; hedefi "toplam puan ≥
/// eşik" olarak tanımlar. Tam optimal çözümü garanti eden bir bitmask/DP
/// arama YERİNE, sınırlı bir geri izleme kullanır — bu, "kabul
/// edilebilir kalitede, cihazı kilitlemeyen" bir çözüm sunar.
abstract final class OpeningAttemptFinder {
  const OpeningAttemptFinder._();

  /// Bulunursa, her biri bir per olacak şekilde gruplanmış taş
  /// listelerini döndürür (toplam puanı eşiğe ulaşır). Bulunamazsa
  /// `null` döner.
  static List<List<OkeyTile>>? findOpeningMelds(
    List<OkeyTile> hand,
    GameRulesConfig rules, {
    required int combinationBudget,
  }) {
    return MeldCombinationSearch.search(
      hand: hand,
      combinationBudget: combinationBudget,
      isGoalReached: (points, _) => points >= rules.openingThreshold,
    );
  }
}
