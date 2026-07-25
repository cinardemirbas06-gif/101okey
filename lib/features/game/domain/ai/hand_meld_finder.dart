import '../../../../core/constants/game_constants.dart';
import '../entities/okey_tile.dart';
import '../enums/meld_type.dart';
import '../enums/tile_color.dart';

/// Bir elde bulunan, tamamlanmış veya tamamlanmaya yakın bir per adayı.
///
/// Bu, kesin bir per DOĞRULAMASI değil; AI'ın "hangi taşlar işime
/// yarayabilir" sorusuna heuristik bir yanıt vermesi için üretilen bir
/// candidate (aday)dır. Birden fazla aday aynı jokeri "kullanabilir"
/// olarak sayabilir (paylaşılan havuz varsayımı) — bu, kesin bir
/// tahsis değil, bir potansiyel değerlendirmesidir.
final class MeldCandidate {
  const MeldCandidate({
    required this.type,
    required this.naturalTiles,
    required this.jokersUsedFromHand,
    required this.missingFromOutside,
    required this.potentialPoints,
  });

  final MeldType type;

  /// Bu adaya katkı sağlayan, elde bulunan GERÇEK (joker olmayan) taşlar.
  final List<OkeyTile> naturalTiles;

  /// Bu adayı tamamlamak için elden kullanılacak (paylaşılan havuzdan)
  /// joker sayısı.
  final int jokersUsedFromHand;

  /// Bu aday tamamlanmadan önce dışarıdan (çekme/ortadan) gelmesi
  /// gereken taş sayısı; 0 ise aday elde TAMAMEN tamamlanabilir.
  final int missingFromOutside;

  /// Aday tamamlandığında toplam puan değeri.
  final int potentialPoints;

  int get filledSlots => naturalTiles.length + jokersUsedFromHand;

  bool get isComplete => missingFromOutside == 0;

  bool containsTile(OkeyTile tile) =>
      naturalTiles.any((t) => t.id == tile.id) ||
      (tile.actsAsJoker && jokersUsedFromHand > 0);
}

/// Bir eldeki olası seri ve grup adaylarını (tam veya eksik) bulan
/// heuristik motor.
///
/// Bu, per doğrulamadan (`MeldValidator`) farklıdır: kesin bir
/// geçerlilik kanıtı değil, AI'ın karar sürecinde kullanacağı "bu
/// taşlar bir araya gelebilir" tahminidir. Performans için tam bir
/// bitmask/DP arama yerine, renk/sayı bazlı doğrudan tarama kullanır
/// (21-22 taşlık bir el için yeterince hızlı ve pratik amaçlı yeterince
/// isabetlidir).
///
/// **Not (fiziksel kopyalar):** Her (renk, sayı) çiftinden en fazla 2
/// fiziksel kopya bulunabileceğinden, bir konum için iki kopya da elde
/// olduğunda o konumu dolduran adayın HER İKİ kopya seçeneğiyle de bir
/// varyantı üretilir. Bu sayede, iki farklı aday (örn. bir seri ve bir
/// grup) aynı sayı/renkteki FARKLI fiziksel taşları kullanarak aynı anda
/// seçilebilir.
abstract final class HandMeldFinder {
  const HandMeldFinder._();

  static List<MeldCandidate> findAllCandidates(List<OkeyTile> hand) {
    return [...findRunCandidates(hand), ...findGroupCandidates(hand)];
  }

