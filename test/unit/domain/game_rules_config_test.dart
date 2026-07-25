import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/scoring_rules.dart';

void main() {
  group('GameRulesConfig', () {
    test('varsayılan açılış eşiği 101\'dir', () {
      const rules = GameRulesConfig.standard;

      expect(rules.openingThreshold, 101);
      expect(rules.requiredPlayerCount, 4);
    });

    test('hazır profiller birbirinden farklı puanlama kuralları taşır', () {
      expect(
        GameRulesConfig.quick.scoringRules.maxHandPenalty,
        ScoringRules.quick.maxHandPenalty,
      );
      expect(
        GameRulesConfig.professional.scoringRules.unopenedPenaltyMultiplier,
        greaterThanOrEqualTo(
          GameRulesConfig.standard.scoringRules.unopenedPenaltyMultiplier,
        ),
      );
    });

    test('copyWith ile ev kuralı özelleştirilebilir', () {
      const base = GameRulesConfig.standard;
      final customized = base.copyWith(
        openingThreshold: 81,
        pairsEnabled: false,
      );

      expect(customized.openingThreshold, 81);
      expect(customized.pairsEnabled, isFalse);
      // Değiştirilmeyen alanlar korunur.
      expect(customized.requiredPairCount, base.requiredPairCount);
    });

    test('JSON round-trip tüm kural alanlarını korur', () {
      const rules = GameRulesConfig.professional;
      final json = rules.toJson();
      final restored = GameRulesConfig.fromJson(json);

      expect(restored, equals(rules));
    });
  });
}
