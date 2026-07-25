import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/game_exceptions.dart';
import '../../../../core/random/random_provider.dart';
import '../../../achievements/data/achievements_repository.dart';
import '../../../achievements/domain/achievement_evaluator.dart';
import '../../../statistics/data/statistics_repository.dart';
import '../../../statistics/domain/player_statistics.dart';
import '../../domain/ai/ai_player_engine.dart';
import '../../domain/ai/ai_visible_state_mapper.dart';
import '../../domain/ai/discard_advisor.dart';
import '../../domain/entities/game_rules_config.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/entities/player.dart';
import '../../domain/enums/ai_difficulty.dart';
import '../../domain/enums/ai_personality.dart';
import '../../domain/enums/finish_type.dart';
import '../../domain/enums/game_mode.dart';
import '../../domain/enums/game_phase.dart';
import '../../domain/rules/finish_engine.dart';
import '../../domain/rules/meld_engine.dart';
import '../../domain/rules/opening_score_calculator.dart';
import '../../domain/rules/turn_engine.dart';
import '../../domain/services/game_setup_service.dart';
import '../../domain/services/scoring_engine.dart';
import '../../data/game_save_repository.dart';
import 'game_session_state.dart';

/// Gerçek (insan) oyuncunun sabit kimliği. Bu uygulama şimdilik yalnızca
/// tek bir yerel oyuncu + 3 AI destekler.
const String kHumanPlayerId = 'human';

const List<String> kDefaultAiNames = ['Ayşe', 'Mehmet', 'Zeynep'];
const List<AiPersonality> kDefaultAiPersonalities = [
  AiPersonality.cautious,
  AiPersonality.aggressive,
  AiPersonality.runFocused,
];

/// Tek bir oyun oturumunu (kurulumdan el sonuna kadar) yöneten
/// presentation-katmanı controller'ı.
///
/// **Kritik kural:** Bu sınıf oyun durumunu HİÇBİR ZAMAN doğrudan
/// değiştirmez; her hamle `TurnEngine`/`MeldEngine`/`FinishEngine`
/// üzerinden geçer ve doğrulanır. UI, yalnızca bu controller'ın
/// metotlarını çağırır.
///
/// Her başarılı hamleden sonra oyun otomatik olarak kaydedilir
/// (`GameSaveRepository`); bir el bittiğinde istatistikler ve
/// başarımlar güncellenip kalıcı olarak saklanır.
class GameController extends StateNotifier<GameSessionState> {
  GameController(this._random) : super(const GameSessionState());

  final RandomProvider _random;

  /// Uygulama açılırken kaydedilmiş bir el varsa yükler.
  ///
  /// Kayıt bozuksa veya şema sürümü uyuşmuyorsa sessizce temizlenir
  /// (kayıt zaten [GameSaveRepository.load] içinde silinir) ve `false`
  /// döner; çağıran taraf bu durumda yeni bir oyun başlatmalıdır.
  Future<bool> resumeSavedGame() async {
    try {
      final saved = await GameSaveRepository.load();
      if (saved == null) return false;
      state = GameSessionState(gameState: saved);
      unawaited(_driveAiTurnsIfNeeded());
      return true;
    } on GameException {
      return false;
    }
  }

  void startNewGame({
    required String playerName,
    GameMode gameMode = GameMode.singleHand,
    GameRulesConfig rules = GameRulesConfig.standard,
    List<AiDifficulty> aiDifficulties = const [
      AiDifficulty.easy,
      AiDifficulty.medium,
      AiDifficulty.hard,
    ],
  }) {
    final players = <Player>[
      Player(id: kHumanPlayerId, name: playerName, avatarId: 'human'),
      for (var i = 0; i < 3; i++)
        Player(
          id: 'ai_$i',
          name: kDefaultAiNames[i],
          avatarId: 'ai_$i',
          isAI: true,
          aiDifficulty: aiDifficulties[i],
          aiPersonality: kDefaultAiPersonalities[i],
        ),
    ];

    final newGame = GameSetupService.createNewGame(
      gameId: DateTime.now().microsecondsSinceEpoch.toString(),
      seed: DateTime.now().microsecondsSinceEpoch,
      gameMode: gameMode,
      rules: rules,
      players: players,
      random: _random,
    );

    state = GameSessionState(gameState: newGame);
    unawaited(GameSaveRepository.save(newGame));
    unawaited(_driveAiTurnsIfNeeded());
  }

