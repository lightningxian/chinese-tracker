import 'package:chinese_tracker/core/theme/app_theme.dart';
import 'package:chinese_tracker/services/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppColors.palette = AppPalette.light;
  });

  test('setMode swaps the palette before notifying and saves the choice',
      () async {
    final controller = ThemeController();
    var paletteWhenNotified = AppColors.palette;
    controller.addListener(() => paletteWhenNotified = AppColors.palette);

    await controller.setMode(ThemeMode.dark);

    expect(paletteWhenNotified, AppPalette.dark);
    expect(AppColors.isDark, isTrue);
    expect(AppColors.card, AppPalette.dark.card);
    expect(AppTextStyles.question.color, AppPalette.dark.ink);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.prefsKey), 'dark');

    await controller.setMode(ThemeMode.light);
    expect(AppColors.card, Colors.white);
    controller.dispose();
  });

  test('load restores a saved mode', () async {
    SharedPreferences.setMockInitialValues({ThemeController.prefsKey: 'dark'});
    final controller = ThemeController();
    expect(controller.mode, ThemeMode.system);

    await controller.load();

    expect(controller.mode, ThemeMode.dark);
    expect(AppColors.palette, AppPalette.dark);
    controller.dispose();
  });

  test('both themes come from their own palette', () {
    AppColors.palette = AppPalette.dark;
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    expect(light.brightness, Brightness.light);
    expect(light.scaffoldBackgroundColor, AppPalette.light.surface);
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, AppPalette.dark.surface);
  });
}
