import '../entities/game_rules_config.dart';
import '../entities/okey_tile.dart';

/// Bir elde bulunan tek bir çifti temsil eder.
final class TilePair {
  const TilePair({required this.first, required this.second});

  final OkeyTile first;
  final OkeyTile second;

  /// Bu çiftte joker (okey/sahte okey) kullanılıp kullanılmadığı.
  bool get usesJoker => first.actsAsJoker || second.actsAsJoker;
}

/// [PairEvaluator.evaluate] sonucu.
final class PairEvaluationResult {
  const PairEvaluationResult({
    required this.pairs,
    required this.unpairedTiles,
  });

  final List<TilePair> pairs;
  final List<OkeyTile> unpairedTiles;

  int get pairCount => pairs.length;
}

/// Bir elin çift açma (bkz. proje gereksinimleri #11) için değerlendirmesi.
///
/// Çift açma, per doğrulamadan bağımsız bir hesaptır: tüm el taranır,
/// aynı renk+sayıdan doğal çiftler eşleştirilir; kalan tek taşlar,
/// [GameRulesConfig.pairJokerPolicy] izin veriyorsa jokerlerle
/// tamamlanır. Amaç, elde kurulabilecek EN FAZLA çift sayısını bulmaktır.
abstract final class PairEvaluator {
  const PairEvaluator._();

  static PairEvaluationResult evaluate(
    List<OkeyTile> hand, {
    required PairJokerPolicy jokerPolicy,
  }) {
    final naturals = <OkeyTile>[];
    final jokers = <OkeyTile>[];
    for (final tile in hand) {
      if (tile.actsAsJoker) {
        jokers.add(tile);
      } else {
        naturals.add(tile);
      }
    }

    // Aynı (renk, sayı) anahtarına sahip doğal taşları grupla.
    final groups = <String, List<OkeyTile>>{};
    for (final tile in naturals) {
      final key = '${tile.color.name}_${tile.number}';
      groups.putIfAbsent(key, () => []).add(tile);
    }

    final pairs = <TilePair>[];
    final leftoverSingles = <OkeyTile>[];
    for (final group in groups.values) {
      var i = 0;
      while (i + 1 < group.length) {
        pairs.add(TilePair(first: group[i], second: group[i + 1]));
        i += 2;
      }
      if (i < group.length) {
        leftoverSingles.add(group[i]);
      }
    }

    final availableJokers = List<OkeyTile>.of(jokers);
    final unpaired = <OkeyTile>[];

    switch (jokerPolicy) {
      case PairJokerPolicy.naturalOnly:
        unpaired
          ..addAll(leftoverSingles)
          ..addAll(availableJokers);

      case PairJokerPolicy.maxOne:
        var jokerBudget = availableJokers.isEmpty ? 0 : 1;
        for (final single in leftoverSingles) {
          if (jokerBudget > 0) {
            pairs.add(TilePair(first: single, second: availableJokers.removeAt(0)));
            jokerBudget--;
          } else {
            unpaired.add(single);
          }
        }
        unpaired.addAll(availableJokers);

      case PairJokerPolicy.unlimited:
        for (final single in leftoverSingles) {
          if (availableJokers.isNotEmpty) {
            pairs.add(
              TilePair(first: single, second: availableJokers.removeAt(0)),
            );
          } else {
            unpaired.add(single);
          }
        }
        // Kalan jokerler kendi aralarında da çift olabilir.
        while (availableJokers.length >= 2) {
          pairs.add(
            TilePair(
              first: availableJokers.removeAt(0),
              second: availableJokers.removeAt(0),
            ),
          );
        }
        unpaired.addAll(availableJokers);
    }

    return PairEvaluationResult(pairs: pairs, unpairedTiles: unpaired);
  }
}
