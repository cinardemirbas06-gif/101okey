import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/game_exceptions.dart';
import '../entities/game_rules_config.dart';
import '../entities/game_state.dart';
import '../entities/meld.dart';
import '../entities/meld_tile.dart';
import '../entities/okey_tile.dart';
import '../entities/player.dart';
import '../enums/game_phase.dart';
import '../enums/meld_type.dart';
import 'engine_support.dart';
import 'meld_validator.dart';
import 'opening_score_calculator.dart';

const _uuid = Uuid();

/// Per açma, masaya taş işleme ve okey değiştirmeyi yöneten kural motoru.
///
/// **Kapsam notu:** Taş çekme/atma/sıra ilerletme [TurnEngine]'de,
/// bitirme/puanlama ayrı bir motorda (sonraki aşama) ele alınır. Bu
/// sınıf yalnızca [GameAction.openMelds], [GameAction.addTileToMeld] ve
/// [GameAction.swapTileWithTableOkey] komutlarını işler.
abstract final class MeldEngine {
  const MeldEngine._();

  /// Bir oyuncunun ilk açılış denemesi.
  ///
  /// [tileGroups] her biri iki taşsa VE [GameRulesConfig.pairsEnabled]
  /// açıksa "çiftten açılış" olarak; aksi halde her grup bağımsız bir
  /// seri/grup olarak değerlendirilip toplamları
  /// [GameRulesConfig.openingThreshold] ile karşılaştırılır.
  static GameState openMelds(
    GameState state,
    String playerId,
    List<List<String>> tileGroups,
  ) {
    GameEngineSupport.assertPlayersTurn(state, playerId);
    GameEngineSupport.assertPhase(state, const {GamePhase.waitingForMeld});

    final player = GameEngineSupport.findPlayer(state, playerId);
    if (player.hasOpened) {
      throw const InvalidActionException(
        'Zaten açılış yaptınız; yeni taşları masaya işlemek için '
        'AddTileToMeld kullanılmalı.',
      );
    }
    if (tileGroups.isEmpty || tileGroups.any((g) => g.isEmpty)) {
      throw const InvalidActionException(
        'Açılış için en az bir per (seri/grup) veya çift belirtilmelidir.',
      );
    }

    final allIds = tileGroups.expand((g) => g).toList();
    if (allIds.toSet().length != allIds.length) {
      throw const TileAlreadyUsedException(
        debugDetail: 'Açılış grupları arasında tekrarlanan taş var.',
      );
    }

    final handById = {for (final t in player.hand) t.id: t};
    for (final id in allIds) {
      if (!handById.containsKey(id)) {
        throw const TileNotInHandException();
      }
    }

    final groups = tileGroups
        .map((ids) => ids.map((id) => handById[id]!).toList())
        .toList();

    final isPairAttempt = groups.every((g) => g.length == 2);
    if (isPairAttempt && state.rules.pairsEnabled) {
      return _openViaPairs(state, player, groups);
    }
    return _openViaMelds(state, player, groups);
  }

  /// Açılmış bir oyuncunun elindeki bir taşı, masadaki mevcut bir pere
  /// eklemesi.
  static GameState addTileToMeld(
    GameState state,
    String playerId,
    String tileId,
    String meldId,
    int position,
  ) {
    GameEngineSupport.assertPlayersTurn(state, playerId);
    GameEngineSupport.assertPhase(state, const {GamePhase.waitingForMeld});

    final player = GameEngineSupport.findPlayer(state, playerId);
    if (!player.hasOpened) {
      throw const PlayerNotOpenedException();
    }

    final tile = player.hand.firstWhereOrNull((t) => t.id == tileId);
    if (tile == null) {
      throw const TileNotInHandException();
    }

    final meldIndex = state.tableMelds.indexWhere((m) => m.id == meldId);
    if (meldIndex == -1) {
      throw const InvalidActionException('Belirtilen per masada bulunamadı.');
    }
    final meld = state.tableMelds[meldIndex];
    if (meld.isLocked) {
      throw const InvalidActionException('Bu per kilitli, düzenlenemez.');
    }
    if (meld.type == MeldType.pair) {
      throw const InvalidActionException('Çiftlere taş eklenemez.');
    }
    if (position < 0 || position > meld.tiles.length) {
      throw const InvalidActionException('Geçersiz taş konumu.');
    }

    final candidateRawTiles = [for (final mt in meld.tiles) mt.tile]
      ..insert(position, tile);

    final result = meld.type == MeldType.run
        ? MeldValidator.validateRun(
            candidateRawTiles,
            wrapAroundRunsEnabled: state.rules.wrapAroundRunsEnabled,
          )
        : MeldValidator.validateGroup(candidateRawTiles);

    if (!result.isValid) {
      throw InvalidMeldException(result.reason!);
    }

    final updatedMeld = meld.copyWith(tiles: result.resolvedTiles!);
    final updatedTableMelds = [...state.tableMelds];
    updatedTableMelds[meldIndex] = updatedMeld;

    final updatedPlayers = GameEngineSupport.updatePlayerHand(
      state.players,
      playerId,
      (hand) => hand.where((t) => t.id != tileId).toList(growable: false),
    );

    return state.copyWith(
      players: updatedPlayers,
      tableMelds: updatedTableMelds,
      lastActionDescription:
          '${player.name} ${GameEngineSupport.tileLabel(tile)} taşını '
          'masaya işledi.',
    );
  }

