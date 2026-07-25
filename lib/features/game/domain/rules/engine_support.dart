import 'package:collection/collection.dart';

import '../../../../core/errors/game_exceptions.dart';
import '../entities/game_state.dart';
import '../entities/okey_tile.dart';
import '../entities/player.dart';
import '../enums/game_phase.dart';

/// [TurnEngine] ve [MeldEngine] arasında paylaşılan doğrulama ve state
/// güncelleme yardımcıları (kod tekrarını önlemek için tek noktada
/// toplanmıştır).
abstract final class GameEngineSupport {
  const GameEngineSupport._();

  static void assertPlayersTurn(GameState state, String playerId) {
    if (state.activePlayer.id != playerId) {
      throw NotPlayersTurnException(
        debugDetail: 'active=${state.activePlayer.id} requested=$playerId',
      );
    }
  }

  static void assertPhase(GameState state, Set<GamePhase> allowedPhases) {
    if (!allowedPhases.contains(state.phase)) {
      throw InvalidGamePhaseException(
        debugDetail: 'phase=${state.phase} allowed=$allowedPhases',
      );
    }
  }

  static Player findPlayer(GameState state, String playerId) {
    final player = state.players.firstWhereOrNull((p) => p.id == playerId);
    if (player == null) {
      throw InvalidActionException('Oyuncu bulunamadı: $playerId');
    }
    return player;
  }

  static List<Player> updatePlayerHand(
    List<Player> players,
    String playerId,
    List<OkeyTile> Function(List<OkeyTile> hand) update,
  ) {
    return [
      for (final p in players)
        if (p.id == playerId) p.copyWith(hand: update(p.hand)) else p,
    ];
  }

  static String playerName(GameState state, String playerId) =>
      findPlayer(state, playerId).name;

  static String tileLabel(OkeyTile tile) =>
      tile.isFalseOkey ? 'Sahte Okey' : '${tile.color.label} ${tile.number}';
}
