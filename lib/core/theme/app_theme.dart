import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const navy = Color(0xFF1B2A4A);
  static const navyLight = Color(0xFF2A3F66);
  static const teal = Color(0xFF2D6A7E);
  static const tealLight = Color(0xFF3D8A9E);
  static const surface = Color(0xFFF5F6F8);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF5C6370);
  static const border = Color(0xFFE2E5EB);
  static const success = Color(0xFF2E7D5A);
  static const error = Color(0xFFB53A3A);
  static const brandYellow = Color(0xFFF5B800);
  static const brandGreen = Color(0xFF00A651);

  // "LinguaHub" restyle tokens (docs/CURSOR_REDESIGN_PROMPT.md).
  static const sidebarBg = Color(0xFFFFFFFF);
  static const sidebarActive = Color(0xFF14181F);
  static const pageBg = Color(0xFFF6F7F8);

  // Stat-chip pastel tints (background / foreground pairs).
  static const chipGreenBg = Color(0xFFE7F5EF);
  static const chipGreenFg = Color(0xFF2E7D5A);
  static const chipBlueBg = Color(0xFFE8F0FE);
  static const chipBlueFg = Color(0xFF2B5FB0);
  static const chipPurpleBg = Color(0xFFF0EAFB);
  static const chipPurpleFg = Color(0xFF6B4FBF);
  static const chipAmberBg = Color(0xFFFDF3E0);
  static const chipAmberFg = Color(0xFFB7791F);
}

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.navy,
        onPrimary: Colors.white,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.pageBg,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.teal.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            );
          }
          return const TextStyle(fontSize: 12, color: AppColors.textSecondary);
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );

    // Global ~12% text scale is applied in `app.dart` via [TextScaler] — not
    // `fontSizeFactor` here (that assert-fails on some TextTheme styles).
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    final chineseFallback = GoogleFonts.notoSansSc().fontFamily!;

    TextStyle? withChinese(TextStyle? style) => style?.copyWith(
          fontFamilyFallback: [chineseFallback],
        );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        bodyLarge: withChinese(textTheme.bodyLarge),
        bodyMedium: withChinese(textTheme.bodyMedium),
        bodySmall: withChinese(textTheme.bodySmall),
        titleLarge: withChinese(textTheme.titleLarge),
        titleMedium: withChinese(textTheme.titleMedium),
        titleSmall: withChinese(textTheme.titleSmall),
        headlineLarge: withChinese(textTheme.headlineLarge),
        headlineMedium: withChinese(textTheme.headlineMedium),
        headlineSmall: withChinese(textTheme.headlineSmall),
        displayLarge: withChinese(textTheme.displayLarge),
        displayMedium: withChinese(textTheme.displayMedium),
        displaySmall: withChinese(textTheme.displaySmall),
        labelLarge: withChinese(textTheme.labelLarge),
        labelMedium: withChinese(textTheme.labelMedium),
        labelSmall: withChinese(textTheme.labelSmall),
      ),
    );
  }
}
