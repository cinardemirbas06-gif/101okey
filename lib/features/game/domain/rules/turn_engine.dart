import 'package:collection/collection.dart';

import '../../../../core/errors/game_exceptions.dart';
import '../../../../core/random/random_provider.dart';
import '../entities/game_rules_config.dart';
import '../entities/game_state.dart';
import '../entities/okey_tile.dart';
import '../entities/player.dart';
import '../enums/game_phase.dart';
import '../enums/turn_direction.dart';
import '../services/tile_shuffler_service.dart';

/// Bir elin tur akışını (taş çekme, taş atma, sıranın ilerlemesi) yöneten
/// kural motoru.
///
/// **Kapsam notu:** Bu sınıf yalnızca çekme/atma/sıralama mekaniğinden
/// sorumludur. Per açma, masaya taş işleme ve okey değiştirme (Aşama 4'te
/// eklenecek per doğrulama motoruna bağımlı) burada YER ALMAZ; bu yüzden
/// [discardTile] taş atmayı `GamePhase.waitingForMeld` fazından da kabul
/// eder (melding her zaman opsiyoneldir ve henüz ayrı bir motor
/// tarafından işlenmemektedir).
///
/// Her metot, UI'dan gelen komutu doğrulayıp (sıra, faz, taş sahipliği)
/// ya yeni bir [GameState] döndürür ya da açıklayıcı bir [GameException]
/// fırlatır. Hiçbir doğrulama atlanmaz.
abstract final class TurnEngine {
  const TurnEngine._();

  /// Aktif oyuncu kapalı desteden taş çeker.
  ///
  /// Deste tükenmişse [GameRulesConfig.deckExhaustionPolicy]'e göre
  /// davranılır; bu durumda [random] yalnızca
  /// [DeckExhaustionPolicy.reshuffleDiscardPile] senaryosunda kullanılır.
  static GameState drawFromDeck(
    GameState state,
    String playerId, {
    required RandomProvider random,
  }) {
    _assertPlayersTurn(state, playerId);
    _assertPhase(state, const {GamePhase.waitingForDraw});
    if (state.hasDrawnThisTurn) {
      throw const InvalidGamePhaseException(
        debugDetail: 'Bu turda zaten taş çekildi.',
      );
    }

    if (state.drawPile.isEmpty) {
      return _handleDeckExhaustion(state, random);
    }

    final drawnTile = state.drawPile.last;
    final updatedPlayers = _updatePlayerHand(
      state.players,
      playerId,
      (hand) => [...hand, drawnTile],
    );

    return state.copyWith(
      players: updatedPlayers,
      drawPile: state.drawPile.sublist(0, state.drawPile.length - 1),
      hasDrawnThisTurn: true,
      tileTakenFromDiscardId: null,
      phase: GamePhase.waitingForMeld,
      lastActionDescription:
          '${_playerName(state, playerId)} desteden taş çekti.',
    );
  }

  /// Aktif oyuncu, önceki oyuncunun attığı açık (ortadaki) taşı alır.
  static GameState takeDiscardedTile(GameState state, String playerId) {
    _assertPlayersTurn(state, playerId);
    _assertPhase(state, const {GamePhase.waitingForDraw});
    if (state.hasDrawnThisTurn) {
      throw const InvalidGamePhaseException(
        debugDetail: 'Bu turda zaten taş çekildi.',
      );
    }
    if (state.discardPile.isEmpty) {
      throw const InvalidActionException('Ortada alınacak açık taş yok.');
    }

    final takenTile = state.discardPile.last;
    final updatedPlayers = _updatePlayerHand(
      state.players,
      playerId,
      (hand) => [...hand, takenTile],
    );

    return state.copyWith(
      players: updatedPlayers,
      discardPile: state.discardPile.sublist(0, state.discardPile.length - 1),
      hasDrawnThisTurn: true,
      tileTakenFromDiscardId: takenTile.id,
      phase: GamePhase.waitingForMeld,
      lastActionDescription:
          '${_playerName(state, playerId)} ortadaki '
          '${_tileLabel(takenTile)} taşını aldı.',
    );
  }

  /// Aktif oyuncu elinden bir taş atar; bu, mevcut turu bitirir ve sırayı
  /// bir sonraki oyuncuya geçirir.
  static GameState discardTile(GameState state, String playerId, String tileId) {
    _assertPlayersTurn(state, playerId);
    _assertPhase(state, const {
      GamePhase.waitingForMeld,
      GamePhase.waitingForDiscard,
    });
    if (!state.hasDrawnThisTurn) {
      throw const InvalidGamePhaseException(
        debugDetail: 'Taş atmadan önce taş çekilmeli.',
      );
    }

    final player = _findPlayer(state, playerId);
    final tile = player.hand.firstWhereOrNull((t) => t.id == tileId);
    if (tile == null) {
      throw const TileNotInHandException();
    }

    final updatedPlayers = _updatePlayerHand(
      state.players,
      playerId,
      (hand) => hand.where((t) => t.id != tileId).toList(growable: false),
    );

    final afterDiscard = state.copyWith(
      players: updatedPlayers,
      discardPile: [...state.discardPile, tile],
      hasDiscardedThisTurn: true,
      lastActionDescription:
          '${_playerName(state, playerId)} ${_tileLabel(tile)} attı.',
    );

    return _advanceTurn(afterDiscard);
  }

