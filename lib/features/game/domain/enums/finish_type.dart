/// Bir elin bitiriliş türü. Puanlama motoru çarpanları buna göre uygular.
enum FinishType {
  /// Standart bitiş: son taş perlere işlenerek veya atılarak el bitirilir.
  normal,

  /// Son taş olarak okey atılarak / okeyle bitirme.
  okeyFinish,

  /// Çift açan oyuncunun elindeki tüm taşları çift olarak bitirmesi.
  pairFinish,

  /// Hiç per açmadan, tüm eli tek seferde masaya koyarak bitirme.
  handFinish,

  /// Ev kuralına göre gösterge taşıyla bitirme gibi özel bitişler.
  indicatorFinish,
}
