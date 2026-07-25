import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../entities/game_rules_config.dart';
import '../entities/meld.dart';
import '../entities/meld_tile.dart';
import '../entities/okey_tile.dart';
import '../enums/meld_type.dart';

/// [MeldEngine] (çiftten açılış) ve [FinishEngine] (çiftten bitirme)
/// arasında paylaşılan çift doğrulama ve per oluşturma yardımcıları.
abstract final class PairMeldSupport {
  const PairMeldSupport._();

  /// Önerilen çift gruplarının yapısal olarak geçerli olup olmadığını
  /// kontrol eder; geçersizse hata mesajını, geçerliyse `null` döndürür.
  static String? validateProposedPairGroups(
    List<List<OkeyTile>> groups,
    PairJokerPolicy policy,
  ) {
    var jokerBudget = switch (policy) {
      PairJokerPolicy.naturalOnly => 0,
      PairJokerPolicy.maxOne => 1,
      PairJokerPolicy.unlimited => 1 << 30,
    };

    for (final group in groups) {
      if (group.length != 2) {
        return 'Her çift tam olarak 2 taştan oluşmalıdır.';
      }
      final jokerCount = group.where((t) => t.actsAsJoker).length;
      if (jokerCount == 0) {
        final a = group[0];
        final b = group[1];
        if (a.color != b.color || a.number != b.number) {
          return 'Çift, aynı renk ve sayıdan iki taştan oluşmalıdır.';
        }
      } else {
        if (jokerCount > jokerBudget) {
          return 'Bu masada çiftte kullanılabilecek okey sayısı aşıldı.';
        }
        jokerBudget -= jokerCount;
      }
    }
    return null;
  }

  static Meld buildPairMeld(String playerId, List<OkeyTile> pairTiles) {
    final natural = pairTiles.where((t) => !t.actsAsJoker).firstOrNull;
    final resolvedTiles = pairTiles.map((t) {
      if (!t.actsAsJoker) return MeldTile(tile: t);
      return MeldTile(
        tile: t,
        representedColor: natural?.color,
        representedNumber: natural?.number,
      );
    }).toList();

    return Meld(
      id: const Uuid().v4(),
      type: MeldType.pair,
      openedByPlayerId: playerId,
      tiles: resolvedTiles,
    );
  }
}
