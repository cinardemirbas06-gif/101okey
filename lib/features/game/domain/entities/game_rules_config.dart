import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/utils/duration_json_converter.dart';
import '../enums/discard_take_policy.dart';
import 'scoring_rules.dart';

part 'game_rules_config.freezed.dart';
part 'game_rules_config.g.dart';

/// Bir masada geçerli olan tüm "ev kuralları". 101 Okey kuralları
/// bölgeden bölgeye değiştiği için sistem hiçbir kuralı sabit kod
/// içine gömmez; kural motoru (`rules engine`) her zaman bu yapı
/// üzerinden çalışır.
@freezed
class GameRulesConfig with _$GameRulesConfig {
  const GameRulesConfig._();

  const factory GameRulesConfig({
    // --- Açılış ---
    @Default(GameConstants.defaultOpeningThreshold) int openingThreshold,

    // --- Çift açma ---
    @Default(true) bool pairsEnabled,
    @Default(7) int requiredPairCount,
    @Default(PairJokerPolicy.unlimited) PairJokerPolicy pairJokerPolicy,

    // --- Seri kuralları ---
    /// 12-13-1 gibi "sarma" (wrap-around) serilere izin verilsin mi.
    @Default(false) bool wrapAroundRunsEnabled,

    // --- Okey ---
    /// Masadaki bir okeyin, gerçek taşla değiştirilebilmesi.
    @Default(true) bool jokerSwapEnabled,

    // --- Tur akışı ---
    @Default(false) bool allowOpenAndFinishSameTurn,
    @Default(true) bool allowRearrangingTableMelds,
    @Default(true) bool allowSplittingTableMelds,
    @Default(DiscardTakePolicy.freeForOpenedPlayers)
    DiscardTakePolicy discardTakePolicy,
    @Default(false) bool meldingRequiredBeforeOpening,

    // --- Bitme türleri ---
    @Default(true) bool okeyFinishEnabled,
    @Default(true) bool pairFinishEnabled,
    @Default(true) bool handFinishEnabled,
    @Default(false) bool indicatorFinishEnabled,

    // --- Tur süresi ---
    @DurationJsonConverter()
    @Default(Duration(seconds: 30))
    Duration turnDuration,
    @Default(true) bool timerEnabled,
    @Default(true) bool autoDrawOnTimeout,
    @Default(true) bool autoDiscardLowestRiskOnTimeout,

    // --- Deste bitişi ---
    @Default(DeckExhaustionPolicy.handIsDraw) DeckExhaustionPolicy
        deckExhaustionPolicy,

    // --- Gösterge bonusu ---
    @Default(false) bool indicatorBonusEnabled,
    @Default(0) int indicatorBonusPoints,

    // --- Masa büyüklüğü ---
    @Default(GameConstants.playerCount) int requiredPlayerCount,

    // --- Puanlama ---
    @Default(ScoringRules.standard) ScoringRules scoringRules,
  }) = _GameRulesConfig;

  factory GameRulesConfig.fromJson(Map<String, dynamic> json) =>
      _$GameRulesConfigFromJson(json);

  /// Standart / varsayılan ev kuralları seti.
  static const standard = GameRulesConfig();

  /// Hızlı oyun için kısaltılmış süre ve basitleştirilmiş kurallar.
  static const quick = GameRulesConfig(
    turnDuration: Duration(seconds: 15),
    scoringRules: ScoringRules.quick,
  );

  /// "Profesyonel" ev kuralı: daha katı kısıtlamalar.
  static const professional = GameRulesConfig(
    requiredPairCount: 6,
    pairJokerPolicy: PairJokerPolicy.maxOne,
    discardTakePolicy: DiscardTakePolicy.mustMeldImmediately,
    allowRearrangingTableMelds: false,
    scoringRules: ScoringRules.harshPenalty,
  );
}

/// Çift açmada okey kullanımının nasıl sınırlandırılacağı.
enum PairJokerPolicy {
  /// Yalnızca doğal (fiziksel) çiftler kabul edilir, okey kullanılamaz.
  naturalOnly,

  /// Bir çiftte en fazla 1 okey kullanılabilir.
  maxOne,

  /// Sınırsız sayıda okey çift tamamlamak için kullanılabilir.
  unlimited,
}

/// Çekme destesi tükendiğinde uygulanacak davranış.
enum DeckExhaustionPolicy {
  /// El berabere/sonuçsuz sayılır, kimse kazanmaz.
  handIsDraw,

  /// El, elinde en az taş kalan (en düşük puanlı) oyuncuya verilir.
  awardToLowestHandValue,

  /// Atılan taşlar (son atılan hariç) karıştırılıp yeni deste oluşturulur.
  reshuffleDiscardPile,
}
