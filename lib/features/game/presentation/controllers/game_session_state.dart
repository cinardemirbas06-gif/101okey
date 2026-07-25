import '../../domain/entities/game_state.dart';
import '../../domain/entities/hand_score_result.dart';

/// Oyun ekranının ihtiyaç duyduğu, [GameState]'in üzerine eklenen UI-only
/// durum (seçili taşlar, hazırlanan per grupları, hata mesajı vb.).
///
/// Bu sınıf bilinçli olarak `freezed` kullanmaz; sık güncellenen, saf
/// UI durumu için basit bir immutable veri sınıfı yeterlidir.
final class GameSessionState {
  const GameSessionState({
    this.gameState,
    this.selectedTileIds = const {},
    this.pendingMeldGroups = const [],
    this.errorMessage,
    this.isAiThinking = false,
    this.lastHandScore,
  });

  final GameState? gameState;

  /// İnsan oyuncunun ıstakasında şu an seçili (vurgulu) taşların
  /// kimlikleri.
  final Set<String> selectedTileIds;

  /// Bu tur içinde hazırlanan, henüz gönderilmemiş per grupları (her biri
  /// bir taş kimliği listesi).
  final List<List<String>> pendingMeldGroups;

  final String? errorMessage;
  final bool isAiThinking;

  /// El bittiğinde hesaplanan puan dökümü; sonuç ekranında gösterilir.
  final HandScoreResult? lastHandScore;

  bool get hasActiveGame => gameState != null;

  GameSessionState copyWith({
    GameState? gameState,
    Set<String>? selectedTileIds,
    List<List<String>>? pendingMeldGroups,
    String? errorMessage,
    bool clearError = false,
    bool? isAiThinking,
    HandScoreResult? lastHandScore,
  }) {
    return GameSessionState(
      gameState: gameState ?? this.gameState,
      selectedTileIds: selectedTileIds ?? this.selectedTileIds,
      pendingMeldGroups: pendingMeldGroups ?? this.pendingMeldGroups,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isAiThinking: isAiThinking ?? this.isAiThinking,
      lastHandScore: lastHandScore ?? this.lastHandScore,
    );
  }
}
