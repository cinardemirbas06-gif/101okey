/// Ortadan (açık taş) alınan taşın kullanımına ilişkin masa kuralı.
enum DiscardTakePolicy {
  /// Alınan açık taş, aynı turda mutlaka kullanılmalıdır (bir perde
  /// işlenmeli veya elden atılmamalıdır).
  mustUseSameTurn,

  /// Açık taş alındığında o turda mutlaka per açılmalı veya işlenmelidir.
  mustMeldImmediately,

  /// Açık taş alınan oyuncu, taşı dilediği gibi (elinde tutarak dahil)
  /// kullanabilir.
  free,

  /// Yalnızca daha önce açılmış oyuncular açık taşı serbestçe kullanabilir;
  /// açılmamış oyuncular için [mustUseSameTurn] geçerlidir.
  freeForOpenedPlayers,
}
