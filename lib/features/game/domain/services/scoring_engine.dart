import 'dart:math';

import '../entities/game_rules_config.dart';
import '../entities/game_state.dart';
import '../entities/hand_score_result.dart';
import '../entities/player.dart';
import '../entities/player_hand_score.dart';
import '../entities/scoring_rules.dart';
import '../enums/finish_type.dart';

/// Bir elin sonunda tüm oyuncuların puanlarını hesaplayan, tamamen
/// yapılandırılabilir puanlama motoru.
///
/// Hiçbir ceza/çarpan değeri kod içine sabitlenmez; her şey
/// [GameRulesConfig.scoringRules] üzerinden okunur (bkz. proje
/// gereksinimleri #22). Bu motor [GameState]'i DEĞİŞTİRMEZ, yalnızca
/// bir [HandScoreResult] üretir; state'e uygulanması (seri puanına
/// eklenmesi) çağıran tarafın sorumluluğundadır.
///
/// Hesaplama modeli (varsayılan/standart profille):
/// - Kazanan, kaybeden oyuncuların ödediği toplam cezayı sıfır-toplamlı
///   biçimde kazanır (`finishBonus`).
/// - Her kaybeden için: `(eldeki taşların sayı değerleri toplamı ×
///   açılmamış oyuncu çarpanı + okey/sahte-okey sabit cezaları) ×
///   bitiş türü çarpanı`, `maxHandPenalty` ile sınırlanır.
abstract final class ScoringEngine {
  const ScoringEngine._();

  static HandScoreResult calculate(GameState state) {
    final rules = state.rules.scoringRules;
    final resolvedWinnerId = state.winnerPlayerId ?? _resolveDeckExhaustionWinner(state);
    final finishType = state.finishType ?? FinishType.normal;

    final finishMultiplier = resolvedWinnerId == null
        ? 1
        : switch (finishType) {
            FinishType.okeyFinish => rules.okeyFinishMultiplier,
            FinishType.pairFinish => rules.pairFinishMultiplier,
            FinishType.handFinish => rules.handFinishMultiplier,
            FinishType.normal || FinishType.indicatorFinish => 1,
          };

    final loserScores = <PlayerHandScore>[
      for (final player in state.players)
        if (player.id != resolvedWinnerId)
          _scoreNonWinner(player, rules, finishMultiplier),
    ];

    final playerScores = <PlayerHandScore>[...loserScores];
    if (resolvedWinnerId != null) {
      final winner = state.players.firstWhere((p) => p.id == resolvedWinnerId);
      final collected = loserScores.fold<int>(
        0,
        (sum, s) => sum + s.totalPenalty,
      );
      playerScores.add(
        PlayerHandScore(
          playerId: winner.id,
          remainingTileCount: winner.hand.length,
          remainingTileValue: 0,
          wasOpened: winner.hasOpened,
          penaltyMultiplier: 1,
          finishBonus: collected,
          totalPenalty: 0,
          roundScoreDelta: collected,
        ),
      );
    }

    return HandScoreResult(
      handNumber: state.handNumber,
      winnerPlayerId: resolvedWinnerId,
      finishType: finishType,
      playerScores: playerScores,
    );
  }

  static PlayerHandScore _scoreNonWinner(
    Player player,
    ScoringRules rules,
    int finishMultiplier,
  ) {
    // Okey/sahte okey taşlarının yüz değeri "elde kalan taşlar" toplamına
    // dahil edilmez; bunlar yerine aşağıdaki sabit okey cezaları uygulanır
    // (bkz. proje gereksinimleri #22 örnek dökümü: "Elde kalan taşlar" ve
    // "Elde kalan okey cezası" ayrı kalemlerdir).
    final remainingTileValue = player.hand
        .where((t) => !t.actsAsJoker)
        .fold<int>(0, (sum, t) => sum + t.number);
    final okeyCount = player.hand.where((t) => t.isOkey).length;
    final falseOkeyCount = player.hand.where((t) => t.isFalseOkey).length;

    final unopenedMultiplier = player.hasOpened
        ? 1
        : rules.unopenedPenaltyMultiplier;
    final okeyPenalty = okeyCount * rules.okeyRemainingPenalty;
    final falseOkeyPenalty = falseOkeyCount * rules.falseOkeyRemainingPenalty;

    final baseTotal =
        (remainingTileValue * unopenedMultiplier) +
        okeyPenalty +
        falseOkeyPenalty;
    final totalPenalty = min(baseTotal * finishMultiplier, rules.maxHandPenalty);

    return PlayerHandScore(
      playerId: player.id,
      remainingTileCount: player.hand.length,
      remainingTileValue: remainingTileValue,
      wasOpened: player.hasOpened,
      penaltyMultiplier: unopenedMultiplier * finishMultiplier,
      okeyRemainingPenalty: okeyPenalty,
      falseOkeyRemainingPenalty: falseOkeyPenalty,
      totalPenalty: totalPenalty,
      roundScoreDelta: -totalPenalty,
    );
  }

  /// [DeckExhaustionPolicy.awardToLowestHandValue] kuralında, elinde en
  /// düşük toplam sayı değeri kalan oyuncuyu kazanan ilan eder.
  /// [DeckExhaustionPolicy.handIsDraw] (veya kazanan zaten belirliyse)
  /// `null` döner.
  static String? _resolveDeckExhaustionWinner(GameState state) {
    if (state.rules.deckExhaustionPolicy !=
        DeckExhaustionPolicy.awardToLowestHandValue) {
      return null;
    }

    Player? lowest;
    var lowestValue = 1 << 30;
    for (final player in state.players) {
      final value = player.hand.fold<int>(0, (sum, t) => sum + t.number);
      if (value < lowestValue) {
        lowestValue = value;
        lowest = player;
      }
    }
    return lowest?.id;
  }
}
