import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/game_constants.dart';
import '../enums/scoring_profile.dart';

part 'scoring_rules.freezed.dart';
part 'scoring_rules.g.dart';

/// Bir elin sonunda uygulanacak tüm ceza/çarpan değerlerini taşıyan,
/// tamamen yapılandırılabilir puanlama seti.
///
/// Bu değerler asla kod içine sabitlenmez; `PuanlamaMotoru`
/// (`ScoringEngine`) her zaman bir [ScoringRules] örneği üzerinden çalışır.
@freezed
class ScoringRules with _$ScoringRules {
  const factory ScoringRules({
    /// Açılmamış oyuncunun elinde kalan taş puanına uygulanan çarpan.
    @Default(GameConstants.defaultUnopenedPenaltyMultiplier)
    int unopenedPenaltyMultiplier,

    /// Elde kalan her okey için ek ceza puanı.
    @Default(GameConstants.defaultOkeyRemainingPenalty)
    int okeyRemainingPenalty,

    /// Elde kalan her sahte okey için ek ceza puanı.
    @Default(GameConstants.defaultFalseOkeyRemainingPenalty)
    int falseOkeyRemainingPenalty,

    /// Geçersiz bir açılış denemesi tespit edildiğinde uygulanan ceza.
    @Default(GameConstants.defaultInvalidOpeningPenalty)
    int invalidOpeningPenalty,

    /// Geçersiz bir bitiş denemesi tespit edildiğinde uygulanan ceza.
    @Default(GameConstants.defaultInvalidFinishPenalty)
    int invalidFinishPenalty,

    /// Son taş olarak okey atarak bitirmenin kazanç çarpanı.
    @Default(GameConstants.defaultOkeyFinishMultiplier)
    int okeyFinishMultiplier,

    /// Çiftten bitirmenin kazanç çarpanı.
    @Default(GameConstants.defaultPairFinishMultiplier)
    int pairFinishMultiplier,

    /// Elden (hiç açmadan) bitirmenin kazanç çarpanı.
    @Default(GameConstants.defaultHandFinishMultiplier)
    int handFinishMultiplier,

    /// Bir oyuncunun bir elde alabileceği en yüksek ceza puanı (üst sınır).
    @Default(GameConstants.defaultMaxHandPenalty) int maxHandPenalty,

    /// Yerden alınan taşı zorunlu kullanmama cezası (0 = kapalı).
    @Default(0) int unusedTakenDiscardPenalty,

    /// Masaya kural dışı taş bırakma denemesi cezası (0 = kapalı).
    @Default(0) int invalidTablePlacementPenalty,

    /// Bu seti tanımlayan hazır profil (UI'da seçim göstermek için).
    @Default(ScoringProfile.standard) ScoringProfile profile,
  }) = _ScoringRules;

  factory ScoringRules.fromJson(Map<String, dynamic> json) =>
      _$ScoringRulesFromJson(json);

  /// Standart 101 Okey puanlama profili.
  static const standard = ScoringRules();

  /// Klasik (daha düşük ceza) ev kuralı profili.
  static const classic = ScoringRules(
    unopenedPenaltyMultiplier: 1,
    okeyRemainingPenalty: 20,
    falseOkeyRemainingPenalty: 20,
    profile: ScoringProfile.classic,
  );

  /// Hızlı oyun için basitleştirilmiş, düşük cezalı profil.
  static const quick = ScoringRules(
    unopenedPenaltyMultiplier: 1,
    okeyRemainingPenalty: 15,
    falseOkeyRemainingPenalty: 15,
    maxHandPenalty: 120,
    profile: ScoringProfile.quick,
  );

  /// Sert ceza profili: yanlış hamle ve açılmama ağır cezalandırılır.
  static const harshPenalty = ScoringRules(
    unopenedPenaltyMultiplier: 3,
    okeyRemainingPenalty: 35,
    falseOkeyRemainingPenalty: 35,
    invalidOpeningPenalty: 20,
    invalidFinishPenalty: 40,
    maxHandPenalty: 300,
    profile: ScoringProfile.harshPenalty,
  );
}
