import '../entities/meld.dart';

/// 101 (veya yapılandırılan eşik) açılış kontrolünün sonucu.
final class OpeningCheckResult {
  const OpeningCheckResult({
    required this.totalScore,
    required this.requiredScore,
  });

  final int totalScore;
  final int requiredScore;

  bool get isSufficient => totalScore >= requiredScore;

  int get missingPoints =>
      isSufficient ? 0 : requiredScore - totalScore;

  /// "Perlerinizin toplamı 94. Açmak için 7 puan daha gerekiyor." gibi
  /// kullanıcıya gösterilecek Türkçe mesaj.
  String get userMessage => isSufficient
      ? 'Perlerinizin toplamı $totalScore. Açılış için yeterli.'
      : 'Perlerinizin toplamı $totalScore. Açmak için $missingPoints '
            'puan daha gerekiyor.';
}

/// Açılış (101) puan hesabı.
///
/// Her taşın puanı kendi sayı değeridir; joker bir taş, temsil ettiği
/// taşın değeri kadar puan katar (bkz. [MeldTile.effectiveNumber]).
abstract final class OpeningScoreCalculator {
  const OpeningScoreCalculator._();

  static int calculateMeldsScore(List<Meld> melds) {
    return melds.fold<int>(
      0,
      (sum, meld) =>
          sum + meld.tiles.fold<int>(0, (s, mt) => s + mt.effectiveNumber),
    );
  }

  static OpeningCheckResult check({
    required List<Meld> proposedMelds,
    required int requiredScore,
  }) {
    return OpeningCheckResult(
      totalScore: calculateMeldsScore(proposedMelds),
      requiredScore: requiredScore,
    );
  }
}