  /// Masadaki bir perde bulunan okeyi, elindeki gerçek (joker olmayan)
  /// taşla değiştirme.
  static GameState swapTileWithTableOkey(
    GameState state,
    String playerId,
    String handTileId,
    String meldId,
    int meldPosition,
  ) {
    GameEngineSupport.assertPlayersTurn(state, playerId);
    GameEngineSupport.assertPhase(state, const {GamePhase.waitingForMeld});

    if (!state.rules.jokerSwapEnabled) {
      throw const InvalidActionException(
        'Bu masada okey değiştirme kapalı.',
      );
    }

    final player = GameEngineSupport.findPlayer(state, playerId);
    if (!player.hasOpened) {
      throw const PlayerNotOpenedException();
    }

    final handTile = player.hand.firstWhereOrNull(
      (t) => t.id == handTileId,
    );
    if (handTile == null) {
      throw const TileNotInHandException();
    }
    if (handTile.actsAsJoker) {
      throw const InvalidActionException(
        'Okey değiştirmek için elinizde gerçek (joker olmayan) bir taş '
        'olmalı.',
      );
    }

    final meldIndex = state.tableMelds.indexWhere((m) => m.id == meldId);
    if (meldIndex == -1) {
      throw const InvalidActionException('Belirtilen per masada bulunamadı.');
    }
    final meld = state.tableMelds[meldIndex];
    if (meldPosition < 0 || meldPosition >= meld.tiles.length) {
      throw const InvalidActionException('Geçersiz taş konumu.');
    }

    final targetSlot = meld.tiles[meldPosition];
    if (!targetSlot.isJokerSubstitute) {
      throw const InvalidActionException(
        'Bu konumda değiştirilebilecek bir okey yok.',
      );
    }
    if (handTile.color != targetSlot.effectiveColor ||
        handTile.number != targetSlot.effectiveNumber) {
      throw const InvalidActionException(
        'Elinizdeki taş, okeyin temsil ettiği taşla eşleşmiyor.',
      );
    }

    final jokerTile = targetSlot.tile;
    final newTiles = [...meld.tiles];
    newTiles[meldPosition] = MeldTile(tile: handTile);
    final updatedMeld = meld.copyWith(tiles: newTiles);
    final updatedTableMelds = [...state.tableMelds];
    updatedTableMelds[meldIndex] = updatedMeld;

    final updatedPlayers = GameEngineSupport.updatePlayerHand(
      state.players,
      playerId,
      (hand) => [
        ...hand.where((t) => t.id != handTileId),
        jokerTile,
      ],
    );

    return state.copyWith(
      players: updatedPlayers,
      tableMelds: updatedTableMelds,
      lastActionDescription:
          '${player.name} okeyi '
          '${GameEngineSupport.tileLabel(handTile)} ile değiştirdi.',
    );
  }

  // --- Yardımcılar --------------------------------------------------------

