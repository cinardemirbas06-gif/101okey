/// Bir elin geçirdiği aşamalar.
enum GamePhase {
  /// Oyun kurulumu hazırlanıyor (oyuncular, kurallar, deste).
  preparing,

  /// Taşlar oyunculara dağıtılıyor (animasyonlu).
  dealing,

  /// Aktif oyuncunun taş çekmesi bekleniyor.
  waitingForDraw,

  /// Aktif oyuncunun per açması / masaya taş işlemesi bekleniyor.
  waitingForMeld,

  /// Aktif oyuncunun taş atması bekleniyor.
  waitingForDiscard,

  /// El bitti, puanlar hesaplanıyor.
  calculatingScore,

  /// El tamamen bitti, sonuç ekranı gösteriliyor.
  finished,
}
