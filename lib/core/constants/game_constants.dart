/// Merkezi oyun sabitleri. Kod içinde magic number kullanılmaması için
/// tüm sayısal/oyun kuralı sabitleri burada toplanır.
abstract final class GameConstants {
  // --- Taş seti ---
  static const int tileColorCount = 4;
  static const int tileNumberMin = 1;
  static const int tileNumberMax = 13;
  static const int copiesPerNormalTile = 2;
  static const int falseOkeyCount = 2;

  /// Sahte okey taşlarının fiziksel karşılığı yoktur (basılı sayısı
  /// bulunmaz); bu değer yalnızca [OkeyTile.number] alanının non-null
  /// kısıtını karşılamak için kullanılan bir yer tutucudur ve hiçbir kural
  /// hesaplamasında okunmaz (`isFalseOkey` her zaman joker olarak davranır).
  static const int falseOkeyPlaceholderNumber = 0;

  /// 4 renk * 13 sayı * 2 kopya + 2 sahte okey = 106 taş.
  static const int totalTileCount =
      tileColorCount * tileNumberMax * copiesPerNormalTile + falseOkeyCount;

  // --- Oyuncu ve dağıtım ---
  static const int playerCount = 4;
  static const int startingPlayerHandSize = 22;
  static const int otherPlayersHandSize = 21;
  static const int handSizeAfterDraw = 22;
  static const int handSizeAfterDiscard = 21;

  // --- Perler ---
  static const int minMeldSize = 3;
  static const int maxRunLength = tileNumberMax;
  static const int maxGroupSize = tileColorCount;

  // --- Açılış ---
  static const int defaultOpeningThreshold = 101;
  static const List<int> openingThresholdPresets = [51, 81, 101];

  // --- Çift açma ---
  static const int totalPairsInHand = 11;
  static const List<int> requiredPairCountPresets = [5, 6, 7];

  // --- Puanlama varsayılanları ---
  static const int defaultUnopenedPenaltyMultiplier = 2;
  static const int defaultOkeyRemainingPenalty = 25;
  static const int defaultFalseOkeyRemainingPenalty = 25;
  static const int defaultInvalidOpeningPenalty = 10;
  static const int defaultInvalidFinishPenalty = 20;
  static const int defaultOkeyFinishMultiplier = 2;
  static const int defaultPairFinishMultiplier = 2;
  static const int defaultHandFinishMultiplier = 4;
  static const int defaultMaxHandPenalty = 200;

  // --- Tur süresi ---
  static const List<int> turnDurationPresetsInSeconds = [15, 30, 45, 60];

  // --- Kayıt ---
  static const int currentSaveSchemaVersion = 1;

  const GameConstants._();
}
