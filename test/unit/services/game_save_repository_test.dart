import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/core/errors/game_exceptions.dart';
import 'package:okey_101_pro/core/random/random_provider.dart';
import 'package:okey_101_pro/features/game/data/game_save_repository.dart';
import 'package:okey_101_pro/features/game/domain/entities/game_rules_config.dart';
import 'package:okey_101_pro/features/game/domain/enums/game_mode.dart';
import 'package:okey_101_pro/features/game/domain/services/game_setup_service.dart';
import 'package:okey_101_pro/services/storage/hive_storage_service.dart';

import '../../helpers/test_players.dart';
import '../../helpers/test_storage.dart';

void main() {
  setUp(() async {
    await resetTestStorage();
  });

  group('GameSaveRepository', () {
    test('kayıt yoksa hasSavedGame false ve load null döner', () async {
      expect(await GameSaveRepository.hasSavedGame(), isFalse);
      expect(await GameSaveRepository.load(), isNull);
    });

    test('save/load round-trip GameState\'i tam olarak korur', () async {
      final original = GameSetupService.createNewGame(
        gameId: 'save_test',
        seed: 5,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(5),
      );

      await GameSaveRepository.save(original);

      expect(await GameSaveRepository.hasSavedGame(), isTrue);
      final loaded = await GameSaveRepository.load();

      expect(loaded, isNotNull);
      expect(loaded!.gameId, original.gameId);
      expect(
        loaded.players.map((p) => p.hand.map((t) => t.id).toList()),
        original.players.map((p) => p.hand.map((t) => t.id).toList()),
      );
      expect(loaded.indicatorTile?.id, original.indicatorTile?.id);
    });

    test('clear kaydı tamamen kaldırır', () async {
      final original = GameSetupService.createNewGame(
        gameId: 'save_test_2',
        seed: 6,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(6),
      );
      await GameSaveRepository.save(original);
      await GameSaveRepository.clear();

      expect(await GameSaveRepository.hasSavedGame(), isFalse);
    });

    test('şema sürümü uyuşmazlığında kayıt silinir ve hata fırlatılır', () async {
      final original = GameSetupService.createNewGame(
        gameId: 'save_test_3',
        seed: 7,
        gameMode: GameMode.singleHand,
        rules: GameRulesConfig.standard,
        players: buildTestPlayers(),
        random: SeededRandomProvider(7),
      );
      await GameSaveRepository.save(original);

      // Şema sürümünü bozarak uyumsuzluk simüle et.
      await HiveStorageService.savedGameBox.put(
        'save_schema_version',
        999,
      );

      await expectLater(
        GameSaveRepository.load(),
        throwsA(isA<SaveVersionMismatchException>()),
      );
      expect(await GameSaveRepository.hasSavedGame(), isFalse);
    });

    test('bozuk JSON verisinde kayıt silinir ve hata fırlatılır', () async {
      final box = HiveStorageService.savedGameBox;
      await box.put('current_game_state', 'gecersiz-json-{');
      await box.put('save_schema_version', 1);

      await expectLater(
        GameSaveRepository.load(),
        throwsA(isA<SaveDataCorruptedException>()),
      );
      expect(await GameSaveRepository.hasSavedGame(), isFalse);
    });
  });
}
