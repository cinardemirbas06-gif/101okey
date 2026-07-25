import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/data/game_save_repository.dart';
import '../../../statistics/data/statistics_repository.dart';
import '../../domain/app_settings.dart';
import '../controllers/settings_controller.dart';

/// Ayarlar ekranı.
///
/// Yalnızca uygulamada gerçekten bir etkisi olan ayarlar burada yer
/// alır (bkz. proje README'si, Aşama 6/7 kapsam notları). Ses seviyesi
/// gibi henüz karşılık gelen bir ses motoru olmayan ayarlar eklenmemiştir.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Titreşim geri bildirimi'),
            subtitle: const Text('Geçersiz hamle ve taş atmada titreşim'),
            value: settings.hapticFeedbackEnabled,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(hapticFeedbackEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Animasyonlar'),
            subtitle: const Text('Kapatılırsa hızlı oyun için geçişler anlık olur'),
            value: settings.animationsEnabled,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(animationsEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Geçerli bırakma alanı vurgusu'),
            subtitle: const Text('Sürükleme sırasında hedef alanları yeşille vurgula'),
            value: settings.validDropHighlightEnabled,
            onChanged: (v) => controller.update(
              (s) => s.copyWith(validDropHighlightEnabled: v),
            ),
          ),
          SwitchListTile(
            title: const Text('Büyük yazı modu'),
            subtitle: const Text('Erişilebilirlik için metinleri büyüt'),
            value: settings.largeTextModeEnabled,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(largeTextModeEnabled: v)),
          ),
          const Divider(),
          ListTile(
            title: const Text('Istaka otomatik sıralama'),
            subtitle: Text(_sortModeLabel(settings.handSortMode)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<HandSortMode>(
              segments: const [
                ButtonSegment(
                  value: HandSortMode.manual,
                  label: Text('Elle'),
                ),
                ButtonSegment(
                  value: HandSortMode.byColor,
                  label: Text('Renge göre'),
                ),
                ButtonSegment(
                  value: HandSortMode.byNumber,
                  label: Text('Sayıya göre'),
                ),
              ],
              selected: {settings.handSortMode},
              onSelectionChanged: (selection) => controller.update(
                (s) => s.copyWith(handSortMode: selection.first),
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Tur süresi sınırı'),
            subtitle: Text(
              settings.turnTimerEnabled
                  ? '${settings.turnDurationSeconds} saniye'
                  : 'Sınırsız',
            ),
            value: settings.turnTimerEnabled,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(turnTimerEnabled: v)),
          ),
          if (settings.turnTimerEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 15, label: Text('15sn')),
                  ButtonSegment(value: 30, label: Text('30sn')),
                  ButtonSegment(value: 45, label: Text('45sn')),
                  ButtonSegment(value: 60, label: Text('60sn')),
                ],
                selected: {settings.turnDurationSeconds},
                onSelectionChanged: (selection) => controller.update(
                  (s) => s.copyWith(turnDurationSeconds: selection.first),
                ),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('İstatistikleri sıfırla'),
            onTap: () => _confirmAndRun(
              context,
              title: 'İstatistikleri sıfırla',
              message: 'Tüm istatistikleriniz kalıcı olarak silinecek.',
              action: StatisticsRepository.reset,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Kayıtlı oyunu sil'),
            onTap: () => _confirmAndRun(
              context,
              title: 'Kayıtlı oyunu sil',
              message: 'Devam eden el varsa silinecek.',
              action: GameSaveRepository.clear,
            ),
          ),
        ],
      ),
    );
  }

  String _sortModeLabel(HandSortMode mode) => switch (mode) {
    HandSortMode.manual => 'Elle düzenleniyor',
    HandSortMode.byColor => 'Renge göre sıralanıyor',
    HandSortMode.byNumber => 'Sayıya göre sıralanıyor',
  };

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem tamamlandı.')),
        );
      }
    }
  }
}
