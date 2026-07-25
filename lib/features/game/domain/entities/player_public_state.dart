import 'package:freezed_annotation/freezed_annotation.dart';

import 'meld.dart';

part 'player_public_state.freezed.dart';
part 'player_public_state.g.dart';

/// Bir oyuncu hakkında diğer tüm oyuncuların (ve AI'ların) görebildiği,
/// kapalı el bilgisi İÇERMEYEN kamuya açık durum.
///
/// AI motoru rakiplerinin kararlarını yalnızca bu tür üzerinden
/// değerlendirir; `Player.hand` alanına asla erişemez.
@freezed
class PlayerPublicState with _$PlayerPublicState {
  const factory PlayerPublicState({
    required String playerId,
    required String name,
    required int remainingTileCount,
    required bool hasOpened,
    required bool hasOpenedWithPairs,
    required List<Meld> ownMelds,

    /// Bu oyuncunun bu el içinde çektiği/aldığı ve attığı taşların
    /// geçmişi; AI'ın rakip takibi yapabilmesi için gereklidir.
    @Default(<String>[]) List<String> discardHistoryTileIds,
    @Default(<String>[]) List<String> takenFromDiscardTileIds,
  }) = _PlayerPublicState;

  factory PlayerPublicState.fromJson(Map<String, dynamic> json) =>
      _$PlayerPublicStateFromJson(json);
}
