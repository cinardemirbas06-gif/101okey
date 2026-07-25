import 'package:freezed_annotation/freezed_annotation.dart';

import 'meld.dart';
import 'okey_tile.dart';
import 'player_public_state.dart';

part 'ai_visible_game_state.freezed.dart';

/// AI karar motoruna verilen, GÖRÜNÜR oyun durumuyla sınırlı girdi.
///
/// **Kritik kural:** AI hile yapmamalıdır. Bu tür yalnızca kendi eli ve
/// tüm oyuncuların görebildiği bilgileri içerir; rakiplerin kapalı
/// taşlarına hiçbir alan üzerinden erişim yoktur. `AiVisibleGameStateMapper`
/// (domain/ai) bunu `GameState`'ten türetirken rakip ellerini bilinçli
/// olarak dışarıda bırakır.
@freezed
class AiVisibleGameState with _$AiVisibleGameState {
  const factory AiVisibleGameState({
    required String selfPlayerId,
    required List<OkeyTile> ownHand,
    required List<OkeyTile> discardHistory,
    required List<Meld> tableMelds,
    required OkeyTile indicatorTile,
    required OkeyTile okeyTile,
    required int remainingDeckCount,
    required List<PlayerPublicState> opponents,
    OkeyTile? currentDiscardTopTile,
    required bool selfHasOpened,
  }) = _AiVisibleGameState;
}
