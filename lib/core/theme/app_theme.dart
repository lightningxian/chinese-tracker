import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for the signed-in app: direction "A · Pensil, calmer".
///
/// Same brand as the landing page (`lib/features/landing/landing_brand.dart`,
/// colours from the logo) on white surfaces with less decoration: teal is the
/// working colour, yellow is a highlight, green means success.
///
/// `navy` and `teal` are legacy names kept so the ~360 existing call sites keep
/// compiling; they now resolve to the brand primary / secondary. New code
/// should use `primary`, `secondary`, `accent`.
abstract final class AppColors {
  // Brand (from assets/brand/README.md)
  static const primary = Color(0xFF006B54); // teal: lettering, pencil tip
  static const primaryDark = Color(0xFF004D3C);
  static const secondary = Color(0xFF0A8A4E); // green, darkened for text on white
  static const secondaryLight = Color(0xFF3DBB7A);
  static const accent = Color(0xFFF5B800); // yellow: pencil body
  static const accentSoft = Color(0xFFFFF4CC);
  static const ink = Color(0xFF16211C);

  // Legacy names → brand
  static const navy = primary;
  static const navyLight = Color(0xFF0E8A6D);
  static const teal = secondary;
  static const tealLight = secondaryLight;
  static const brandYellow = accent;
  static const brandGreen = Color(0xFF00A651);

  // Surfaces and text
  static const surface = Color(0xFFF7F6F1); // warm off-white page
  static const pageBg = surface;
  static const card = Colors.white;
  static const border = Color(0xFFE4E2DA);
  /// Row and column lines inside data tables: darker than [border] so the
  /// grid reads at a glance.
  static const tableLine = Color(0xFFCBC7BB);
  static const textPrimary = ink;
  static const textSecondary = Color(0xFF5B665F);
  static const success = secondary;
  static const error = Color(0xFFB53A3A);

  // Sidebar
  static const sidebarBg = Colors.white;
  static const sidebarActive = primary;

  // Stat-chip tints (background / foreground pairs)
  static const chipGreenBg = Color(0xFFE3F5EA);
  static const chipGreenFg = secondary;
  static const chipBlueBg = Color(0xFFE6F1EE);
  static const chipBlueFg = primary;
  static const chipPurpleBg = Color(0xFFF0EAFB);
  static const chipPurpleFg = Color(0xFF6B4FBF);
  static const chipAmberBg = accentSoft;
  static const chipAmberFg = Color(0xFF8A5A12);
}

/// Text styles shared by the screens that show question content.
abstract final class AppTextStyles {
  /// Chinese text falls back to this family (Lexend has no CJK glyphs).
  /// Kai style, as on the centre's worksheets and in handwriting class.
  static const chineseFamily = 'LXGW WenKai';

  /// A question, sentence or option as the admin or student reads it: larger
  /// than body text and with room between the lines for the Kai strokes.
  static const question = TextStyle(
    fontSize: 18,
    height: 1.5,
    color: AppColors.textPrimary,
    fontFamilyFallback: [chineseFamily],
  );

  /// Secondary line under a question (answer key, pinyin, order).
  static const questionDetail = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.textSecondary,
    fontFamilyFallback: [chineseFamily],
  );
}

abstract final class AppTheme {
  static ThemeData light() {
    const radius = 12.0;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.accent,
        onTertiary: AppColors.ink,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.pageBg,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.accentSoft,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.accentSoft : AppColors.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textSecondary,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBFAF6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary);
          }
          return const TextStyle(fontSize: 12, color: AppColors.textSecondary);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.accentSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );

    // Global ~12% text scale is applied in `app.dart` via [TextScaler] — not
    // `fontSizeFactor` here (that assert-fails on some TextTheme styles).
    // Lexend is the brand body face (same as the landing page); headings get
    // a heavier weight instead of a second family to keep the inside calm.
    final textTheme = GoogleFonts.lexendTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    // Chinese glyphs come from the bundled Kai face (pubspec `fonts:`); the
    // report PDFs keep Noto Sans SC (`report_pdf_fonts.dart`).
    TextStyle? withChinese(TextStyle? style, {FontWeight? weight}) => style?.copyWith(
          fontFamilyFallback: const [AppTextStyles.chineseFamily],
          fontWeight: weight ?? style.fontWeight,
        );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        bodyLarge: withChinese(textTheme.bodyLarge),
        bodyMedium: withChinese(textTheme.bodyMedium),
        bodySmall: withChinese(textTheme.bodySmall),
        titleLarge: withChinese(textTheme.titleLarge, weight: FontWeight.w700),
        titleMedium: withChinese(textTheme.titleMedium, weight: FontWeight.w600),
        titleSmall: withChinese(textTheme.titleSmall, weight: FontWeight.w600),
        headlineLarge: withChinese(textTheme.headlineLarge, weight: FontWeight.w700),
        headlineMedium: withChinese(textTheme.headlineMedium, weight: FontWeight.w700),
        headlineSmall: withChinese(textTheme.headlineSmall, weight: FontWeight.w700),
        displayLarge: withChinese(textTheme.displayLarge, weight: FontWeight.w700),
        displayMedium: withChinese(textTheme.displayMedium, weight: FontWeight.w700),
        displaySmall: withChinese(textTheme.displaySmall, weight: FontWeight.w700),
        labelLarge: withChinese(textTheme.labelLarge),
        labelMedium: withChinese(textTheme.labelMedium),
        labelSmall: withChinese(textTheme.labelSmall),
      ),
    );
  }
}
