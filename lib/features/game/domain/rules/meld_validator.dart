import '../../../../core/constants/game_constants.dart';
import '../entities/meld_tile.dart';
import '../entities/okey_tile.dart';
import '../enums/meld_type.dart';
import '../enums/tile_color.dart';

/// [MeldValidator] tarafından üretilen doğrulama sonucu.
///
/// [isValid] false ise [reason] kullanıcıya gösterilecek Türkçe bir
/// açıklama içerir (bkz. proje gereksinimleri #12 örnek hata mesajları).
/// [isValid] true ise [resolvedTiles], jokerlerin ne temsil ettiği açıkça
/// çözülmüş (representedColor/representedNumber atanmış) taş listesidir.
final class MeldValidationResult {
  const MeldValidationResult._({
    required this.isValid,
    this.reason,
    this.type,
    this.resolvedTiles,
    this.points = 0,
  });

  const MeldValidationResult.invalid(String reason)
    : this._(isValid: false, reason: reason);

  const MeldValidationResult.valid({
    required MeldType type,
    required List<MeldTile> resolvedTiles,
    required int points,
  }) : this._(
         isValid: true,
         type: type,
         resolvedTiles: resolvedTiles,
         points: points,
       );

  final bool isValid;
  final String? reason;
  final MeldType? type;
  final List<MeldTile>? resolvedTiles;
  final int points;
}

/// Per (seri/grup) yapısal doğrulaması ve joker çözümlemesi.
///
/// **Tasarım kararı — seriler pozisyona bağlıdır:** [Meld.tiles] sıralı
/// bir listedir (fiziksel olarak soldan sağa dizilmiş taşları temsil
/// eder). Bu nedenle seri doğrulaması taşları bir KÜME değil, bir DİZİ
/// olarak ele alır: listedeki ilk normal (joker olmayan) taş referans
/// alınarak beklenen taban sayı hesaplanır, diğer tüm konumların bu
/// tabana göre tutarlı olup olmadığı denetlenir. Gruplarda ise sıra
/// önemsizdir; tüm normal taşların aynı sayıya ve birbirinden farklı
/// renklere sahip olması yeterlidir.
abstract final class MeldValidator {
  const MeldValidator._();

  /// [tiles] listesini önce seri, olmuyorsa grup olarak doğrulamayı
  /// dener. Her ikisi de geçersizse en açıklayıcı hatayı döndürür.
  static MeldValidationResult validate(
    List<OkeyTile> tiles, {
    bool wrapAroundRunsEnabled = false,
  }) {
    if (tiles.length < GameConstants.minMeldSize) {
      return MeldValidationResult.invalid(
        'Bu per en az ${GameConstants.minMeldSize} taştan oluşmalıdır.',
      );
    }

    final runResult = validateRun(
      tiles,
      wrapAroundRunsEnabled: wrapAroundRunsEnabled,
    );
    if (runResult.isValid) return runResult;

    final groupResult = validateGroup(tiles);
    if (groupResult.isValid) return groupResult;

    // İkisi de geçersizse, kullanıcıya daha anlamlı gelen hatayı seç:
    // taşlar aynı renkteyse muhtemelen seri denemesiydi, değilse grup.
    final nonJokers = tiles.where((t) => !t.actsAsJoker).toList();
    final looksLikeRunAttempt =
        nonJokers.isNotEmpty &&
        nonJokers.every((t) => t.color == nonJokers.first.color);
    return looksLikeRunAttempt ? runResult : groupResult;
  }