  static GameState _openViaMelds(
    GameState state,
    Player player,
    List<List<OkeyTile>> groups,
  ) {
    final resolvedMelds = <Meld>[];
    for (final group in groups) {
      final result = MeldValidator.validate(
        group,
        wrapAroundRunsEnabled: state.rules.wrapAroundRunsEnabled,
      );
      if (!result.isValid) {
        throw InvalidMeldException(result.reason!);
      }
      resolvedMelds.add(
        Meld(
          id: _uuid.v4(),
          type: result.type!,
          openedByPlayerId: player.id,
          tiles: result.resolvedTiles!,
        ),
      );
    }

    final check = OpeningScoreCalculator.check(
      proposedMelds: resolvedMelds,
      requiredScore: state.rules.openingThreshold,
    );
    if (!check.isSufficient) {
      throw InsufficientOpeningScoreException(
        currentScore: check.totalScore,
        requiredScore: check.requiredScore,
      );
    }

    final usedIds = groups.expand((g) => g.map((t) => t.id)).toSet();
    final updatedPlayers = _markOpened(
      GameEngineSupport.updatePlayerHand(
        state.players,
        player.id,
        (hand) => hand.where((t) => !usedIds.contains(t.id)).toList(),
      ),
      player.id,
      withPairs: false,
    );

    return state.copyWith(
      players: updatedPlayers,
      tableMelds: [...state.tableMelds, ...resolvedMelds],
      lastActionDescription:
          '${player.name} açılış yaptı (${check.totalScore} puan).',
    );
  }

  static GameState _openViaPairs(
    GameState state,
    Player player,
    List<List<OkeyTile>> groups,
  ) {
    final pairCheck = _validateProposedPairs(
      groups,
      state.rules.pairJokerPolicy,
    );
    if (pairCheck != null) {
      throw InvalidMeldException(pairCheck);
    }
    if (groups.length < state.rules.requiredPairCount) {
      throw InsufficientPairCountException(
        currentPairCount: groups.length,
        requiredPairCount: state.rules.requiredPairCount,
      );
    }

    final resolvedMelds = groups
        .map((pairTiles) => _buildPairMeld(player.id, pairTiles))
        .toList();

    final usedIds = groups.expand((g) => g.map((t) => t.id)).toSet();
    final updatedPlayers = _markOpened(
      GameEngineSupport.updatePlayerHand(
        state.players,
        player.id,
        (hand) => hand.where((t) => !usedIds.contains(t.id)).toList(),
      ),
      player.id,
      withPairs: true,
    );

    return state.copyWith(
      players: updatedPlayers,
      tableMelds: [...state.tableMelds, ...resolvedMelds],
      lastActionDescription:
          '${player.name} çiftten açılış yaptı (${groups.length} çift).',
    );
  }

  /// Önerilen çift gruplarının yapısal olarak geçerli olup olmadığını
  /// kontrol eder; geçersizse hata mesajını, geçerliyse `null` döndürür.
  static String? _validateProposedPairs(
    List<List<OkeyTile>> groups,
    PairJokerPolicy policy,
  ) {
    var jokerBudget = switch (policy) {
      PairJokerPolicy.naturalOnly => 0,
      PairJokerPolicy.maxOne => 1,
      PairJokerPolicy.unlimited => 1 << 30,
    };

    for (final group in groups) {
      if (group.length != 2) {
        return 'Her çift tam olarak 2 taştan oluşmalıdır.';
      }
      final jokerCount = group.where((t) => t.actsAsJoker).length;
      if (jokerCount == 0) {
        final a = group[0];
        final b = group[1];
        if (a.color != b.color || a.number != b.number) {
          return 'Çift, aynı renk ve sayıdan iki taştan oluşmalıdır.';
        }
      } else {
        if (jokerCount > jokerBudget) {
          return 'Bu masada çiftte kullanılabilecek okey sayısı aşıldı.';
        }
        jokerBudget -= jokerCount;
      }
    }
    return null;
  }

  static Meld _buildPairMeld(String playerId, List<OkeyTile> pairTiles) {
    final natural = pairTiles.firstWhereOrNull((t) => !t.actsAsJoker);
    final resolvedTiles = pairTiles.map((t) {
      if (!t.actsAsJoker) return MeldTile(tile: t);
      return MeldTile(
        tile: t,
        representedColor: natural?.color,
        representedNumber: natural?.number,
      );
    }).toList();

    return Meld(
      id: _uuid.v4(),
      type: MeldType.pair,
      openedByPlayerId: playerId,
      tiles: resolvedTiles,
    );
  }

  static List<Player> _markOpened(
    List<Player> players,
    String playerId, {
    required bool withPairs,
  }) {
    return [
      for (final p in players)
        if (p.id == playerId)
          p.copyWith(hasOpened: true, hasOpenedWithPairs: withPairs)
        else
          p,
    ];
  }
}
