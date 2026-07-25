import 'package:flutter_test/flutter_test.dart';
import 'package:okey_101_pro/features/settings/data/settings_repository.dart';
import 'package:okey_101_pro/features/settings/domain/app_settings.dart';

import '../../helpers/test_storage.dart';

void main() {
  setUp(() async {
    await resetTestStorage();
  });

  group('SettingsRepository', () {
    test('kayıt yokken varsayılan ayarları döner', () {
      expect(SettingsRepository.load(), AppSettings.defaults);
    });

    test('save/load round-trip özelleştirilmiş ayarları korur', () async {
      const customized = AppSettings(
        hapticFeedbackEnabled: false,
        handSortMode: HandSortMode.byNumber,
        turnDurationSeconds: 45,
        largeTextModeEnabled: true,
      );

      await SettingsRepository.save(customized);
      final loaded = SettingsRepository.load();

      expect(loaded, customized);
    });
  });
}
