import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/game_phase.dart';
import 'meld.dart';
import 'okey_tile.dart';
import 'player.dart';

part 'game_state_snapshot.freezed.dart';
part 'game_state_snapshot.g.dart';

/// [GameState]'in hafif bir anlık görüntüsü.
///
/// Hamle geçmişi (`GameMove.before`/`GameMove.after`) için kullanılır.
/// Bilinçli olarak `GameState.moveHistory` alanını İÇERMEZ; aksi halde
/// her hamle kendi geçmişinin bir kopyasını taşır ve bellek kullanımı
/// katlanarak büyürdü.
@freezed
class GameStateSnapshot with _$GameStateSnapshot {
  const factory GameStateSnapshot({
    required GamePhase phase,
    required List<Player> players,
    required int activePlayerIndex,
    required int handNumber,
    required int turnNumber,
    required List<OkeyTile> drawPile,
    required List<OkeyTile> discardPile,
    required List<Meld> tableMelds,
    OkeyTile? indicatorTile,
    OkeyTile? okeyTile,
    @Default(false) bool hasDrawnThisTurn,
  }) = _GameStateSnapshot;

  factory GameStateSnapshot.fromJson(Map<String, dynamic> json) =>
      _$GameStateSnapshotFromJson(json);
}