  /// Aynı renkte, ardışık en az 3 taştan oluşan seriyi doğrular.
  static MeldValidationResult validateRun(
    List<OkeyTile> tiles, {
    bool wrapAroundRunsEnabled = false,
  }) {
    if (tiles.length < GameConstants.minMeldSize) {
      return MeldValidationResult.invalid(
        'Bu per en az ${GameConstants.minMeldSize} taştan oluşmalıdır.',
      );
    }
    if (tiles.length > GameConstants.maxRunLength) {
      return MeldValidationResult.invalid(
        'Bir seri en fazla ${GameConstants.maxRunLength} taş içerebilir.',
      );
    }

    final nonJokerIndices = <int>[
      for (var i = 0; i < tiles.length; i++)
        if (!tiles[i].actsAsJoker) i,
    ];
    if (nonJokerIndices.isEmpty) {
      return const MeldValidationResult.invalid(
        'Bir seri, en az bir gerçek (joker olmayan) taş içermelidir.',
      );
    }

    final runColor = tiles[nonJokerIndices.first].color;
    for (final i in nonJokerIndices) {
      if (tiles[i].color != runColor) {
        return const MeldValidationResult.invalid(
          'Serideki tüm taşlar aynı renkte olmalıdır.',
        );
      }
    }

    // Her non-joker'ın işaret ettiği "0. konum" tabanını hesapla; hepsi
    // aynı tabana işaret etmiyorsa dizi ardışık değildir.
    int? baseNumber;
    for (final i in nonJokerIndices) {
      final impliedBase = wrapAroundRunsEnabled
          ? _wrapNumber(tiles[i].number - i)
          : tiles[i].number - i;
      baseNumber ??= impliedBase;
      if (impliedBase != baseNumber) {
        return const MeldValidationResult.invalid(
          'Bu taş serinin devamı değil.',
        );
      }
    }

    final resolved = <MeldTile>[];
    for (var i = 0; i < tiles.length; i++) {
      final rawNumber = baseNumber! + i;
      final int? positionNumber = wrapAroundRunsEnabled
          ? _wrapNumber(rawNumber)
          : (rawNumber >= GameConstants.tileNumberMin &&
                    rawNumber <= GameConstants.tileNumberMax
                ? rawNumber
                : null);
      if (positionNumber == null) {
        return const MeldValidationResult.invalid(
          'Seri 13\'ten sonra 1\'e sarmıyor (bu masada kapalı).',
        );
      }

      final tile = tiles[i];
      final isNatural = !tile.actsAsJoker;
      resolved.add(
        MeldTile(
          tile: tile,
          representedColor: isNatural ? null : runColor,
          representedNumber: isNatural ? null : positionNumber,
        ),
      );
    }

    final points = resolved.fold<int>(
      0,
      (sum, mt) => sum + mt.effectiveNumber,
    );
    return MeldValidationResult.valid(
      type: MeldType.run,
      resolvedTiles: resolved,
      points: points,
    );
  }

  /// Aynı sayıda, farklı renklerden en az 3 taştan oluşan grubu doğrular.
  static MeldValidationResult validateGroup(List<OkeyTile> tiles) {
    if (tiles.length < GameConstants.minMeldSize) {
      return MeldValidationResult.invalid(
        'Bu per en az ${GameConstants.minMeldSize} taştan oluşmalıdır.',
      );
    }
    if (tiles.length > GameConstants.maxGroupSize) {
      return MeldValidationResult.invalid(
        'Bir grup en fazla ${GameConstants.maxGroupSize} taş içerebilir '
        '(renk sayısı kadar).',
      );
    }

    final nonJokers = tiles.where((t) => !t.actsAsJoker).toList();
    final jokers = tiles.where((t) => t.actsAsJoker).toList();
    if (nonJokers.isEmpty) {
      return const MeldValidationResult.invalid(
        'Bir grup, en az bir gerçek (joker olmayan) taş içermelidir.',
      );
    }

    final groupNumber = nonJokers.first.number;
    final usedColors = <TileColor>{};
    for (final tile in nonJokers) {
      if (tile.number != groupNumber) {
        return const MeldValidationResult.invalid(
          'Gruptaki tüm taşlar aynı sayıda olmalıdır.',
        );
      }
      if (!usedColors.add(tile.color)) {
        return const MeldValidationResult.invalid(
          'Aynı renk grupta iki kez kullanılamaz.',
        );
      }
    }

    final availableColors = TileColor.values
        .where((c) => !usedColors.contains(c))
        .toList();
    if (jokers.length > availableColors.length) {
      return const MeldValidationResult.invalid(
        'Aynı renk grupta iki kez kullanılamaz.',
      );
    }

    final resolved = <MeldTile>[];
    var jokerColorCursor = 0;
    for (final tile in tiles) {
      if (tile.actsAsJoker) {
        final representedColor = availableColors[jokerColorCursor];
        jokerColorCursor++;
        resolved.add(
          MeldTile(
            tile: tile,
            representedColor: representedColor,
            representedNumber: groupNumber,
          ),
        );
      } else {
        resolved.add(MeldTile(tile: tile));
      }
    }

    final points = resolved.fold<int>(
      0,
      (sum, mt) => sum + mt.effectiveNumber,
    );
    return MeldValidationResult.valid(
      type: MeldType.group,
      resolvedTiles: resolved,
      points: points,
    );
  }

  static int _wrapNumber(int n) {
    final zeroBased = (n - GameConstants.tileNumberMin) % GameConstants.tileNumberMax;
    final normalized = zeroBased < 0
        ? zeroBased + GameConstants.tileNumberMax
        : zeroBased;
    return normalized + GameConstants.tileNumberMin;
  }
}
