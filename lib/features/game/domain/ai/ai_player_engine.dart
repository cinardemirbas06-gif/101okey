import '../../../../core/errors/game_exceptions.dart';
import '../../../../core/random/random_provider.dart';
import '../entities/ai_visible_game_state.dart';
import '../entities/game_state.dart';
import '../entities/okey_tile.dart';
import '../entities/player.dart';
import '../enums/ai_difficulty.dart';
import '../enums/ai_personality.dart';
import '../enums/finish_type.dart';
import '../enums/game_phase.dart';
import '../enums/meld_type.dart';
import '../rules/finish_engine.dart';
import '../rules/meld_engine.dart';
import '../rules/meld_validator.dart';
import '../rules/turn_engine.dart';
import 'ai_visible_state_mapper.dart';
import 'discard_advisor.dart';
import 'hand_coverage_finder.dart';
import 'hand_meld_finder.dart';
import 'opening_attempt_finder.dart';

/// Bir yapay zekâ oyuncusunun tam bir turunu oynayan üst düzey motor.
///
/// **Kritik kural:** Bu motor, kararlarını yalnızca
/// [AiVisibleStateMapper] tarafından üretilen [AiVisibleGameState]
/// üzerinden verir; rakiplerin kapalı ellerine hiçbir noktada erişmez.
/// Tüm state değişiklikleri her zaman [TurnEngine]/[MeldEngine]/
/// [FinishEngine] üzerinden, aynı doğrulamalardan geçirilerek yapılır —
/// AI için ayrı bir "arka kapı" yoktur.
///
/// **Kapsam notu:** Bu aşamada AI yalnızca seri/grup ile açılış ve
/// normal/okeyle bitiş dener; çiftten açılış/bitiş ve masadaki
/// perleri stratejik olarak "saklama" (expert seviye için olası bir
/// geliştirme) bu motorun kapsamı dışındadır.
///
/// **Performans:** Bu motor saf Dart'tır, Flutter'a bağımlı değildir;
/// UI katmanı (Aşama 6) bunu `compute()`/isolate içinde çağırarak arayüz
/// thread'ini bloklamamalıdır (bkz. proje gereksinimleri #18).
abstract final class AiPlayerEngine {
  const AiPlayerEngine._();

  static GameState playTurn(GameState state, {required RandomProvider random}) {
    final player = state.activePlayer;
    if (!player.isAI) {
      throw ArgumentError('playTurn yalnızca AI oyuncular için çağrılabilir.');
    }
    final difficulty = player.aiDifficulty ?? AiDifficulty.medium;
    final personality = player.aiPersonality ?? AiPersonality.cautious;

    // Başlayan oyuncunun ilk turu: dağıtımdan zaten 22 taşla geldiği için
    // (hasDrawnThisTurn=true, bkz. GameSetupService) çekme adımı atlanır.
    var current = state;
    if (!current.hasDrawnThisTurn) {
      current = _decideDraw(current, player.id, random: random);
    }
    if (current.phase != GamePhase.waitingForMeld) {
      // Deste tükendi ve el sonuçsuz/bitmiş sayıldı (bkz. TurnEngine).
      return current;
    }

    current = _tryOpenOrPlayToTable(current, player.id, difficulty);

    final finished = _tryFinish(current, player.id, difficulty);
    if (finished != null) return finished;

    return _discard(current, player.id, difficulty, personality);
  }

  static GameState _decideDraw(
    GameState state,
    String playerId, {
    required RandomProvider random,
  }) {
    final visible = AiVisibleStateMapper.buildVisibleState(state, playerId);
    if (_shouldTakeDiscard(visible)) {
      try {
        return TurnEngine.takeDiscardedTile(state, playerId);
      } on GameException {
        // Beklenmedik doğrulama hatası: güvenli varsayılana (kapalı
        // desteden çekme) düş.
      }
    }
    return TurnEngine.drawFromDeck(state, playerId, random: random);
  }

  static bool _shouldTakeDiscard(AiVisibleGameState visible) {
    final topTile = visible.currentDiscardTopTile;
    if (topTile == null) return false;

    final handWithTile = [...visible.ownHand, topTile];
    final relevantCandidates = HandMeldFinder.findAllCandidates(
      handWithTile,
    ).where((c) => c.containsTile(topTile));

    return relevantCandidates.any(
      (c) => c.isComplete || c.missingFromOutside <= 1,
    );
  }

  static GameState _tryOpenOrPlayToTable(
    GameState state,
    String playerId,
    AiDifficulty difficulty,
  ) {
    final player = state.players.firstWhere((p) => p.id == playerId);
    if (!player.hasOpened) {
      return _tryOpen(state, player, playerId, difficulty);
    }
    return _tryPlayToTable(state, playerId);
  }