  // --- Seçim / hazırlanan gruplar -----------------------------------------

  void toggleTileSelection(String tileId) {
    final current = Set<String>.of(state.selectedTileIds);
    if (!current.remove(tileId)) current.add(tileId);
    state = state.copyWith(selectedTileIds: current, clearError: true);
  }

  void clearSelection() {
    state = state.copyWith(selectedTileIds: const {});
  }

  /// Şu an seçili taşları YENİ bir per grubu olarak hazırlanan gruplara
  /// ekler (henüz motora gönderilmez).
  void stageSelectionAsGroup() {
    if (state.selectedTileIds.isEmpty) return;
    state = state.copyWith(
      pendingMeldGroups: [
        ...state.pendingMeldGroups,
        state.selectedTileIds.toList(),
      ],
      selectedTileIds: const {},
      clearError: true,
    );
  }

  /// Sürükle-bırak ile doğrudan tek bir taşı yeni bir per grubuna ekler.
  void addTileToPendingGroup(String tileId, {int? groupIndex}) {
    final groups = [
      for (final g in state.pendingMeldGroups) [...g],
    ];
    if (groupIndex != null && groupIndex >= 0 && groupIndex < groups.length) {
      if (!groups[groupIndex].contains(tileId)) groups[groupIndex].add(tileId);
    } else {
      groups.add([tileId]);
    }
    state = state.copyWith(pendingMeldGroups: groups, clearError: true);
  }

  void clearPendingGroups() {
    state = state.copyWith(pendingMeldGroups: const []);
  }

  /// Hazırlanan bir gruptan tek bir taşı çıkarır (grup boş kalırsa grup
  /// tamamen kaldırılır).
  void removeTileFromPendingGroup(int groupIndex, String tileId) {
    final groups = [
      for (final g in state.pendingMeldGroups) [...g],
    ];
    if (groupIndex < 0 || groupIndex >= groups.length) return;
    groups[groupIndex].remove(tileId);
    if (groups[groupIndex].isEmpty) groups.removeAt(groupIndex);
    state = state.copyWith(pendingMeldGroups: groups, clearError: true);
  }

  // --- İnsan hamleleri ------------------------------------------------------

  Future<void> humanDrawFromDeck() => _runHumanAction(
    (gs) => TurnEngine.drawFromDeck(gs, kHumanPlayerId, random: _random),
    onSuccess: (_, _) => state = state.copyWith(
      tilesDrawnFromDeckThisHand: state.tilesDrawnFromDeckThisHand + 1,
    ),
  );

  Future<void> humanTakeDiscard() => _runHumanAction(
    (gs) => TurnEngine.takeDiscardedTile(gs, kHumanPlayerId),
    onSuccess: (_, _) => state = state.copyWith(
      tilesTakenFromDiscardThisHand: state.tilesTakenFromDiscardThisHand + 1,
    ),
  );

  Future<void> humanOpenMelds() => _runHumanAction((gs) {
    if (state.pendingMeldGroups.isEmpty) {
      throw const InvalidActionException(
        'Önce en az bir per grubu hazırlamalısınız.',
      );
    }
    return MeldEngine.openMelds(gs, kHumanPlayerId, state.pendingMeldGroups);
  }, clearPendingGroups: true, onSuccess: (before, after) {
    final wasOpened = before.players
        .firstWhere((p) => p.id == kHumanPlayerId)
        .hasOpened;
    if (wasOpened) return;
    final beforeMeldIds = before.tableMelds.map((m) => m.id).toSet();
    final newOwnMelds = after.tableMelds
        .where(
          (m) =>
              !beforeMeldIds.contains(m.id) &&
              m.openedByPlayerId == kHumanPlayerId,
        )
        .toList();
    if (newOwnMelds.isEmpty) return;
    final score = OpeningScoreCalculator.calculateMeldsScore(newOwnMelds);
    state = state.copyWith(openingScoreThisHand: score);
  });

  Future<void> humanAddTileToMeld(String tileId, String meldId, int position) =>
      _runHumanAction(
        (gs) =>
            MeldEngine.addTileToMeld(gs, kHumanPlayerId, tileId, meldId, position),
        onSuccess: (_, _) => state = state.copyWith(
          tilesAddedToTableThisHand: state.tilesAddedToTableThisHand + 1,
        ),
      );

