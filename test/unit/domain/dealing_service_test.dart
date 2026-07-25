import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/domain/services/dealing_service.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_factory_service.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_indicator_service.dart';
import 'package:okey_101_pro/features/game/domain/services/tile_shuffler_service.dart';

import '../../helpers/test_players.dart';

void main() {
  group('DealingService.deal', () {
    test('başlayan oyuncu 22, diğerleri 21 taş alır', () {
      final random = SeededRandomProvider(1);
      final shuffled = TileShufflerService.shuffle(
        TileFactoryService.createFullSet(),
        random,
      );
      final indicatorDraw = TileIndicatorService.drawIndicator(shuffled);

      final result = DealingService.deal(
        shuffledDeck: indicatorDraw.remainingTiles,
        players: buildTestPlayers(),
        startingPlayerIndex: 2,
      );

      for (var i = 0; i < result.players.length; i++) {
        final expected = i == 2 ? 22 : 21;
        expect(
          result.players[i].hand.length,
          expected,
          reason: 'oyuncu index $i',
        );
      }
    });

    test('dağıtılan taşlar + çekme destesi toplamı 105 taşı korur', () {
      final random = SeededRandomProvider(2);
      final shuffled = TileShufflerService.shuffle(
        TileFactoryService.createFullSet(),
        random,
      );
      final indicatorDraw = TileIndicatorService.drawIndicator(shuffled);

      final result = DealingService.deal(
        shuffledDeck: indicatorDraw.remainingTiles,
        players: buildTestPlayers(),
        startingPlayerIndex: 0,
      );

      final dealtCount = result.players.fold<int>(
        0,
        (sum, p) => sum + p.hand.length,
      );
      expect(dealtCount + result.drawPile.length, 105);
    });

    test('hiçbir fiziksel taş iki farklı elde/destede tekrar etmez', () {
      final random = SeededRandomProvider(3);
      final shuffled = TileShufflerService.shuffle(
        TileFactoryService.createFullSet(),
        random,
      );
      final indicatorDraw = TileIndicatorService.drawIndicator(shuffled);

      final result = DealingService.deal(
        shuffledDeck: indicatorDraw.remainingTiles,
        players: buildTestPlayers(),
        startingPlayerIndex: 1,
      );

      final allIds = [
        ...result.players.expand((p) => p.hand.map((t) => t.id)),
        ...result.drawPile.map((t) => t.id),
      ];
      expect(allIds.toSet().length, allIds.length);
    });

    test('4 oyuncudan farklı sayıda oyuncu ile hata fırlatır', () {
      final random = SeededRandomProvider(4);
      final shuffled = TileShufflerService.shuffle(
        TileFactoryService.createFullSet(),
        random,
      );

      expect(
        () => DealingService.deal(
          shuffledDeck: shuffled,
          players: buildTestPlayers().sublist(0, 3),
          startingPlayerIndex: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
