/// Yapay zekâ oyuncuların zorluk seviyesi.
///
/// [searchDepth] ve [combinationBudget], AI karar motorunun ne kadar
/// derinlemesine arama yapacağını sınırlar (bkz. `features/game/domain/ai`).
enum AiDifficulty {
  easy(searchDepth: 1, combinationBudget: 200, thinkingDelayMs: 400),
  medium(searchDepth: 2, combinationBudget: 800, thinkingDelayMs: 700),
  hard(searchDepth: 3, combinationBudget: 2500, thinkingDelayMs: 1100),
  expert(searchDepth: 4, combinationBudget: 6000, thinkingDelayMs: 1600);

  const AiDifficulty({
    required this.searchDepth,
    required this.combinationBudget,
    required this.thinkingDelayMs,
  });

  /// Kaç hamle ötesinin değerlendirileceği (yaklaşık arama derinliği).
  final int searchDepth;

  /// Bir karar için değerlendirilecek en fazla kombinasyon sayısı.
  final int combinationBudget;

  /// Doğal görünmesi için eklenen minimum düşünme gecikmesi.
  final int thinkingDelayMs;
}
