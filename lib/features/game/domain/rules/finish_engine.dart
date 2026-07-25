import 'package:uuid/uuid.dart';

import '../../../../core/errors/game_exceptions.dart';
import '../entities/game_rules_config.dart';
import '../entities/game_state.dart';
import '../entities/meld.dart';
import '../entities/okey_tile.dart';
import '../entities/player.dart';
import '../enums/finish_type.dart';
import '../enums/game_phase.dart';
import 'engine_support.dart';
import 'meld_validator.dart';
import 'opening_score_calculator.dart';
import 'pair_meld_support.dart';

const _uuid = Uuid();

/// Bir elin bitirilmesini (bkz. proje gereksinimleri #21) doğrulayan ve
/// uygulayan kural motoru.
///
/// **Kapsam notu:** Bu sınıf yalnızca bitiş denemesinin GEÇERLİ olup
/// olmadığını kontrol edip [GameState]'i `GamePhase.calculatingScore`
/// fazına taşır; nihai puan hesabı ayrı bir `ScoringEngine` tarafından
/// yapılır.
///
/// Desteklenen bitiş türleri:
/// - [FinishType.normal] / [FinishType.okeyFinish] /
///   [FinishType.indicatorFinish]: kalan taşların hepsi (son atılacak 1
///   taş hariç) geçerli seri/gruplar halinde gruplanır.
/// - [FinishType.pairFinish]: kalan taşların hepsi (son 1 taş hariç)
///   geçerli çiftler halinde gruplanır; oyuncu daha önce çiftten açılmış
///   olmalıdır.
/// - [FinishType.handFinish]: oyuncu HİÇ açılmamışken, elindeki TÜM
///   taşları tek seferde geçerli per haline getirir (atılacak taş yoktur).
abstract final class FinishEngine {
  const FinishEngine._();

  static GameState finishHand(
    GameState state,
    String playerId,
    FinishType finishType,
    List<List<String>>? finalTileGroups,
  ) {
    GameEngineSupport.assertPlayersTurn(state, playerId);
    GameEngineSupport.assertPhase(state, const {GamePhase.waitingForMeld});
    if (!state.hasDrawnThisTurn) {
      throw const InvalidGamePhaseException(
        debugDetail: 'Bitirmeden önce taş çekilmeli.',
      );
    }
    _assertFinishTypeEnabled(state.rules, finishType);

    return finishType == FinishType.handFinish
        ? _finishFromHand(state, playerId, finalTileGroups)
        : _finishStandard(state, playerId, finishType, finalTileGroups);
  }

  static void _assertFinishTypeEnabled(
    GameRulesConfig rules,
    FinishType type,
  ) {
    final enabled = switch (type) {
      FinishType.normal => true,
      FinishType.okeyFinish => rules.okeyFinishEnabled,
      FinishType.pairFinish => rules.pairFinishEnabled,
      FinishType.indicatorFinish => rules.indicatorFinishEnabled,
      FinishType.handFinish => rules.handFinishEnabled,
    };
    if (!enabled) {
      throw InvalidFinishException('Bu bitiş türü bu masada kapalı.');
    }
  }

