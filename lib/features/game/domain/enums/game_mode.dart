/// Uygulamanın sunduğu oyun modları.
enum GameMode {
  /// Tek bir el oynanır, el bitince oyun sona erer.
  singleHand,

  /// Oyuncu durdurana kadar art arda eller oynanır.
  seriesGame,

  /// Önceden belirlenen sayıda el oynanır.
  fixedHandCount,

  /// Bir oyuncu hedef puana (veya üzerine) ulaşana kadar oynanır.
  targetScore,

  /// Kısaltılmış süre ve animasyonlarla hızlı oynanan mod.
  quickGame,

  /// Adım adım öğretici mod.
  tutorial,
}
