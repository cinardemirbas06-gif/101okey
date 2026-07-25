import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Istakanın otomatik sıralama tercihi.
enum HandSortMode {
  /// Otomatik sıralama kapalı; oyuncu elle/sürükleyerek düzenler.
  manual,

  /// Renge, ardından sayıya göre sırala.
  byColor,

  /// Sayıya, ardından renge göre sırala.
  byNumber,
}

/// Kalıcı olarak saklanan, kullanıcı tarafından değiştirilebilir uygulama
/// ayarları.
///
/// **Kapsam notu:** Bu ayarlar yalnızca UYGULAMADA GERÇEKTEN BİR ETKİSİ
/// OLAN seçenekleri içerir. Ses seviyesi gibi henüz karşılık gelen bir
/// ses motoru bulunmayan ayarlar bilinçli olarak eklenmemiştir (bkz.
/// proje README'si — Aşama 6 kapsam notları).
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(true) bool hapticFeedbackEnabled,
    @Default(true) bool animationsEnabled,
    @Default(HandSortMode.manual) HandSortMode handSortMode,
    @Default(true) bool validDropHighlightEnabled,
    @Default(true) bool turnTimerEnabled,
    @Default(30) int turnDurationSeconds,
    @Default(false) bool largeTextModeEnabled,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  static const AppSettings defaults = AppSettings();
}
