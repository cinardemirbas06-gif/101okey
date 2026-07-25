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

/// Gerçek 101 Okey taşlarının en-boy oranına (48x64) karşılık gelir.
const double _tileAspectRatio = 64 / 48;

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

    // Uygulama yatay (landscape) kilitlendiğinden (bkz. main.dart), genişlik
    // bol ama yükseklik kısıtlıdır. Taş boyutu bu yüzden yalnızca genişliğe
    // göre değil, ıstaka tepsisine ayrılan yükseklik payına göre de
    // sınırlandırılır — aksi halde geniş bir elde taşlar, tepsiyi ekranın
    // geri kalanının üzerine taşacak kadar büyütülebilir.
    final screenSize = MediaQuery.sizeOf(context);
    final tileCountForSizing = human.hand.isEmpty
        ? 8
        : (human.hand.length / 2).ceil();
    final tileWidthByAvailableWidth =
        (screenSize.width - 32) / (tileCountForSizing + 1);
    final maxRackHeight = screenSize.height * 0.24;
    final tileWidthByAvailableHeight =
        (maxRackHeight - 16) / 2.15 / _tileAspectRatio;
    final tileWidth = tileWidthByAvailableWidth
        .clamp(0.0, tileWidthByAvailableHeight)
        .clamp(26.0, 58.0);
    final tileHeight = tileWidth * _tileAspectRatio;

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

    final rules = gameState.rules;
    final ruleBadges = [
      if (rules.pairsEnabled)
        const _RuleBadge(label: 'Eşli', color: TilePalette.ruleBadgePaired),
      if (settings.validDropHighlightEnabled)
        const _RuleBadge(
          label: 'Yardımlı',
          color: TilePalette.ruleBadgeAssisted,
        ),
      if (rules.scoringRules.okeyFinishMultiplier > 1 ||
          rules.scoringRules.pairFinishMultiplier > 1 ||
          rules.scoringRules.handFinishMultiplier > 1)
        const _RuleBadge(
          label: 'Katlamalı',
          color: TilePalette.ruleBadgeMultiplied,
        ),
      _RuleBadge(
        label: gameState.fixedHandCount != null
            ? 'El ${gameState.handNumber}/${gameState.fixedHandCount}'
            : 'El ${gameState.handNumber}',
        color: TilePalette.ruleBadgeHandCounter,
      ),
    ];

    return GameUiPreferences(
      animationsEnabled: settings.animationsEnabled,
      dropHighlightsEnabled: settings.validDropHighlightEnabled,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [TilePalette.tableNavyDark, TilePalette.tableNavyDarkest],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  handNumber: gameState.handNumber,
                  turnNumber: gameState.turnNumber,
                  lastAction: gameState.lastActionDescription,
                  isAiThinking: session.isAiThinking,
                  ruleBadges: ruleBadges,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                                        gameState.phase ==
                                            GamePhase.waitingForDraw) {
                                      controller.humanTakeDiscard();
                                    }
                                  },
                                  onDiscardDropped: (tile) {
                                    if (isHumanTurn) {
                                      controller.humanDiscard(tile.id);
                                    }
                                  },
                                  tileWidth: tileWidth * 0.75,
                                  tileHeight: tileHeight * 0.75,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: TilePalette.meldAreaBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: TilePalette.meldAreaGridLine,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    const Positioned.fill(
                                      child: _MeldAreaGrid(),
                                    ),
                                    const Positioned.fill(
                                      child: Center(child: _MeldAreaWatermark()),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: gameState.tableMelds.isEmpty
                                          ? const SizedBox.shrink()
                                          : Wrap(
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
                                                  controller
                                                      .humanSwapTileWithTableOkey(
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
                            ],
                          ),
                        ),
                      ),
                      _ActionRail(
                        isHumanTurn: isHumanTurn,
                        phase: gameState.phase,
                        hasDrawn: gameState.hasDrawnThisTurn,
                        selectedCount: session.selectedTileIds.length,
                        hasPendingGroups: session.pendingMeldGroups.isNotEmpty,
                        pairsEnabled: rules.pairsEnabled,
                        onStageSelection: controller.stageSelectionAsGroup,
                        onClearGroups: controller.clearPendingGroups,
                        onOpenMelds: controller.humanOpenMelds,
                        onOpenPairs: controller.humanOpenPairs,
                        onFinishNormal: () =>
                            controller.humanFinish(FinishType.normal),
                        onFinishHand: () =>
                            controller.humanFinish(FinishType.handFinish),
                        onDiscardSelected: session.selectedTileIds.length == 1
                            ? () => controller.humanDiscard(
                                session.selectedTileIds.single,
                              )
                            : null,
                        onSort: settings.handSortMode == HandSortMode.manual
                            ? null
                            : () => controller.humanRearrangeHand(
                                _sortedHandOrder(
                                  human.hand,
                                  settings.handSortMode,
                                ),
                              ),
                      ),
                    ],
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
                      onRemoveTileFromGroup:
                          controller.removeTileFromPendingGroup,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [TilePalette.woodLight, TilePalette.woodDark],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RackSortButton(
                        label: 'Çift Diz',
                        icon: Icons.filter_2,
                        onPressed: human.hand.isEmpty
                            ? null
                            : () => controller.humanRearrangeHand(
                                _sortedHandOrder(
                                  human.hand,
                                  HandSortMode.byNumber,
                                ),
                              ),
                      ),
                      Expanded(
                        child: DragTarget<OkeyTile>(
                          onWillAcceptWithDetails: (_) => true,
                          onAcceptWithDetails: (details) => controller
                              .addTileToPendingGroup(details.data.id),
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
                      _RackSortButton(
                        label: 'Seri Diz',
                        icon: Icons.linear_scale,
                        onPressed: human.hand.isEmpty
                            ? null
                            : () => controller.humanRearrangeHand(
                                _sortedHandOrder(
                                  human.hand,
                                  HandSortMode.byColor,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    required this.ruleBadges,
  });

  final int handNumber;
  final int turnNumber;
  final String? lastAction;
  final bool isAiThinking;
  final List<Widget> ruleBadges;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: TilePalette.tableNavyDarkest,
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
          for (final badge in ruleBadges) ...[
            badge,
            const SizedBox(width: 4),
          ],
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

/// Bir kural rozetini (ör. "Eşli", "Katlamalı") gösteren küçük, renkli hap.
class _RuleBadge extends StatelessWidget {
  const _RuleBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Oyun masasının sağ kenarındaki dikey hamle düğmeleri rayı.
class _ActionRail extends StatelessWidget {
  const _ActionRail({
    required this.isHumanTurn,
    required this.phase,
    required this.hasDrawn,
    required this.selectedCount,
    required this.hasPendingGroups,
    required this.pairsEnabled,
    required this.onStageSelection,
    required this.onClearGroups,
    required this.onOpenMelds,
    required this.onOpenPairs,
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
  final bool pairsEnabled;
  final VoidCallback onStageSelection;
  final VoidCallback onClearGroups;
  final VoidCallback onOpenMelds;
  final VoidCallback onOpenPairs;
  final VoidCallback onFinishNormal;
  final VoidCallback onFinishHand;
  final VoidCallback? onDiscardSelected;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    final canAct = isHumanTurn && phase == GamePhase.waitingForMeld && hasDrawn;

    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: TilePalette.meldAreaGridLine)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _RailButton(
              icon: Icons.lock_open,
              label: 'Seri Aç',
              onPressed: canAct && hasPendingGroups ? onOpenMelds : null,
            ),
            _RailButton(
              icon: Icons.join_full,
              label: 'Çift Aç',
              onPressed: canAct && pairsEnabled ? onOpenPairs : null,
            ),
            _RailButton(
              icon: Icons.undo,
              label: 'Geri Topla',
              onPressed: hasPendingGroups ? onClearGroups : null,
            ),
            _RailButton(
              icon: Icons.grid_view,
              label: 'Taşları İşle',
              onPressed: selectedCount >= 2 ? onStageSelection : null,
            ),
            _RailButton(
              icon: Icons.flag,
              label: 'Bitir',
              onPressed: canAct ? onFinishNormal : null,
            ),
            _RailButton(
              icon: Icons.bolt,
              label: 'Elden Bitir',
              onPressed: canAct && !hasPendingGroups ? onFinishHand : null,
            ),
            _RailButton(
              icon: Icons.arrow_downward,
              label: 'Seçileni At',
              onPressed: canAct ? onDiscardSelected : null,
            ),
            _RailButton(
              icon: Icons.sort,
              label: 'Sırala',
              onPressed: onSort,
            ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: TilePalette.actionRailButton,
          disabledBackgroundColor: TilePalette.actionRailButton.withValues(
            alpha: 0.35,
          ),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(height: 1),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Istaka tepsisinin köşelerindeki hızlı sıralama düğmeleri ("Çift Diz" /
/// "Seri Diz"). Sayı önceliğine göre sıralamak çiftleri/grupları, renk
/// önceliğine göre sıralamak serileri yan yana getirir — bu yüzden
/// gerçek (sahte olmayan) bir işlevi vardır: bkz. `_sortedHandOrder`.
class _RackSortButton extends StatelessWidget {
  const _RackSortButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: TilePalette.tableNavyDarkest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Masaya açılmış perlerin arka planına çizilen çok soluk (blueprint
/// tarzı) izgara dokusu. Salt dekoratiftir, hiçbir hamleyi etkilemez.
class _MeldAreaGrid extends StatelessWidget {
  const _MeldAreaGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MeldAreaGridPainter());
  }
}

class _MeldAreaGridPainter extends CustomPainter {
  static const double _cellSize = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TilePalette.meldAreaGridLine.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += _cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += _cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeldAreaGridPainter oldDelegate) => false;
}

/// Masa alanının ortasındaki, çok soluk uygulama filigranı. Gerçek bir
/// marka/logo varlığı kullanılmaz — yalnızca uygulamanın kendi ikon
/// motifiyle (bkz. ana menü) tutarlı, özgün bir çizim.
class _MeldAreaWatermark extends StatelessWidget {
  const _MeldAreaWatermark();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.grid_view_rounded,
      size: 72,
      color: Colors.white.withValues(alpha: 0.04),
    );
  }
}