  static List<MeldCandidate> findRunCandidates(List<OkeyTile> hand) {
    final jokerCount = hand.where((t) => t.actsAsJoker).length;
    final naturalsByColor = <TileColor, Map<int, List<OkeyTile>>>{};
    for (final tile in hand.where((t) => !t.actsAsJoker)) {
      naturalsByColor
          .putIfAbsent(tile.color, () => {})
          .putIfAbsent(tile.number, () => [])
          .add(tile);
    }

    final candidates = <MeldCandidate>[];
    for (final color in TileColor.values) {
      final naturals = naturalsByColor[color] ?? const {};
      if (naturals.isEmpty) continue;

      for (
        var length = GameConstants.minMeldSize;
        length <= GameConstants.maxRunLength;
        length++
      ) {
        for (
          var start = GameConstants.tileNumberMin;
          start + length - 1 <= GameConstants.tileNumberMax;
          start++
        ) {
          final slots = List<int>.generate(length, (i) => start + i);
          final filledSlots = [
            for (final n in slots)
              if (naturals[n] != null && naturals[n]!.isNotEmpty) naturals[n]!,
          ];
          if (filledSlots.isEmpty) continue;

          void addCandidate(List<OkeyTile> ownedTiles) {
            final missingSlots = length - ownedTiles.length;
            final jokersUsed = missingSlots < jokerCount
                ? missingSlots
                : jokerCount;
            final missingFromOutside = missingSlots - jokersUsed;
            candidates.add(
              MeldCandidate(
                type: MeldType.run,
                naturalTiles: ownedTiles,
                jokersUsedFromHand: jokersUsed,
                missingFromOutside: missingFromOutside,
                potentialPoints: slots.fold<int>(0, (sum, n) => sum + n),
              ),
            );
          }

          final baseOwned = [for (final copies in filledSlots) copies.first];
          addCandidate(baseOwned);

          final duplicateIndex = filledSlots.indexWhere(
            (copies) => copies.length > 1,
          );
          if (duplicateIndex != -1) {
            final altOwned = [...baseOwned];
            altOwned[duplicateIndex] = filledSlots[duplicateIndex][1];
            addCandidate(altOwned);
          }
        }
      }
    }
    return candidates;
  }

  static List<MeldCandidate> findGroupCandidates(List<OkeyTile> hand) {
    final jokerCount = hand.where((t) => t.actsAsJoker).length;
    final naturalsByNumber = <int, Map<TileColor, List<OkeyTile>>>{};
    for (final tile in hand.where((t) => !t.actsAsJoker)) {
      naturalsByNumber
          .putIfAbsent(tile.number, () => {})
          .putIfAbsent(tile.color, () => [])
          .add(tile);
    }

    final candidates = <MeldCandidate>[];
    for (
      var number = GameConstants.tileNumberMin;
      number <= GameConstants.tileNumberMax;
      number++
    ) {
      final owned = naturalsByNumber[number];
      if (owned == null || owned.isEmpty) continue;
      final ownedEntries = owned.entries.toList();

      for (final groupSize in [
        GameConstants.minMeldSize,
        GameConstants.maxGroupSize,
      ]) {
        final ownedCount = ownedEntries.length < groupSize
            ? ownedEntries.length
            : groupSize;
        if (ownedCount == 0) continue;
        final chosen = ownedEntries.take(ownedCount).toList();

        void addCandidate(List<OkeyTile> ownedTiles) {
          final missingSlots = groupSize - ownedCount;
          final jokersUsed = missingSlots < jokerCount
              ? missingSlots
              : jokerCount;
          final missingFromOutside = missingSlots - jokersUsed;
          candidates.add(
            MeldCandidate(
              type: MeldType.group,
              naturalTiles: ownedTiles,
              jokersUsedFromHand: jokersUsed,
              missingFromOutside: missingFromOutside,
              potentialPoints: number * groupSize,
            ),
          );
        }

        final baseOwned = [for (final entry in chosen) entry.value.first];
        addCandidate(baseOwned);

        final duplicateIndex = chosen.indexWhere(
          (entry) => entry.value.length > 1,
        );
        if (duplicateIndex != -1) {
          final altOwned = [...baseOwned];
          altOwned[duplicateIndex] = chosen[duplicateIndex].value[1];
          addCandidate(altOwned);
        }
      }
    }
    return candidates;
  }
}
