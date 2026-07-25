import '../../../../core/constants/game_constants.dart';
import '../entities/ai_visible_game_state.dart';
import '../entities/meld.dart';
import '../entities/okey_tile.dart';
import '../enums/ai_difficulty.dart';
import '../enums/ai_personality.dart';
import '../enums/meld_type.dart';
import '../rules/meld_validator.dart';
import 'hand_meld_finder.dart';

/// Kişilik bazlı ağırlık çarpanları (bkz. proje gereksinimleri #17).
final class _PersonalityWeights {
  const _PersonalityWeights({
    required this.keepValueMultiplier,
    required this.opponentRiskMultiplier,
    required this.jokerHoardBonus,
    this.preferredType,
  });

  final double keepValueMultiplier;
  final double opponentRiskMultiplier;
  final double jokerHoardBonus;
  final MeldType? preferredType;

  static _PersonalityWeights of(AiPersonality personality) {
    return switch (personality) {
      AiPersonality.cautious => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 1.5,
        jokerHoardBonus: 0,
      ),
      AiPersonality.aggressive => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 0.6,
        jokerHoardBonus: 0,
      ),
      AiPersonality.runFocused => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 1.0,
        jokerHoardBonus: 0,
        preferredType: MeldType.run,
      ),
      AiPersonality.groupFocused => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 1.0,
        jokerHoardBonus: 0,
        preferredType: MeldType.group,
      ),
      AiPersonality.okeyHoarder => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 1.0,
        jokerHoardBonus: 12.0,
      ),
      AiPersonality.fastOpener => const _PersonalityWeights(
        keepValueMultiplier: 1.2,
        opponentRiskMultiplier: 1.0,
        jokerHoardBonus: 0,
      ),
      AiPersonality.opponentTracker => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 1.3,
        jokerHoardBonus: 0,
      ),
      AiPersonality.riskTaker => const _PersonalityWeights(
        keepValueMultiplier: 1.0,
        opponentRiskMultiplier: 0.5,
        jokerHoardBonus: 0,
      ),
    };
  }
}

/// Bir tur içinde, elden atılacak en uygun taşı öneren heuristik motor.
///
/// **İşaret kuralı:** [scoreDiscardCandidate] "bu taşı atmanın ne kadar
/// iyi bir fikir olduğunu" döndürür — YÜKSEK skor = atmak için daha iyi
/// (daha güvenli / elde tutmaya daha az değer) aday demektir.
/// [chooseDiscard] eldeki tüm taşlar arasından en yüksek skorluyu seçer.
///
/// Zorluk seviyesi arttıkça: rakip risk analizi devreye girer (kolay
/// seviye bunu hiç hesaba katmaz), masaya oynanabilirlik ve görünür taş
/// sayımı daha ağırlıklı değerlendirilir.
abstract final class DiscardAdvisor {
  const DiscardAdvisor._();

  static OkeyTile chooseDiscard({
    required List<OkeyTile> hand,
    required AiVisibleGameState visibleState,
    required AiDifficulty difficulty,
    required AiPersonality personality,
  }) {
    assert(hand.isNotEmpty, 'Boş elden taş atılamaz.');

    OkeyTile? best;
    var bestScore = double.negativeInfinity;
    for (final tile in hand) {
      final score = scoreDiscardCandidate(
        tile: tile,
        hand: hand,
        visibleState: visibleState,
        difficulty: difficulty,
        personality: personality,
      );
      if (score > bestScore) {
        bestScore = score;
        best = tile;
      }
    }
    return best!;
  }

