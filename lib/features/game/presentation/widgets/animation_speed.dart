import 'package:flutter/widgets.dart';

/// Ayarlardaki "Animasyonlar" ve "Geçerli bırakma alanı vurgusu"
/// tercihlerini widget ağacı boyunca taşıyan hafif bir
/// `InheritedWidget`.
///
/// Her animasyonlu/vurgulu widget'a ayrı birer parametre eklemek yerine,
/// taş ve per widget'ları [GameUiPreferences.scaleOf] /
/// [GameUiPreferences.dropHighlightsEnabled] ile bu tercihleri okur.
class GameUiPreferences extends InheritedWidget {
  const GameUiPreferences({
    super.key,
    required this.animationsEnabled,
    required this.dropHighlightsEnabled,
    required super.child,
  });

  final bool animationsEnabled;
  final bool dropHighlightsEnabled;

  static GameUiPreferences? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameUiPreferences>();

  static Duration scaleOf(BuildContext context, Duration normal) =>
      (_of(context)?.animationsEnabled ?? true) ? normal : Duration.zero;

  static bool dropHighlightsEnabledOf(BuildContext context) =>
      _of(context)?.dropHighlightsEnabled ?? true;

  @override
  bool updateShouldNotify(GameUiPreferences oldWidget) =>
      animationsEnabled != oldWidget.animationsEnabled ||
      dropHighlightsEnabled != oldWidget.dropHighlightsEnabled;
}
