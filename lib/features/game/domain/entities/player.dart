import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/ai_difficulty.dart';
import '../enums/ai_personality.dart';
import 'meld.dart';
import 'okey_tile.dart';

part 'player.freezed.dart';
part 'player.g.dart';

/// Masadaki bir oyuncuyu (gerçek veya yapay zekâ) temsil eder.
///
/// [hand], oyuncunun ıstakasındaki taşları sırayla tutar; sıralama UI
/// tarafından `RearrangeHand` komutuyla değiştirilebilir ve bu sıralama
/// kalıcı olarak saklanır (kayıt/devam sisteminde de korunur).
@freezed
class Player with _$Player {
  const Player._();

  const factory Player({
    required String id,
    required String name,
    required String avatarId,
    @Default(false) bool isAI,
    AiDifficulty? aiDifficulty,
    AiPersonality? aiPersonality,
    @Default(<OkeyTile>[]) List<OkeyTile> hand,

    /// Bu oyuncunun kendi açılışında ortaya koyduğu perler (henüz masaya
    /// "herkese açık" hale gelmemiş, ama açılış toplamına sayılan perler).
    @Default(<Meld>[]) List<Meld> ownMelds,
    @Default(false) bool hasOpened,
    @Default(false) bool hasOpenedWithPairs,

    /// Bu el içinde biriken ceza/kazanç puanı (henüz seriye eklenmedi).
    @Default(0) int currentHandScore,

    /// Seri oyun boyunca biriken toplam puan.
    @Default(0) int seriesScore,

    /// İleride online multiplayer için; şimdilik hep true.
    @Default(true) bool isConnected,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) =>
      _$PlayerFromJson(json);

  int get tileCount => hand.length;

  bool get isHuman => !isAI;
}
