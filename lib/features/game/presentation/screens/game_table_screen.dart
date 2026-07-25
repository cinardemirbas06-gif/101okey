import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/tile_palette.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/okey_tile.dart';
import '../../domain/entities/player_public_state.dart';
import '../../domain/enums/finish_type.dart';
import '../../domain/enums/game_phase.dart';
import '../controllers/game_controller.dart';
import '../widgets/animation_speed.dart';
import '../widgets/meld_staging_tray.dart';
import '../widgets/opponent_panel.dart';
import '../widgets/player_rack.dart';
import '../widgets/table_center_panel.dart';
import '../widgets/table_meld_view.dart';

/// Oyun masası ekranı: rakipler, ortadaki alan, masaya açılmış perler,
/// insan oyuncunun ıstakası ve hamle butonları.
class GameTableScreen extends ConsumerWidget {
  const GameTableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    ref.listen(gameControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        if (settings.hapticFeedbackEnabled) {
          HapticFeedback.heavyImpact();
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
      }
      if (next.lastHandScore != null && previous?.lastHandScore == null) {
        if (settings.hapticFeedbackEnabled) {
          HapticFeedback.mediumImpact();
        }
        context.push('/result');
      }
    });

    final session = ref.watch(gameControllerProvider);
    final gameState = session.gameState;

    if (gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final controller = ref.read(gameControllerProvider.notifier);
    final human = gameState.players.firstWhere((p) => p.id == kHumanPlayerId);
    final opponents = gameState.players.where((p) => p.id != kHumanPlayerId).toList();
    final isHumanTurn = gameState.activePlayer.id == kHumanPlayerId;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileCountForSizing = human.hand.isEmpty
        ? 8
        : (human.hand.length / 2).ceil();
    final tileWidth = ((screenWidth - 32) / (tileCountForSizing + 1)).clamp(
      30.0,
      58.0,
    );
    final tileHeight = tileWidth * 1.45;

    final stagedTileIds = session.pendingMeldGroups
        .expand((g) => g)
        .toSet();
    final handById = {for (final t in human.hand) t.id: t};
    final visibleRackHand = human.hand
        .where((t) => !stagedTileIds.contains(t.id))
        .toList();
    final stagingGroups = [
      for (final g in session.pendingMeldGroups)
        [for (final id in g) if (handById[id] != null) handById[id]!],
    ];

    return GameUiPreferences(
      animationsEnabled: settings.animationsEnabled,
      dropHighlightsEnabled: settings.validDropHighlightEnabled,
      child: Scaffold(
      backgroundColor: TilePalette.tableFeltGreen,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              handNumber: gameState.handNumber,
              turnNumber: gameState.turnNumber,
              lastAction: gameState.lastActionDescription,
              isAiThinking: session.isAiThinking,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final opponent in opponents)
                    OpponentPanel(
                      opponent: PlayerPublicState(
                        playerId: opponent.id,
                        name: opponent.name,
                        remainingTileCount: opponent.hand.length,
                        hasOpened: opponent.hasOpened,
                        hasOpenedWithPairs: opponent.hasOpenedWithPairs,
                      ),
                      isActive: gameState.activePlayer.id == opponent.id,
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TableCenterPanel(
                        drawPileCount: gameState.remainingDeckCount,
                        indicatorTile: gameState.indicatorTile,
                        okeyTile: gameState.okeyTile,
                        discardTopTile: gameState.currentDiscardTopTile,
                        canDrawFromDeck:
                            isHumanTurn &&
                            gameState.phase == GamePhase.waitingForDraw,
                        onDrawFromDeck: controller.humanDrawFromDeck,
                        onTakeDiscard: () {
                          if (isHumanTurn &&
                              gameState.phase == GamePhase.waitingForDraw) {
                            controller.humanTakeDiscard();
                          }
                        },
                        onDiscardDropped: (tile) {
                          if (isHumanTurn) controller.humanDiscard(tile.id);
                        },
                        tileWidth: tileWidth * 0.75,
                        tileHeight: tileHeight * 0.75,
                      ),
                    ),
                    if (gameState.tableMelds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final meld in gameState.tableMelds)
                              TableMeldView(
                                meld: meld,
                                tileWidth: tileWidth * 0.7,
                                tileHeight: tileHeight * 0.7,
                                onDropAtStart: (tile) {
                                  if (isHumanTurn) {
                                    controller.humanAddTileToMeld(
                                      tile.id,
                                      meld.id,
                                      0,
                                    );
                                  }
                                },
                                onDropAtEnd: (tile) {
                                  if (isHumanTurn) {
                                    controller.humanAddTileToMeld(
                                      tile.id,
                                      meld.id,
                                      meld.tiles.length,
                                    );
                                  }
                                },
                                onDropOnJokerSlot: (tile, position) {
                                  if (isHumanTurn) {
                                    controller.humanSwapTileWithTableOkey(
                                      tile.id,
                                      meld.id,
                                      position,
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _ActionBar(
              isHumanTurn: isHumanTurn,
              phase: gameState.phase,
              hasDrawn: gameState.hasDrawnThisTurn,
              selectedCount: session.selectedTileIds.length,
              hasPendingGroups: session.pendingMeldGroups.isNotEmpty,
              onStageSelection: controller.stageSelectionAsGroup,
              onClearGroups: controller.clearPendingGroups,
              onOpenMelds: controller.humanOpenMelds,
              onFinishNormal: () => controller.humanFinish(FinishType.normal),
              onFinishHand: () => controller.humanFinish(FinishType.handFinish),
              onDiscardSelected: session.selectedTileIds.length == 1
                  ? () => controller.humanDiscard(
                      session.selectedTileIds.single,
                    )
                  : null,
              onSort: settings.handSortMode == HandSortMode.manual
                  ? null
                  : () => controller.humanRearrangeHand(
                      _sortedHandOrder(human.hand, settings.handSortMode),
                    ),
            ),
            if (stagingGroups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: MeldStagingTray(
                  groups: stagingGroups,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                  onDropIntoGroup: (tile, groupIndex) => controller
                      .addTileToPendingGroup(tile.id, groupIndex: groupIndex),
                  onDropIntoNewGroup: (tile) =>
                      controller.addTileToPendingGroup(tile.id),
                  onRemoveTileFromGroup: controller.removeTileFromPendingGroup,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: DragTarget<OkeyTile>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) =>
                    controller.addTileToPendingGroup(details.data.id),
                builder: (context, candidateData, rejectedData) {
                  return PlayerRack(
                    hand: visibleRackHand,
                    selectedTileIds: session.selectedTileIds,
                    onTileTap: (tile) =>
                        controller.toggleTileSelection(tile.id),
                    onReorder: controller.humanRearrangeHand,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

}

List<String> _sortedHandOrder(List<OkeyTile> hand, HandSortMode mode) {
  final sorted = [...hand];
  if (mode == HandSortMode.byColor) {
    sorted.sort((a, b) {
      final byColor = a.color.index.compareTo(b.color.index);
      return byColor != 0 ? byColor : a.number.compareTo(b.number);
    });
  } else {
    sorted.sort((a, b) {
      final byNumber = a.number.compareTo(b.number);
      return byNumber != 0 ? byNumber : a.color.index.compareTo(b.color.index);
    });
  }
  return sorted.map((t) => t.id).toList();
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.handNumber,
    required this.turnNumber,
    required this.lastAction,
    required this.isAiThinking,
  });

  final int handNumber;
  final int turnNumber;
  final String? lastAction;
  final bool isAiThinking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black26,
      child: Row(
        children: [
          Text(
            'El $handNumber · Tur $turnNumber',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lastAction ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const _TurnCountdown(),
          if (isAiThinking) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'AI düşünüyor…',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sıra süresi geri sayımını gösteren, kendi `Timer`'ını yöneten küçük
/// bir alt widget.
///
/// Bu widget bilinçli olarak [GameTableScreen]'den ayrıldı: saniyede bir
/// tetiklenen sayaç, yalnızca bu küçük metin/ikon çiftini yeniden
/// çizmeli — tüm oyun masasını (ıstaka, masaya açılmış perler, sürükle-
/// bırak hedefleri) her saniye yeniden inşa etmek gereksiz bir performans
/// maliyetidir.
class _TurnCountdown extends ConsumerStatefulWidget {
  const _TurnCountdown();

  @override
  ConsumerState<_TurnCountdown> createState() => _TurnCountdownState();
}

class _TurnCountdownState extends ConsumerState<_TurnCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // yalnızca sayaç metnini yenilemek için
      _checkTimeout();
    });
  }

  void _checkTimeout() {
    final gameState = ref.read(gameControllerProvider).gameState;
    if (gameState == null) return;
    if (gameState.activePlayer.id != kHumanPlayerId) return;
    if (!gameState.rules.timerEnabled) return;
    final startedAt = gameState.turnStartedAt;
    if (startedAt == null) return;
    if (DateTime.now().difference(startedAt) >= gameState.rules.turnDuration) {
      ref.read(gameControllerProvider.notifier).handleTurnTimeout();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(
      gameControllerProvider.select((s) => s.gameState),
    );
    if (gameState == null) return const SizedBox.shrink();

    final isHumanTurn = gameState.activePlayer.id == kHumanPlayerId;
    if (!isHumanTurn || !gameState.rules.timerEnabled || gameState.turnStartedAt == null) {
      return const SizedBox.shrink();
    }

    final elapsed = DateTime.now().difference(gameState.turnStartedAt!);
    final remainingSeconds = (gameState.rules.turnDuration - elapsed)
        .inSeconds
        .clamp(0, gameState.rules.turnDuration.inSeconds);
    final urgent = remainingSeconds <= 5;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: urgent ? Colors.redAccent : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '${remainingSeconds}sn',
            style: TextStyle(
              color: urgent ? Colors.redAccent : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isHumanTurn,
    required this.phase,
    required this.hasDrawn,
    required this.selectedCount,
    required this.hasPendingGroups,
    required this.onStageSelection,
    required this.onClearGroups,
    required this.onOpenMelds,
    required this.onFinishNormal,
    required this.onFinishHand,
    required this.onDiscardSelected,
    required this.onSort,
  });

  final bool isHumanTurn;
  final GamePhase phase;
  final bool hasDrawn;
  final int selectedCount;
  final bool hasPendingGroups;
  final VoidCallback onStageSelection;
  final VoidCallback onClearGroups;
  final VoidCallback onOpenMelds;
  final VoidCallback onFinishNormal;
  final VoidCallback onFinishHand;
  final VoidCallback? onDiscardSelected;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    final canAct = isHumanTurn && phase == GamePhase.waitingForMeld && hasDrawn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          ElevatedButton.icon(
            onPressed: selectedCount >= 2 ? onStageSelection : null,
            icon: const Icon(Icons.grid_view, size: 16),
            label: const Text('Per Olarak Hazırla'),
          ),
          ElevatedButton.icon(
            onPressed: hasPendingGroups ? onClearGroups : null,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Grupları Temizle'),
          ),
          ElevatedButton.icon(
            onPressed: canAct && hasPendingGroups ? onOpenMelds : null,
            icon: const Icon(Icons.lock_open, size: 16),
            label: const Text('Aç'),
          ),
          ElevatedButton.icon(
            onPressed: canAct ? onFinishNormal : null,
            icon: const Icon(Icons.flag, size: 16),
            label: const Text('Bitir'),
          ),
          ElevatedButton.icon(
            onPressed: canAct && !hasPendingGroups ? onFinishHand : null,
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text('Elden Bitir'),
          ),
          ElevatedButton.icon(
            onPressed: canAct ? onDiscardSelected : null,
            icon: const Icon(Icons.arrow_downward, size: 16),
            label: const Text('Seçileni At'),
          ),
          OutlinedButton.icon(
            onPressed: onSort,
            icon: const Icon(Icons.sort, size: 16),
            label: const Text('Sırala'),
          ),
        ],
      ),
    );
  }
}
