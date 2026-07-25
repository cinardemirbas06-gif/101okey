import '../../../../core/random/random_provider.dart';
import '../entities/okey_tile.dart';

/// Taş listelerini [RandomProvider] üzerinden karıştıran, test edilebilir
/// ince bir servis.
abstract final class TileShufflerService {
  const TileShufflerService._();

  /// [tiles] listesinin karıştırılmış YENİ bir kopyasını döndürür; girdi
  /// listesi değiştirilmez.
  static List<OkeyTile> shuffle(List<OkeyTile> tiles, RandomProvider random) {
    final shuffled = List<OkeyTile>.of(tiles);
    random.shuffle(shuffled);
    return shuffled;
  }
}
