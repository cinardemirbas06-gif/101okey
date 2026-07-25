import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/game_exceptions.dart';
import '../../../../core/random/random_provider.dart';
import '../../domain/ai/ai_player_engine.dart';
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
import '../../domain/rules/turn_engine.dart';
import '../../domain/services/game_setup_service.dart';
import '../../domain/services/scoring_engine.dart';
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
class GameController extends StateNotifier<GameSessionState> {
  GameController(this._random) : super(const GameSessionState());

  final RandomProvider _random;

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

  Future<void> humanDrawFromDeck() =>
      _runHumanAction((gs) => TurnEngine.drawFromDeck(gs, kHumanPlayerId, random: _random));

  Future<void> humanTakeDiscard() =>
      _runHumanAction((gs) => TurnEngine.takeDiscardedTile(gs, kHumanPlayerId));

  Future<void> humanOpenMelds() => _runHumanAction((gs) {
    if (state.pendingMeldGroups.isEmpty) {
      throw const InvalidActionException('Önce en az bir per grubu hazırlamalısınız.');
    }
    return MeldEngine.openMelds(gs, kHumanPlayerId, state.pendingMeldGroups);
  }, clearPendingGroups: true);

  Future<void> humanAddTileToMeld(String tileId, String meldId, int position) =>
      _runHumanAction(
        (gs) => MeldEngine.addTileToMeld(gs, kHumanPlayerId, tileId, meldId, position),
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

  Future<void> humanDiscard(String tileId) =>
      _runHumanAction((gs) => TurnEngine.discardTile(gs, kHumanPlayerId, tileId));

  Future<void> humanFinish(FinishType finishType) => _runHumanAction((gs) {
    return FinishEngine.finishHand(
      gs,
      kHumanPlayerId,
      finishType,
      state.pendingMeldGroups.isEmpty ? null : state.pendingMeldGroups,
    );
  }, clearPendingGroups: true);

  // --- Dahili yardımcılar ---------------------------------------------------

  Future<void> _runHumanAction(
    GameState Function(GameState) action, {
    bool clearPendingGroups = false,
    bool driveAi = true,
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
    state = state.copyWith(
      gameState: current.copyWith(phase: GamePhase.finished),
      lastHandScore: result,
    );
  }

  void startNextHandOrReturnToMenu() {
    state = const GameSessionState();
  }
}

final gameControllerProvider =
    StateNotifierProvider<GameController, GameSessionState>((ref) {
      return GameController(SystemRandomProvider());
    });