  static GameState _tryOpen(
    GameState state,
    Player player,
    String playerId,
    AiDifficulty difficulty,
  ) {
    final openingGroups = OpeningAttemptFinder.findOpeningMelds(
      player.hand,
      state.rules,
      combinationBudget: difficulty.combinationBudget,
    );
    if (openingGroups == null) return state;

    try {
      return MeldEngine.openMelds(
        state,
        playerId,
        openingGroups.map((g) => g.map((t) => t.id).toList()).toList(),
      );
    } on GameException {
      return state;
    }
  }

  /// Açılmış oyuncunun elindeki, masadaki mevcut perlere eklenebilecek
  /// tüm taşları açgözlü (greedy) biçimde işler.
  static GameState _tryPlayToTable(GameState state, String playerId) {
    var current = state;
    var madeProgress = true;
    var safetyCounter = 0;

    while (madeProgress && safetyCounter < 50) {
      madeProgress = false;
      safetyCounter++;
      final player = current.players.firstWhere((p) => p.id == playerId);

      for (final tile in player.hand) {
        final placement = _findTablePlacement(tile, current);
        if (placement == null) continue;
        try {
          current = MeldEngine.addTileToMeld(
            current,
            playerId,
            tile.id,
            placement.meldId,
            placement.position,
          );
          madeProgress = true;
          break;
        } on GameException {
          continue;
        }
      }
    }
    return current;
  }

  static _TablePlacement? _findTablePlacement(OkeyTile tile, GameState state) {
    for (final meld in state.tableMelds) {
      if (meld.isLocked) continue;
      final rawTiles = meld.tiles.map((mt) => mt.tile).toList();
      if (meld.type == MeldType.run) {
        if (MeldValidator.validateRun([tile, ...rawTiles]).isValid) {
          return _TablePlacement(meld.id, 0);
        }
        if (MeldValidator.validateRun([...rawTiles, tile]).isValid) {
          return _TablePlacement(meld.id, rawTiles.length);
        }
      } else if (meld.type == MeldType.group) {
        if (MeldValidator.validateGroup([...rawTiles, tile]).isValid) {
          return _TablePlacement(meld.id, rawTiles.length);
        }
      }
    }
    return null;
  }

  static GameState? _tryFinish(
    GameState state,
    String playerId,
    AiDifficulty difficulty,
  ) {
    final player = state.players.firstWhere((p) => p.id == playerId);
    final hand = player.hand;
    if (hand.isEmpty) return null;

    if (!player.hasOpened) {
      if (!state.rules.handFinishEnabled) return null;
      final groups = HandCoverageFinder.findFullCoverage(
        hand,
        0,
        combinationBudget: difficulty.combinationBudget,
      );
      if (groups == null) return null;
      try {
        return FinishEngine.finishHand(
          state,
          playerId,
          FinishType.handFinish,
          groups.map((g) => g.map((t) => t.id).toList()).toList(),
        );
      } on GameException {
        return null;
      }
    }

    final groups = HandCoverageFinder.findFullCoverage(
      hand,
      1,
      combinationBudget: difficulty.combinationBudget,
    );
    if (groups == null) return null;

    final groupedIds = groups.expand((g) => g).map((t) => t.id).toSet();
    final leftover = hand.where((t) => !groupedIds.contains(t.id)).toList();
    if (leftover.length != 1) return null;

    final finishingTile = leftover.single;
    final finishType =
        finishingTile.actsAsJoker && state.rules.okeyFinishEnabled
        ? FinishType.okeyFinish
        : FinishType.normal;

    try {
      return FinishEngine.finishHand(
        state,
        playerId,
        finishType,
        groups.map((g) => g.map((t) => t.id).toList()).toList(),
      );
    } on GameException {
      return null;
    }
  }

  static GameState _discard(
    GameState state,
    String playerId,
    AiDifficulty difficulty,
    AiPersonality personality,
  ) {
    final player = state.players.firstWhere((p) => p.id == playerId);
    final visible = AiVisibleStateMapper.buildVisibleState(state, playerId);
    final tile = DiscardAdvisor.chooseDiscard(
      hand: player.hand,
      visibleState: visible,
      difficulty: difficulty,
      personality: personality,
    );
    return TurnEngine.discardTile(state, playerId, tile.id);
  }
}

final class _TablePlacement {
  const _TablePlacement(this.meldId, this.position);
  final String meldId;
  final int position;
}
