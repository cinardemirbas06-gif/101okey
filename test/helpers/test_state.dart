import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_state.dart';
import 'package:okey_101_pro/features/game/domain/entities/meld.dart';
import 'package:okey_101_pro/features/game/domain/entities/okey_tile.dart';
import 'package:okey_101_pro/features/game/domain/entities/player.dart';
import 'package:okey_101_pro/features/game/domain/enums/enums.dart';

/// Testlerde per/tur motorlarını izole biçimde çalıştırmak için, tam
/// rastgele kurulumdan geçmeden doğrudan kontrollü bir [GameState]
/// üretir.
GameState buildTestGameState({
  required List<Player> players,
  GameRulesConfig rules = GameRulesConfig.standard,
  int activePlayerIndex = 0,
  GamePhase phase = GamePhase.waitingForMeld,
  TurnDirection turnDirection = TurnDirection.counterClockwise,
  List<Meld> tableMelds = const [],
  List<OkeyTile> drawPile = const [],
  List<OkeyTile> discardPile = const [],
  bool hasDrawnThisTurn = true,
}) {
  return GameState(
    gameId: 'test_game',
    seed: 1,
    gameMode: GameMode.singleHand,
    rules: rules,
    phase: phase,
    players: players,
    activePlayerIndex: activePlayerIndex,
    turnDirection: turnDirection,
    handNumber: 1,
    turnNumber: 1,
    drawPile: drawPile,
    discardPile: discardPile,
    tableMelds: tableMelds,
    hasDrawnThisTurn: hasDrawnThisTurn,
  );
}

/// Kısa yoldan normal (joker olmayan) taş oluşturur.
OkeyTile normalTile(String id, TileColor color, int number) => OkeyTile(
  id: id,
  color: color,
  number: number,
  type: TileType.normal,
);

/// Kısa yoldan gerçek okey (joker) taşı oluşturur.
OkeyTile okeyJoker(String id, TileColor color, int number) => OkeyTile(
  id: id,
  color: color,
  number: number,
  type: TileType.okey,
  isOkey: true,
);

/// Kısa yoldan sahte okey taşı oluşturur.
OkeyTile falseOkeyJoker(String id) => OkeyTile(
  id: id,
  color: TileColor.red,
  number: 0,
  type: TileType.falseOkey,
  isFalseOkey: true,
);
