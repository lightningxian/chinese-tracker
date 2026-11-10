import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';

/// Text size steps offered in the Appearance menu. [scale] multiplies every
/// font size in the app; [normal] is the size the app has always used.
enum AppTextSize {
  normal(1.12),
  big(1.28),
  bigger(1.45);

  const AppTextSize(this.scale);
  final double scale;

  static AppTextSize fromName(String? name) => AppTextSize.values.firstWhere(
        (s) => s.name == name,
        orElse: () => AppTextSize.normal,
      );
}

/// Appearance: light, dark or follow the device, plus the text size. Chosen
/// from the menu next to the bell or on the Profile / Account page.
///
/// Saved on this device under [prefsKey] ('light', 'dark' or 'system'; nothing
/// saved means follow the device) and [textSizeKey]. The controller also owns
/// the palette the screens read through `AppColors`: it swaps the palette
/// first and notifies after, so the rebuild that follows already paints the
/// new colours.
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeController() {
    WidgetsBinding.instance.addObserver(this);
    _apply();
  }

  static const prefsKey = 'app_theme';
  static const textSizeKey = 'app_text_size';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  AppTextSize _textSize = AppTextSize.normal;
  AppTextSize get textSize => _textSize;

  /// The brightness the app is showing right now.
  Brightness get brightness => switch (_mode) {
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
        ThemeMode.system => PlatformDispatcher.instance.platformBrightness,
      };

  bool get isDark => brightness == Brightness.dark;

  /// Reads the saved choice, if any. Safe to call once at start-up.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = _parse(prefs.getString(prefsKey));
      final savedSize = prefs.getString(textSizeKey);
      var changed = false;
      if (saved != null && saved != _mode) {
        _mode = saved;
        _apply();
        changed = true;
      }
      if (savedSize != null) {
        final size = AppTextSize.fromName(savedSize);
        if (size != _textSize) {
          _textSize = size;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    } catch (e) {
      // Storage unavailable (private window, blocked site data): follow the
      // device.
      debugPrint('ThemeController.load failed: $e');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    _apply();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, mode.name);
    } catch (e) {
      debugPrint('ThemeController.setMode could not save: $e');
    }
  }

  Future<void> setTextSize(AppTextSize size) async {
    if (size == _textSize) return;
    _textSize = size;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(textSizeKey, size.name);
    } catch (e) {
      debugPrint('ThemeController.setTextSize could not save: $e');
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode != ThemeMode.system) return;
    _apply();
    notifyListeners();
  }

  void _apply() {
    AppColors.palette = isDark ? AppPalette.dark : AppPalette.light;
  }

  static ThemeMode? _parse(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => null,
      };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
