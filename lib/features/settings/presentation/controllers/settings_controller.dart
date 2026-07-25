import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../domain/app_settings.dart';

/// Kalıcı uygulama ayarlarını yöneten controller. Her değişiklik anında
/// diske yazılır.
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(SettingsRepository.load());

  void update(AppSettings Function(AppSettings current) updater) {
    state = updater(state);
    unawaited(SettingsRepository.save(state));
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>(
      (ref) => SettingsController(),
    );
