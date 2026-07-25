import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/finish_type.dart';

part 'game_action.freezed.dart';
part 'game_action.g.dart';

/// UI katmanının oyun motoruna gönderebileceği tüm komutlar.
///
/// **Kritik kural:** UI tarafından gönderilen hiçbir [GameAction] doğrudan
/// kabul edilmez. Her komut `GameEngine` içinde sırayla: oyuncunun sırası mı,
/// doğru aşamada mı, taş oyuncuda mı, per geçerli mi, açılış toplamı yeterli
/// mi gibi kontrollerden geçer (bkz. `domain/rules/action_validator.dart`).
@freezed
sealed class GameAction with _$GameAction {
  /// Kapalı desteden taş çekme.
  const factory GameAction.drawFromDeck({
    required String playerId,
  }) = DrawFromDeck;

  /// Ortadaki (önceki oyuncunun attığı) açık taşı alma.
  const factory GameAction.takeDiscardedTile({
    required String playerId,
  }) = TakeDiscardedTile;

  /// Oyuncunun kendi ilk perlerini açması (101 açılış denemesi).
  /// [tileGroups], her biri bir per olacak şekilde gruplanmış taş
  /// kimlikleri listesidir.
  const factory GameAction.openMelds({
    required String playerId,
    required List<List<String>> tileGroups,
  }) = OpenMelds;

  /// Elindeki bir taşı masadaki mevcut bir pere ekleme.
  const factory GameAction.addTileToMeld({
    required String playerId,
    required String tileId,
    required String meldId,
    required int position,
  }) = AddTileToMeld;

  /// Masadaki bir perde bulunan okeyi, elindeki gerçek taşla değiştirme.
  const factory GameAction.swapTileWithTableOkey({
    required String playerId,
    required String handTileId,
    required String meldId,
    required int meldPosition,
  }) = SwapTileWithTableOkey;

  /// Istakadaki taşların sırasını değiştirme (sürükle-bırak / otomatik
  /// sıralama sonucu).
  const factory GameAction.rearrangeHand({
    required String playerId,
    required List<String> orderedTileIds,
  }) = RearrangeHand;

  /// Elden bir taş atarak turu bitirme.
  const factory GameAction.discardTile({
    required String playerId,
    required String tileId,
  }) = DiscardTile;

  /// Eli bitirme denemesi.
  const factory GameAction.finishHand({
    required String playerId,
    required FinishType finishType,
    List<List<String>>? finalTileGroups,
  }) = FinishHand;

  /// Oyuncunun kendi turu içinde, henüz tamamlanmamış son hareketini geri
  /// alması (taş çekme/atma gibi geri alınamaz aksiyonlar hariç).
  const factory GameAction.undoLastMove({
    required String playerId,
  }) = UndoLastMove;

  factory GameAction.fromJson(Map<String, dynamic> json) =>
      _$GameActionFromJson(json);
}