  static GameState _finishStandard(
    GameState state,
    String playerId,
    FinishType finishType,
    List<List<String>>? finalTileGroups,
  ) {
    final player = GameEngineSupport.findPlayer(state, playerId);
    final groups = finalTileGroups ?? const <List<String>>[];
    final handById = {for (final t in player.hand) t.id: t};

    final allGroupedIds = groups.expand((g) => g).toList();
    if (allGroupedIds.toSet().length != allGroupedIds.length) {
      throw const TileAlreadyUsedException(
        debugDetail: 'Bitiş grupları arasında tekrarlanan taş var.',
      );
    }
    for (final id in allGroupedIds) {
      if (!handById.containsKey(id)) {
        throw const TileNotInHandException();
      }
    }

    final leftover = player.hand
        .where((t) => !allGroupedIds.contains(t.id))
        .toList();
    if (leftover.length != 1) {
      throw const InvalidFinishException(
        'Bitirmek için gruplanan taşlar dışında elde tam olarak 1 taş '
        'kalmalı (atılacak son taş).',
      );
    }
    final finishingTile = leftover.single;

    if (finishType == FinishType.okeyFinish && !finishingTile.actsAsJoker) {
      throw const InvalidFinishException(
        'Okeyle bitirmek için son atılan taş okey olmalıdır.',
      );
    }
    if (finishType == FinishType.indicatorFinish) {
      final indicator = state.indicatorTile;
      final matchesIndicator =
          indicator != null &&
          finishingTile.color == indicator.color &&
          finishingTile.number == indicator.number;
      if (!matchesIndicator) {
        throw const InvalidFinishException(
          'Göstergeyle bitirmek için son taş göstergeyle aynı renk ve '
          'sayıda olmalıdır.',
        );
      }
    }

    final groupTiles = groups
        .map((ids) => ids.map((id) => handById[id]!).toList())
        .toList();

    final resolvedMelds = <Meld>[];
    if (finishType == FinishType.pairFinish) {
      if (!player.hasOpenedWithPairs) {
        throw const InvalidFinishException(
          'Çiftten bitirmek için önce çiftten açılmış olmalısınız.',
        );
      }
      final pairError = PairMeldSupport.validateProposedPairGroups(
        groupTiles,
        state.rules.pairJokerPolicy,
      );
      if (pairError != null) {
        throw InvalidFinishException(pairError);
      }
      for (final tiles in groupTiles) {
        resolvedMelds.add(PairMeldSupport.buildPairMeld(playerId, tiles));
      }
    } else {
      for (final tiles in groupTiles) {
        final result = MeldValidator.validate(
          tiles,
          wrapAroundRunsEnabled: state.rules.wrapAroundRunsEnabled,
        );
        if (!result.isValid) {
          throw InvalidFinishException(result.reason!);
        }
        resolvedMelds.add(
          Meld(
            id: _uuid.v4(),
            type: result.type!,
            openedByPlayerId: playerId,
            tiles: result.resolvedTiles!,
          ),
        );
      }

      if (!player.hasOpened) {
        if (!state.rules.allowOpenAndFinishSameTurn) {
          throw const PlayerNotOpenedException();
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
      }
    }

    final updatedPlayers = _finishPlayerHand(
      state.players,
      playerId,
      remainingHand: const [],
    );

    return state.copyWith(
      players: updatedPlayers,
      tableMelds: [...state.tableMelds, ...resolvedMelds],
      discardPile: [...state.discardPile, finishingTile],
      phase: GamePhase.calculatingScore,
      winnerPlayerId: playerId,
      finishType: finishType,
      lastActionDescription:
          '${player.name} eli bitirdi '
          '(${GameEngineSupport.tileLabel(finishingTile)} attı).',
    );
  }

  static GameState _finishFromHand(
    GameState state,
    String playerId,
    List<List<String>>? finalTileGroups,
  ) {
    final player = GameEngineSupport.findPlayer(state, playerId);
    if (player.hasOpened) {
      throw const InvalidFinishException(
        'Elden bitirme yalnızca daha önce hiç açılmamış oyuncu için '
        'geçerlidir.',
      );
    }

    final groups = finalTileGroups ?? const <List<String>>[];
    final handById = {for (final t in player.hand) t.id: t};
    final allGroupedIds = groups.expand((g) => g).toList();
    if (allGroupedIds.toSet().length != allGroupedIds.length) {
      throw const TileAlreadyUsedException(
        debugDetail: 'Bitiş grupları arasında tekrarlanan taş var.',
      );
    }
    final coversWholeHand =
        allGroupedIds.length == player.hand.length &&
        player.hand.every((t) => allGroupedIds.contains(t.id));
    if (!coversWholeHand) {
      throw const InvalidFinishException(
        'Elden bitirmek için elinizdeki TÜM taşlar geçerli perler '
        'halinde gruplanmalıdır (atılacak taş yoktur).',
      );
    }

    final resolvedMelds = <Meld>[];
    for (final ids in groups) {
      final tiles = ids.map((id) => handById[id]!).toList();
      final result = MeldValidator.validate(
        tiles,
        wrapAroundRunsEnabled: state.rules.wrapAroundRunsEnabled,
      );
      if (!result.isValid) {
        throw InvalidFinishException(result.reason!);
      }
      resolvedMelds.add(
        Meld(
          id: _uuid.v4(),
          type: result.type!,
          openedByPlayerId: playerId,
          tiles: result.resolvedTiles!,
        ),
      );
    }

    final updatedPlayers = _finishPlayerHand(
      state.players,
      playerId,
      remainingHand: const [],
    );

    return state.copyWith(
      players: updatedPlayers,
      tableMelds: [...state.tableMelds, ...resolvedMelds],
      phase: GamePhase.calculatingScore,
      winnerPlayerId: playerId,
      finishType: FinishType.handFinish,
      lastActionDescription: '${player.name} elden bitirdi!',
    );
  }

  static List<Player> _finishPlayerHand(
    List<Player> players,
    String playerId, {
    required List<OkeyTile> remainingHand,
  }) {
    return [
      for (final p in players)
        if (p.id == playerId)
          p.copyWith(hand: remainingHand, hasOpened: true)
        else
          p,
    ];
  }
}
