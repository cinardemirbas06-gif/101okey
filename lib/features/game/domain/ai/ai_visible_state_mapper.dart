import '../entities/ai_visible_game_state.dart';
import '../entities/game_state.dart';
import '../entities/player_public_state.dart';

/// [GameState]'ten, tek bir AI oyuncusunun görebileceği bilgilerle
/// sınırlı bir [AiVisibleGameState] üretir.
///
/// **Kritik kural:** Bu fonksiyon [selfPlayerId] dışındaki hiçbir
/// oyuncunun `Player.hand` alanına erişmez/kopyalamaz. AI karar motoru
/// (`AiPlayerEngine` ve alt servisleri) girdisini SADECE bu tür
/// üzerinden alır; `GameState`'in tamamına asla erişemez.
///
/// **Bilinen basitleştirme:** [PlayerPublicState.discardHistoryTileIds]
/// ve [PlayerPublicState.takenFromDiscardTileIds] şu an boş döner; bu
/// oyuncu bazlı geçmiş, `GameMove` hamle geçmişinin dolu biçimde
/// tutulmasını gerektirir (henüz oyun motorlarında etkin değil). AI
/// rakip takibini bunun yerine paylaşılan [AiVisibleGameState.
/// discardHistory] üzerinden yapar.
abstract final class AiVisibleStateMapper {
  const AiVisibleStateMapper._();

  static AiVisibleGameState buildVisibleState(
    GameState state,
    String selfPlayerId,
  ) {
    final self = state.players.firstWhere((p) => p.id == selfPlayerId);
    final opponents = state.players
        .where((p) => p.id != selfPlayerId)
        .map(
          (p) => PlayerPublicState(
            playerId: p.id,
            name: p.name,
            remainingTileCount: p.hand.length,
            hasOpened: p.hasOpened,
            hasOpenedWithPairs: p.hasOpenedWithPairs,
          ),
        )
        .toList(growable: false);

    return AiVisibleGameState(
      selfPlayerId: selfPlayerId,
      ownHand: self.hand,
      discardHistory: state.discardPile,
      tableMelds: state.tableMelds,
      indicatorTile: state.indicatorTile!,
      okeyTile: state.okeyTile!,
      remainingDeckCount: state.drawPile.length,
      opponents: opponents,
      currentDiscardTopTile: state.currentDiscardTopTile,
      selfHasOpened: self.hasOpened,
    );
  }
}
