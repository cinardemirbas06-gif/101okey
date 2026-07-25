import 'package:collection/collection.dart';

import '../../../../core/random/random_provider.dart';
import '../entities/game_rules_config.dart';
import '../entities/game_state.dart';
import '../entities/player.dart';
import '../enums/game_mode.dart';
import '../enums/game_phase.dart';
import '../enums/turn_direction.dart';
import 'dealing_service.dart';
import 'tile_factory_service.dart';
import 'tile_indicator_service.dart';
import 'tile_shuffler_service.dart';

/// Yeni bir eli, taş üretiminden ilk oynanabilir [GameState]'e kadar
/// uçtan uca kuran orkestrasyon servisi.
///
/// Sıra: taş seti oluştur → karıştır → gösterge çek → okeyi hesapla →
/// kalan desteyi okeye göre işaretle → dağıt → başlangıç durumunu üret.
///
/// Başlayan oyuncu, kurallara göre taş çekmeden 22 taşla başladığı için
/// üretilen [GameState] doğrudan [GamePhase.waitingForMeld] fazında ve
/// `hasDrawnThisTurn: true` olarak döner (bkz. proje gereksinimleri #5).
abstract final class GameSetupService {
  const GameSetupService._();

  static GameState createNewGame({
    required String gameId,
    required int seed,
    required GameMode gameMode,
    required GameRulesConfig rules,
    required List<Player> players,
    required RandomProvider random,
    int? startingPlayerIndex,
    int? targetScore,
    int? fixedHandCount,
    int handNumber = 1,
    TurnDirection turnDirection = TurnDirection.counterClockwise,
  }) {
    if (players.length != rules.requiredPlayerCount) {
      throw ArgumentError(
        'Oyuncu sayısı (${players.length}) kural setinin beklediği '
        '${rules.requiredPlayerCount} ile uyuşmuyor.',
      );
    }

    final freshTiles = TileFactoryService.createFullSet();
    final shuffled = TileShufflerService.shuffle(freshTiles, random);
    final indicatorDraw = TileIndicatorService.drawIndicator(shuffled);
    final okeyDesignation = TileIndicatorService.calculateOkey(
      indicatorDraw.indicatorTile,
    );
    final markedDeck = TileIndicatorService.applyOkeyDesignation(
      indicatorDraw.remainingTiles,
      okeyDesignation,
    );

    final starter = startingPlayerIndex ?? random.nextInt(players.length);
    final dealResult = DealingService.deal(
      shuffledDeck: markedDeck,
      players: players,
      startingPlayerIndex: starter,
    );

    final canonicalOkeyTile = dealResult.players
        .expand((p) => p.hand)
        .followedBy(dealResult.drawPile)
        .where((t) => t.isOkey)
        .firstOrNull;

    return GameState(
      gameId: gameId,
      seed: seed,
      gameMode: gameMode,
      rules: rules,
      phase: GamePhase.waitingForMeld,
      players: dealResult.players,
      activePlayerIndex: starter,
      turnDirection: turnDirection,
      handNumber: handNumber,
      turnNumber: 1,
      drawPile: dealResult.drawPile,
      discardPile: const [],
      indicatorTile: indicatorDraw.indicatorTile,
      okeyTile: canonicalOkeyTile,
      hasDrawnThisTurn: true,
      turnStartedAt: DateTime.now(),
      targetScore: targetScore,
      fixedHandCount: fixedHandCount,
      lastActionDescription:
          '${players[starter].name} ile yeni el başladı. '
          'Gösterge: ${indicatorDraw.indicatorTile.color.label} '
          '${indicatorDraw.indicatorTile.number}, Okey: $okeyDesignation.',
    );
  }
}
