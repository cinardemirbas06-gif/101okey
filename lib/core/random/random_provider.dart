import 'dart:math';

/// Oyun motorunun rastgelelik ihtiyacı için soyutlanmış arayüz.
///
/// Bu soyutlama sayesinde testler sabit (seed'li) bir rastgelelik
/// kullanabilirken, üretim ortamında gerçek rastgelelik kullanılabilir.
abstract interface class RandomProvider {
  /// `[0, max)` aralığında bir tam sayı üretir.
  int nextInt(int max);

  /// Verilen listeyi yerinde (in place) karıştırır.
  void shuffle<T>(List<T> items);
}

/// Belirli bir seed ile başlatılan, tekrarlanabilir rastgelelik sağlayıcısı.
///
/// Aynı seed her zaman aynı taş dağılımını üretir; bu da unit testlerde ve
/// "eli tekrar izle" özelliğinde kullanılır.
final class SeededRandomProvider implements RandomProvider {
  SeededRandomProvider(this.seed) : _random = Random(seed);

  final int seed;
  final Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);

  @override
  void shuffle<T>(List<T> items) => items.shuffle(_random);
}

/// Üretim ortamında kullanılan, kriptografik olarak güvenli rastgelelik
/// sağlayıcısı.
final class SystemRandomProvider implements RandomProvider {
  SystemRandomProvider() : _random = Random.secure();

  final Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);

  @override
  void shuffle<T>(List<T> items) => items.shuffle(_random);
}
