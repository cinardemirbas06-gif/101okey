/// Bir taşın türü.
enum TileType {
  /// 1-13 arası numaralı, renkli standart taş.
  normal,

  /// Gösterge taşına göre belirlenen, joker olarak kullanılabilen taş.
  okey,

  /// Her zaman "sahte okey" olan, seçilen okeyin normal değerini temsil
  /// eden 2 özel taştan biri.
  falseOkey,
}
