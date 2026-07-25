import '../../../../core/constants/game_constants.dart';
import '../entities/okey_tile.dart';
import '../entities/player.dart';

/// [DealingService.deal] sonucu: taşları dağıtılmış oyuncular ve geri
/// kalan kapalı çekme destesi.
final class DealResult {
  const DealResult({required this.players, required this.drawPile});

  final List<Player> players;
  final List<OkeyTile> drawPile;
}

/// Taşların oyunculara kurallara uygun biçimde dağıtılması.
///
/// Başlayan oyuncu 22, diğer oyuncular 21 taş alır. Dağıtım, gerçek
/// masadaki gibi oyuncular arasında sırayla (round-robin) yapılır; bu
/// sayede başlayan oyuncu doğal olarak en son ekstra taşını alır.
abstract final class DealingService {
  const DealingService._();

  static DealResult deal({
    required List<OkeyTile> shuffledDeck,
    required List<Player> players,
    required int startingPlayerIndex,
  }) {
    if (players.length != GameConstants.playerCount) {
      throw ArgumentError(
        'Dağıtım tam olarak ${GameConstants.playerCount} oyuncu gerektirir, '
        '${players.length} verildi.',
      );
    }
    if (startingPlayerIndex < 0 || startingPlayerIndex >= players.length) {
      throw RangeError.index(startingPlayerIndex, players, 'startingPlayerIndex');
    }

    final targetCounts = List<int>.filled(
      players.length,
      GameConstants.otherPlayersHandSize,
    );
    targetCounts[startingPlayerIndex] = GameConstants.startingPlayerHandSize;
    final totalToDeal = targetCounts.reduce((a, b) => a + b);

    if (shuffledDeck.length < totalToDeal) {
      throw StateError(
        'Dağıtım için yeterli taş yok: gerekli $totalToDeal, '
        'mevcut ${shuffledDeck.length}.',
      );
    }

    final hands = List<List<OkeyTile>>.generate(
      players.length,
      (_) => <OkeyTile>[],
    );

    var deckCursor = 0;
    var dealt = 0;
    var playerIndex = startingPlayerIndex;
    while (dealt < totalToDeal) {
      if (hands[playerIndex].length < targetCounts[playerIndex]) {
        hands[playerIndex].add(shuffledDeck[deckCursor]);
        deckCursor++;
        dealt++;
      }
      playerIndex = (playerIndex + 1) % players.length;
    }

    final updatedPlayers = [
      for (var i = 0; i < players.length; i++)
        players[i].copyWith(hand: List.unmodifiable(hands[i])),
    ];
    final remainingDrawPile = shuffledDeck.sublist(deckCursor);

    return DealResult(
      players: updatedPlayers,
      drawPile: List.unmodifiable(remainingDrawPile),
    );
  }
}