  Future<void> humanSwapTileWithTableOkey(
    String handTileId,
    String meldId,
    int meldPosition,
  ) => _runHumanAction(
    (gs) => MeldEngine.swapTileWithTableOkey(
      gs,
      kHumanPlayerId,
      handTileId,
      meldId,
      meldPosition,
    ),
  );

  Future<void> humanRearrangeHand(List<String> orderedTileIds) =>
      _runHumanAction(
        (gs) => TurnEngine.rearrangeHand(gs, kHumanPlayerId, orderedTileIds),
        driveAi: false,
      );

  Future<void> humanDiscard(String tileId) => _runHumanAction(
    (gs) => TurnEngine.discardTile(gs, kHumanPlayerId, tileId),
    onSuccess: (_, _) => state = state.copyWith(
      tilesDiscardedThisHand: state.tilesDiscardedThisHand + 1,
    ),
  );

  Future<void> humanFinish(FinishType finishType) => _runHumanAction((gs) {
    return FinishEngine.finishHand(
      gs,
      kHumanPlayerId,
      finishType,
      state.pendingMeldGroups.isEmpty ? null : state.pendingMeldGroups,
    );
  }, clearPendingGroups: true);

  /// Tur süresi dolduğunda çağrılır (bkz. proje gereksinimleri #35).
  ///
  /// Yalnızca sıra insan oyuncudaysa ve [GameRulesConfig.timerEnabled]
  /// açıksa etkilidir: taş çekilmediyse [GameRulesConfig.autoDrawOnTimeout]
  /// açıksa otomatik çeker; çekilmişse
  /// [GameRulesConfig.autoDiscardLowestRiskOnTimeout] açıksa
  /// `DiscardAdvisor`'ın önerdiği en güvenli taşı otomatik atar.
  Future<void> handleTurnTimeout() async {
    final current = state.gameState;
    if (current == null) return;
    if (current.activePlayer.id != kHumanPlayerId) return;
    if (!current.rules.timerEnabled) return;
    if (current.phase != GamePhase.waitingForDraw &&
        current.phase != GamePhase.waitingForMeld) {
      return;
    }

    if (!current.hasDrawnThisTurn) {
      if (current.rules.autoDrawOnTimeout) {
        await humanDrawFromDeck();
      }
      return;
    }

    if (current.rules.autoDiscardLowestRiskOnTimeout) {
      final human = current.players.firstWhere((p) => p.id == kHumanPlayerId);
      if (human.hand.isEmpty) return;
      final visible = AiVisibleStateMapper.buildVisibleState(
        current,
        kHumanPlayerId,
      );
      final tile = DiscardAdvisor.chooseDiscard(
        hand: human.hand,
        visibleState: visible,
        difficulty: AiDifficulty.medium,
        personality: AiPersonality.cautious,
      );
      await humanDiscard(tile.id);
    }
  }

  // --- Dahili yardımcılar ---------------------------------------------------

  Future<void> _runHumanAction(
    GameState Function(GameState) action, {
    bool clearPendingGroups = false,
    bool driveAi = true,
    void Function(GameState before, GameState after)? onSuccess,
  }) async {
    final current = state.gameState;
    if (current == null) return;

    try {
      final updated = action(current);
      state = state.copyWith(
        gameState: updated,
        selectedTileIds: const {},
        pendingMeldGroups: clearPendingGroups ? const [] : state.pendingMeldGroups,
        clearError: true,
      );
      onSuccess?.call(current, updated);
      unawaited(GameSaveRepository.save(updated));
      _finishHandIfNeeded();
      if (driveAi) await _driveAiTurnsIfNeeded();
    } on GameException catch (e) {
      state = state.copyWith(errorMessage: e.userMessage);
    }
  }

  Future<void> _driveAiTurnsIfNeeded() async {
    var current = state.gameState;
    while (mounted &&
        current != null &&
        current.phase != GamePhase.calculatingScore &&
        current.phase != GamePhase.finished &&
        current.activePlayer.isAI) {
      state = state.copyWith(isAiThinking: true);
      final difficulty = current.activePlayer.aiDifficulty ?? AiDifficulty.medium;
      await Future<void>.delayed(Duration(milliseconds: difficulty.thinkingDelayMs));
      if (!mounted) return;

      try {
        current = AiPlayerEngine.playTurn(current, random: _random);
      } on GameException {
        // AI güvenli bir hamle bulamadıysa (beklenmedik durum): turu
        // pas geçmek yerine mevcut durumda kal, ilerlemeyi durdur.
        break;
      }
      state = state.copyWith(
        gameState: current,
        isAiThinking: false,
        selectedTileIds: const {},
        pendingMeldGroups: const [],
      );
      unawaited(GameSaveRepository.save(current));
      _finishHandIfNeeded();
    }
    if (mounted) state = state.copyWith(isAiThinking: false);
  }

