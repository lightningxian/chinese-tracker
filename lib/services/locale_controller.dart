import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The UI language (Indonesian or English), chosen with the ID | EN toggle.
///
/// Saved on this device under [prefsKey] ('en' or 'id'). With nothing saved,
/// the app follows the device language when it is Indonesian and otherwise
/// starts in English.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? deviceLocale})
      : _locale = _fromDevice(
          deviceLocale ?? PlatformDispatcher.instance.locale,
        );

  static const prefsKey = 'app_locale';
  static const supportedLocales = [Locale('en'), Locale('id')];

  Locale _locale;
  Locale get locale => _locale;

  bool get isIndonesian => _locale.languageCode == 'id';

  static Locale _fromDevice(Locale device) =>
      device.languageCode == 'id' ? const Locale('id') : const Locale('en');

  /// Reads the saved choice, if any. Safe to call once at start-up.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsKey);
      if (saved == 'id' || saved == 'en') {
        final next = Locale(saved!);
        if (next != _locale) {
          _locale = next;
          notifyListeners();
        }
      }
    } catch (e) {
      // Storage unavailable (private window, blocked site data): keep the
      // device-based default.
      debugPrint('LocaleController.load failed: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'id' ? 'id' : 'en';
    final next = Locale(code);
    if (next == _locale) return;
    _locale = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, code);
    } catch (e) {
      debugPrint('LocaleController.setLocale could not save: $e');
    }
  }
}
