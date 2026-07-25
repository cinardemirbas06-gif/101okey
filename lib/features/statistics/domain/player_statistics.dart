import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_statistics.freezed.dart';
part 'player_statistics.g.dart';

/// Gerçek (insan) oyuncunun cihazda kalıcı olarak saklanan istatistikleri.
@freezed
class PlayerStatistics with _$PlayerStatistics {
  const PlayerStatistics._();

  const factory PlayerStatistics({
    @Default(0) int handsPlayed,
    @Default(0) int handsWon,
    @Default(0) int handsLost,
    @Default(0) int normalFinishCount,
    @Default(0) int okeyFinishCount,
    @Default(0) int pairFinishCount,
    @Default(0) int handFinishCount,
    @Default(0) int highestOpeningScore,
    @Default(0) int totalOpeningScore,
    @Default(0) int openingCount,
    @Default(0) int longestWinStreak,
    @Default(0) int currentWinStreak,
    @Default(0) int totalTilesDiscarded,
    @Default(0) int totalTilesDrawnFromDeck,
    @Default(0) int totalTilesTakenFromDiscard,
  }) = _PlayerStatistics;

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatisticsFromJson(json);

  static const PlayerStatistics empty = PlayerStatistics();

  double get winRate => handsPlayed == 0 ? 0 : handsWon / handsPlayed;

  double get averageOpeningScore =>
      openingCount == 0 ? 0 : totalOpeningScore / openingCount;

  double get discardPileTakeRate {
    final totalDraws = totalTilesDrawnFromDeck + totalTilesTakenFromDiscard;
    return totalDraws == 0 ? 0 : totalTilesTakenFromDiscard / totalDraws;
  }
}