  /// Bir oyuncu ıstakasındaki taşların sırasını değiştirir. Taş kümesi
  /// (hangi fiziksel taşların elde olduğu) değişmeden kalmalıdır; bu
  /// nedenle oyuncunun sırası veya oyun fazı ile sınırlı değildir.
  static GameState rearrangeHand(
    GameState state,
    String playerId,
    List<String> orderedTileIds,
  ) {
    final player = _findPlayer(state, playerId);

    final currentIds = player.hand.map((t) => t.id).toSet();
    final requestedIds = orderedTileIds.toSet();
    if (currentIds.length != orderedTileIds.length ||
        currentIds.length != requestedIds.length ||
        !currentIds.containsAll(requestedIds)) {
      throw const InvalidActionException(
        'Istaka yeniden sıralanamadı: taş kümesi değişmemeli.',
      );
    }

    final tilesById = {for (final t in player.hand) t.id: t};
    final reordered = orderedTileIds
        .map((id) => tilesById[id]!)
        .toList(growable: false);

    return state.copyWith(
      players: _updatePlayerHand(state.players, playerId, (_) => reordered),
    );
  }

  // --- Yardımcılar --------------------------------------------------------

  static GameState _advanceTurn(GameState afterDiscard) {
    final playerCount = afterDiscard.players.length;
    // Oyuncu listesi masada saat yönünde oturma sırasını temsil eder;
    // TurnDirection.clockwise index'i artırır, counterClockwise azaltır.
    final step = afterDiscard.turnDirection == TurnDirection.clockwise
        ? 1
        : -1;
    final nextIndex =
        (afterDiscard.activePlayerIndex + step + playerCount) % playerCount;

    return afterDiscard.copyWith(
      activePlayerIndex: nextIndex,
      turnNumber: afterDiscard.turnNumber + 1,
      hasDrawnThisTurn: false,
      hasDiscardedThisTurn: false,
      tileTakenFromDiscardId: null,
      phase: GamePhase.waitingForDraw,
      turnStartedAt: DateTime.now(),
    );
  }

  static GameState _handleDeckExhaustion(
    GameState state,
    RandomProvider random,
  ) {
    switch (state.rules.deckExhaustionPolicy) {
      case DeckExhaustionPolicy.reshuffleDiscardPile:
        // Ortadaki son atılan taş masada görünür kalmalı; onun dışındaki
        // atılan taşlar yeni çekme destesi olarak karıştırılır.
        if (state.discardPile.length <= 1) {
          return state.copyWith(
            phase: GamePhase.finished,
            lastActionDescription:
                'Çekme destesi tükendi ve yeniden karıştırılacak taş yok. '
                'El sonuçsuz kaldı.',
          );
        }
        final topTile = state.discardPile.last;
        final toReshuffle = state.discardPile.sublist(
          0,
          state.discardPile.length - 1,
        );
        final reshuffled = TileShufflerService.shuffle(toReshuffle, random);
        return state.copyWith(
          drawPile: reshuffled,
          discardPile: [topTile],
          lastActionDescription:
              'Çekme destesi tükendi, atılan taşlar yeniden karıştırıldı.',
        );

      case DeckExhaustionPolicy.handIsDraw:
      case DeckExhaustionPolicy.awardToLowestHandValue:
        return state.copyWith(
          phase: GamePhase.finished,
          lastActionDescription: 'Çekme destesi tükendi, el sona erdi.',
        );
    }
  }

  static void _assertPlayersTurn(GameState state, String playerId) {
    if (state.activePlayer.id != playerId) {
      throw NotPlayersTurnException(
        debugDetail: 'active=${state.activePlayer.id} requested=$playerId',
      );
    }
  }

  static void _assertPhase(GameState state, Set<GamePhase> allowedPhases) {
    if (!allowedPhases.contains(state.phase)) {
      throw InvalidGamePhaseException(
        debugDetail: 'phase=${state.phase} allowed=$allowedPhases',
      );
    }
  }

  static Player _findPlayer(GameState state, String playerId) {
    final player = state.players.firstWhereOrNull((p) => p.id == playerId);
    if (player == null) {
      throw InvalidActionException('Oyuncu bulunamadı: $playerId');
    }
    return player;
  }

  static List<Player> _updatePlayerHand(
    List<Player> players,
    String playerId,
    List<OkeyTile> Function(List<OkeyTile> hand) update,
  ) {
    return [
      for (final p in players)
        if (p.id == playerId) p.copyWith(hand: update(p.hand)) else p,
    ];
  }

  static String _playerName(GameState state, String playerId) =>
      _findPlayer(state, playerId).name;

  static String _tileLabel(OkeyTile tile) =>
      tile.isFalseOkey ? 'Sahte Okey' : '${tile.color.label} ${tile.number}';
}
