import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finish_type.dart';
import 'player_hand_score.dart';

part 'hand_score_result.freezed.dart';
part 'hand_score_result.g.dart';

/// Bir elin sonunda `ScoringEngine` tarafından üretilen tam sonuç.
@freezed
class HandScoreResult with _$HandScoreResult {
  const factory HandScoreResult({
    required int handNumber,

    /// Kazanan oyuncunun kimliği; deste tükenmesiyle sonuçsuz/berabere
    /// biten ellerde (bkz. `DeckExhaustionPolicy.handIsDraw`) `null`dır.
    String? winnerPlayerId,
    required FinishType finishType,
    required List<PlayerHandScore> playerScores,
  }) = _HandScoreResult;

  factory HandScoreResult.fromJson(Map<String, dynamic> json) =>
      _$HandScoreResultFromJson(json);
}
