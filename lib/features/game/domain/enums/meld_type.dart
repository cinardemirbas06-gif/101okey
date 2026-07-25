/// Geçerli per (kombinasyon) türleri.
enum MeldType {
  /// Aynı renkte, ardışık en az 3 taş (seri).
  run,

  /// Aynı numarada, farklı renklerden en az 3 taş (grup).
  group,

  /// Aynı renk ve numaradan iki fiziksel taş (çift açma kuralı için).
  pair,
}