  static double scoreDiscardCandidate({
    required OkeyTile tile,
    required List<OkeyTile> hand,
    required AiVisibleGameState visibleState,
    required AiDifficulty difficulty,
    required AiPersonality personality,
  }) {
    final weights = _PersonalityWeights.of(personality);
    final candidates = HandMeldFinder.findAllCandidates(hand)
        .where((c) => c.containsTile(tile))
        .toList();

    // meldContribution + futurePotential + openingContribution: en iyi
    // adayın "elde tutma değeri" olarak birleştirilir.
    var keepValue = 0.0;
    for (final candidate in candidates) {
      final totalSlots = candidate.filledSlots + candidate.missingFromOutside;
      final completeness = totalSlots == 0
          ? 0.0
          : candidate.filledSlots / totalSlots;
      final urgencyWeight = candidate.isComplete
          ? 3.0
          : (candidate.missingFromOutside == 1 ? 2.0 : 1.0);
      var contribution =
          urgencyWeight * completeness * (candidate.potentialPoints / 10);
      if (weights.preferredType != null &&
          candidate.type == weights.preferredType) {
        contribution *= 1.3;
      }
      if (contribution > keepValue) keepValue = contribution;
    }
    keepValue *= weights.keepValueMultiplier;

    final isDeadTile = candidates.isEmpty;
    // deadTilePenalty (elde tutmanın cezası): tamamen işe yaramayan bir
    // taş, atmak için güvenli olduğundan discardScore'u YÜKSELTİR.
    final deadTileBonus = isDeadTile ? 10.0 : 0.0;
    // highValuePenalty: ölü taşlar arasında, yüksek sayılı olanı önce at
    // (elde kalırsa açılmamış oyuncu cezası daha büyük olur).
    final highValueBonus = isDeadTile ? tile.number * 0.1 : 0.0;

    var opponentRiskPenalty = 0.0;
    // Kolay AI rakip takibi yapmaz (bkz. proje gereksinimleri #17).
    if (difficulty != AiDifficulty.easy) {
      final anyOpponentOpened = visibleState.opponents.any(
        (o) => o.hasOpened,
      );
      if (anyOpponentOpened && _canExtendAnyTableMeld(tile, visibleState.tableMelds)) {
        opponentRiskPenalty += 8.0;
      }
      if (!tile.actsAsJoker) {
        final visibleCopies = _countVisibleCopies(tile, hand, visibleState);
        if (visibleCopies >= GameConstants.copiesPerNormalTile) {
          // Diğer kopya zaten görünürde/hesapta; kimse ikinci bir tane
          // isteyemez, bu taş güvenlidir.
          opponentRiskPenalty = 0;
        }
      }
      final difficultyWeight = switch (difficulty) {
        AiDifficulty.easy => 0.0,
        AiDifficulty.medium => 1.0,
        AiDifficulty.hard => 1.3,
        AiDifficulty.expert => 1.6,
      };
      opponentRiskPenalty *= difficultyWeight * weights.opponentRiskMultiplier;
    }

    final jokerHoardPenalty = tile.actsAsJoker ? weights.jokerHoardBonus : 0.0;

    return deadTileBonus +
        highValueBonus -
        keepValue -
        opponentRiskPenalty -
        jokerHoardPenalty;
  }

  static bool _canExtendAnyTableMeld(OkeyTile tile, List<Meld> tableMelds) {
    for (final meld in tableMelds) {
      if (meld.isLocked) continue;
      final rawTiles = meld.tiles.map((mt) => mt.tile).toList();
      if (meld.type == MeldType.run) {
        if (MeldValidator.validateRun([tile, ...rawTiles]).isValid) {
          return true;
        }
        if (MeldValidator.validateRun([...rawTiles, tile]).isValid) {
          return true;
        }
      } else if (meld.type == MeldType.group) {
        if (MeldValidator.validateGroup([...rawTiles, tile]).isValid) {
          return true;
        }
      }
    }
    return false;
  }

  static int _countVisibleCopies(
    OkeyTile tile,
    List<OkeyTile> hand,
    AiVisibleGameState visibleState,
  ) {
    bool matches(OkeyTile t) =>
        !t.actsAsJoker && t.color == tile.color && t.number == tile.number;

    var count = hand.where(matches).length;
    count += visibleState.discardHistory.where(matches).length;
    for (final meld in visibleState.tableMelds) {
      count += meld.tiles.where((mt) => matches(mt.tile)).length;
    }
    return count;
  }
}
