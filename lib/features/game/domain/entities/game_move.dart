import 'package:freezed_annotation/freezed_annotation.dart';

import 'game_action.dart';
import 'game_state_snapshot.dart';

part 'game_move.freezed.dart';
part 'game_move.g.dart';

/// Oynanan tek bir hamlenin, geri alma ve geliştirici modu hamle geçmişi
/// (bkz. bölüm 34) için gereken tam kaydı.
@freezed
class GameMove with _$GameMove {
  const factory GameMove({
    required String id,
    required String playerId,
    required GameAction action,
    required DateTime timestamp,
    required GameStateSnapshot before,
    required GameStateSnapshot after,

    /// Bu hamle, oyuncunun kendi turu bitmeden geri alınabilir mi.
    @Default(false) bool isUndoable,
  }) = _GameMove;

  factory GameMove.fromJson(Map<String, dynamic> json) =>
      _$GameMoveFromJson(json);
}
