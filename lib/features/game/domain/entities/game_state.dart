import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finish_type.dart';
import '../enums/game_mode.dart';
import '../enums/game_phase.dart';
import '../enums/turn_direction.dart';
import 'game_move.dart';
import 'game_rules_config.dart';
import 'meld.dart';
import 'okey_tile.dart';
import 'player.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

/// Tüm oyunun tek, merkezi durumu (single source of truth).
///
/// UI ve AI dahil hiçbir katman kendi kopya durumunu tutmaz; her şey bu
/// yapıdan türetilir. `GameEngine`, gelen her [GameAction] için bu
/// durumun yeni (immutable) bir sürümünü üretir.
@freezed
class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    required String gameId,
    required int seed,
    required GameMode gameMode,
    required GameRulesConfig rules,
    required GamePhase phase,
    required List<Player> players,
    required int activePlayerIndex,
    required TurnDirection turnDirection,
    required int handNumber,
    required int turnNumber,
    required List<OkeyTile> drawPile,
    required List<OkeyTile> discardPile,
    OkeyTile? indicatorTile,
    OkeyTile? okeyTile,
    @Default(<Meld>[]) List<Meld> tableMelds,
    @Default(<GameMove>[]) List<GameMove> moveHistory,
    DateTime? turnStartedAt,
    @Default(false) bool hasDrawnThisTurn,
    @Default(false) bool hasDiscardedThisTurn,

    /// Aktif oyuncunun bu tur ortadan aldığı taşın kimliği (varsa).
    /// `DiscardTakePolicy` doğrulaması (Aşama 4, per işleme ile birlikte)
    /// bu alanı kullanır; tur değiştiğinde `null`'a sıfırlanır.
    String? tileTakenFromDiscardId,
    String? lastActionDescription,

    /// El bittiğinde (`GamePhase.calculatingScore`/`finished`) kazanan
    /// oyuncunun kimliği; berabere/sonuçsuz biten ellerde `null` kalır.
    String? winnerPlayerId,

    /// Elin nasıl bittiği (normal/okeyle/çiftten/elden). Kazanan yoksa
    /// (deste tükenmesiyle sonuçsuz biten el gibi) `null` kalır.
    FinishType? finishType,

    /// Hedef puan modunda oyunun biteceği puan; diğer modlarda null.
    int? targetScore,

    /// Belirlenen el sayısı modunda oynanacak toplam el; diğer modlarda
    /// null.
    int? fixedHandCount,

    /// Kayıt/geri yükleme uyumluluğu için şema sürümü.
    @Default(1) int saveSchemaVersion,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  Player get activePlayer => players[activePlayerIndex];

  int get remainingDeckCount => drawPile.length;

  OkeyTile? get currentDiscardTopTile =>
      discardPile.isEmpty ? null : discardPile.last;

  bool get isGameOver => phase == GamePhase.finished;
}