  void _finishHandIfNeeded() {
    final current = state.gameState;
    if (current == null) return;
    if (current.phase != GamePhase.calculatingScore &&
        current.phase != GamePhase.finished) {
      return;
    }
    if (state.lastHandScore != null) return;

    final result = ScoringEngine.calculate(current);
    final updatedStatistics = _applyHandToStatistics(current);
    final unlocked = AchievementEvaluator.evaluate(
      finishedState: current,
      statisticsAfterHand: updatedStatistics,
      tilesAddedToTableThisHand: state.tilesAddedToTableThisHand,
      humanPlayerId: kHumanPlayerId,
    );
    final previouslyUnlocked = AchievementsRepository.loadUnlocked();
    final newlyUnlocked = unlocked.difference(previouslyUnlocked).toList();
    if (unlocked.isNotEmpty) {
      unawaited(
        AchievementsRepository.saveUnlocked({
          ...previouslyUnlocked,
          ...unlocked,
        }),
      );
    }

    unawaited(GameSaveRepository.clear());

    state = state.copyWith(
      gameState: current.copyWith(phase: GamePhase.finished),
      lastHandScore: result,
      newlyUnlockedAchievements: newlyUnlocked,
    );
  }

  /// Bu elin sonucunu kalıcı [PlayerStatistics]'e işler ve saklar.
  PlayerStatistics _applyHandToStatistics(GameState finishedState) {
    final previous = StatisticsRepository.load();
    final humanWon = finishedState.winnerPlayerId == kHumanPlayerId;
    final someoneWon = finishedState.winnerPlayerId != null;

    final currentWinStreak = humanWon ? previous.currentWinStreak + 1 : 0;

    final updated = previous.copyWith(
      handsPlayed: previous.handsPlayed + 1,
      handsWon: previous.handsWon + (humanWon ? 1 : 0),
      handsLost: previous.handsLost + (someoneWon && !humanWon ? 1 : 0),
      normalFinishCount:
          previous.normalFinishCount +
          (humanWon && finishedState.finishType == FinishType.normal ? 1 : 0),
      okeyFinishCount:
          previous.okeyFinishCount +
          (humanWon && finishedState.finishType == FinishType.okeyFinish
              ? 1
              : 0),
      pairFinishCount:
          previous.pairFinishCount +
          (humanWon && finishedState.finishType == FinishType.pairFinish
              ? 1
              : 0),
      handFinishCount:
          previous.handFinishCount +
          (humanWon && finishedState.finishType == FinishType.handFinish
              ? 1
              : 0),
      highestOpeningScore: state.openingScoreThisHand != null
          ? _max(previous.highestOpeningScore, state.openingScoreThisHand!)
          : previous.highestOpeningScore,
      totalOpeningScore:
          previous.totalOpeningScore + (state.openingScoreThisHand ?? 0),
      openingCount: previous.openingCount + (state.openingScoreThisHand != null ? 1 : 0),
      longestWinStreak: _max(previous.longestWinStreak, currentWinStreak),
      currentWinStreak: currentWinStreak,
      totalTilesDiscarded:
          previous.totalTilesDiscarded + state.tilesDiscardedThisHand,
      totalTilesDrawnFromDeck:
          previous.totalTilesDrawnFromDeck + state.tilesDrawnFromDeckThisHand,
      totalTilesTakenFromDiscard:
          previous.totalTilesTakenFromDiscard +
          state.tilesTakenFromDiscardThisHand,
    );

    unawaited(StatisticsRepository.save(updated));
    return updated;
  }

  static int _max(int a, int b) => a > b ? a : b;

  void startNextHandOrReturnToMenu() {
    unawaited(GameSaveRepository.clear());
    state = const GameSessionState();
  }
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSessionState>((ref) {
      return GameController(SystemRandomProvider());
    });
