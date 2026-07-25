/// 101 Okey taşlarında kullanılan 4 renk.
///
/// Bu enum bilinçli olarak Flutter UI katmanından (dart:ui `Color`)
/// bağımsızdır; domain katmanı UI'a bağımlı olmamalıdır. Görsel renk
/// eşlemesi `app/theme` katmanında yapılır.
enum TileColor {
  red('Kırmızı', '●'),
  black('Siyah', '■'),
  blue('Mavi', '▲'),
  yellow('Sarı', '◆');

  const TileColor(this.label, this.colorBlindSymbol);

  /// Türkçe görünen ad.
  final String label;

  /// Renk körlüğü modunda rengin yanında gösterilecek ayırt edici sembol.
  final String colorBlindSymbol;
}
