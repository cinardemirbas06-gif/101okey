/// Aktif oyuncunun taş çektiği kaynak.
enum DrawSource {
  /// Kapalı çekme destesi.
  deck,

  /// Önceki oyuncunun attığı açık (ortadaki) taş.
  discardPile,
}
