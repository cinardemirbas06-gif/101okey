import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_hand_score.freezed.dart';
part 'player_hand_score.g.dart';

/// Bir oyuncunun tek bir eldeki puan hesabının kalem kalem dökümü.
///
/// UI, örneğin: "Elde kalan taşlar: 42, Açmamış oyuncu çarpanı: x2,
/// Elde kalan okey cezası: +25, Toplam ceza: 109" gibi bir görünüm
/// oluşturmak için bu alanları doğrudan kullanır.
@freezed
class PlayerHandScore with _$PlayerHandScore {
  const factory PlayerHandScore({
    required String playerId,
    required int remainingTileCount,
    required int remainingTileValue,
    required bool wasOpened,
    required int penaltyMultiplier,
    @Default(0) int okeyRemainingPenalty,
    @Default(0) int falseOkeyRemainingPenalty,
    @Default(0) int invalidOpeningPenalty,
    @Default(0) int invalidFinishPenalty,
    @Default(0) int unusedTakenDiscardPenalty,
    @Default(0) int invalidTablePlacementPenalty,
    @Default(0) int finishBonus,
    required int totalPenalty,

    /// Bu elin seri toplam skoruna eklediği net değişim
    /// (kazanan için negatif/pozitif, kurallara göre değişir).
    required int roundScoreDelta,
  }) = _PlayerHandScore;

  factory PlayerHandScore.fromJson(Map<String, dynamic> json) =>
      _$PlayerHandScoreFromJson(json);
}
