import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for the signed-in app: direction "A · Pensil, calmer".
///
/// Same brand as the landing page (`lib/features/landing/landing_brand.dart`,
/// colours from the logo) on white surfaces with less decoration: teal is the
/// working colour, yellow is a highlight, green means success.
///
/// Light and dark are two [AppPalette]s. [AppColors] keeps the names the
/// screens already use (`AppColors.navy`, `AppColors.card`, ...) and reads
/// them from the palette that is on: [ThemeController] swaps it before the
/// app rebuilds, so a screen never has to know which mode it is in.
///
/// `navy` and `teal` are legacy names kept so the existing call sites keep
/// compiling; they resolve to the brand primary / secondary. New code should
/// use `primary`, `secondary`, `accent`.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.accent,
    required this.accentSoft,
    required this.ink,
    required this.navyLight,
    required this.brandGreen,
    required this.surface,
    required this.card,
    required this.border,
    required this.tableLine,
    required this.textSecondary,
    required this.error,
    required this.inputFill,
    required this.chipGreenBg,
    required this.chipBlueBg,
    required this.chipPurpleBg,
    required this.chipPurpleFg,
    required this.chipAmberFg,
  });

  final Brightness brightness;
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryLight;
  final Color accent;
  final Color accentSoft;
  final Color ink;
  final Color navyLight;
  final Color brandGreen;
  final Color surface;
  final Color card;
  final Color border;
  final Color tableLine;
  final Color textSecondary;
  final Color error;
  final Color inputFill;
  final Color chipGreenBg;
  final Color chipBlueBg;
  final Color chipPurpleBg;
  final Color chipPurpleFg;
  final Color chipAmberFg;

  bool get isDark => brightness == Brightness.dark;

  /// Brand colours from assets/brand/README.md on warm white surfaces.
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF006B54), // teal: lettering, pencil tip
    primaryDark: Color(0xFF004D3C),
    secondary: Color(0xFF0A8A4E), // green, darkened for text on white
    secondaryLight: Color(0xFF3DBB7A),
    accent: Color(0xFFF5B800), // yellow: pencil body
    accentSoft: Color(0xFFFFF4CC),
    ink: Color(0xFF16211C),
    navyLight: Color(0xFF0E8A6D),
    brandGreen: Color(0xFF00A651),
    surface: Color(0xFFF7F6F1), // warm off-white page
    card: Colors.white,
    border: Color(0xFFE4E2DA),
    tableLine: Color(0xFFCBC7BB),
    textSecondary: Color(0xFF5B665F),
    error: Color(0xFFB53A3A),
    inputFill: Color(0xFFFBFAF6),
    chipGreenBg: Color(0xFFE3F5EA),
    chipBlueBg: Color(0xFFE6F1EE),
    chipPurpleBg: Color(0xFFF0EAFB),
    chipPurpleFg: Color(0xFF6B4FBF),
    chipAmberFg: Color(0xFF8A5A12),
  );

  /// The same brand at night: deep warm-green surfaces, the teal and green
  /// lifted so they still read as text, white kept for text on buttons.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF34A585),
    primaryDark: Color(0xFF237F66),
    secondary: Color(0xFF4FC48A),
    secondaryLight: Color(0xFF7FDCA5),
    accent: Color(0xFFF5C842),
    accentSoft: Color(0xFF3A3418),
    ink: Color(0xFFECEFEA), // text on dark surfaces
    navyLight: Color(0xFF6CC9AE),
    brandGreen: Color(0xFF4FC27A),
    surface: Color(0xFF121614),
    card: Color(0xFF1B211E),
    border: Color(0xFF2E3833),
    tableLine: Color(0xFF3D4943),
    textSecondary: Color(0xFFA3ADA6),
    error: Color(0xFFE06A6A),
    inputFill: Color(0xFF161C19),
    chipGreenBg: Color(0xFF1E3A2C),
    chipBlueBg: Color(0xFF1C3330),
    chipPurpleBg: Color(0xFF2B2540),
    chipPurpleFg: Color(0xFFB9A5F0),
    chipAmberFg: Color(0xFFF2CF6B),
  );
}

/// The colours of the palette that is on. Getters, not constants: a widget
/// using them cannot be `const`, which is what lets the whole tree repaint
/// when the mode changes.
abstract final class AppColors {
  /// The palette in use. Set by [ThemeController] before it notifies.
  static AppPalette palette = AppPalette.light;

  static bool get isDark => palette.isDark;

  // Brand
  static Color get primary => palette.primary;
  static Color get primaryDark => palette.primaryDark;
  static Color get secondary => palette.secondary;
  static Color get secondaryLight => palette.secondaryLight;
  static Color get accent => palette.accent;
  static Color get accentSoft => palette.accentSoft;
  static Color get ink => palette.ink;

  // Legacy names → brand
  static Color get navy => primary;
  static Color get navyLight => palette.navyLight;
  static Color get teal => secondary;
  static Color get tealLight => secondaryLight;
  static Color get brandYellow => accent;
  static Color get brandGreen => palette.brandGreen;

  // Surfaces and text
  static Color get surface => palette.surface;
  static Color get pageBg => surface;
  static Color get card => palette.card;
  static Color get border => palette.border;

  /// Row and column lines inside data tables: darker than [border] so the
  /// grid reads at a glance.
  static Color get tableLine => palette.tableLine;
  static Color get textPrimary => ink;
  static Color get textSecondary => palette.textSecondary;
  static Color get success => secondary;
  static Color get error => palette.error;

  // Sidebar
  static Color get sidebarBg => card;
  static Color get sidebarActive => primary;

  // Stat-chip tints (background / foreground pairs)
  static Color get chipGreenBg => palette.chipGreenBg;
  static Color get chipGreenFg => secondary;
  static Color get chipBlueBg => palette.chipBlueBg;
  static Color get chipBlueFg => primary;
  static Color get chipPurpleBg => palette.chipPurpleBg;
  static Color get chipPurpleFg => palette.chipPurpleFg;
  static Color get chipAmberBg => accentSoft;
  static Color get chipAmberFg => palette.chipAmberFg;
}

/// Text styles shared by the screens that show question content.
abstract final class AppTextStyles {
  /// Chinese text falls back to this family (Lexend has no CJK glyphs).
  /// Kai style, as on the centre's worksheets and in handwriting class.
  static const chineseFamily = 'LXGW WenKai';

  /// A question, sentence or option as the admin or student reads it: larger
  /// than body text and with room between the lines for the Kai strokes.
  static TextStyle get question => TextStyle(
        fontSize: 18,
        height: 1.5,
        color: AppColors.textPrimary,
        fontFamilyFallback: const [chineseFamily],
      );

  /// Secondary line under a question (answer key, pinyin, order).
  static TextStyle get questionDetail => TextStyle(
        fontSize: 15,
        height: 1.5,
        color: AppColors.textSecondary,
        fontFamilyFallback: const [chineseFamily],
      );
}

abstract final class AppTheme {
  static ThemeData light() => build(AppPalette.light);
  static ThemeData dark() => build(AppPalette.dark);

  /// [ThemeData] for one palette. Both themes are built from their own
  /// palette (not from [AppColors]) so `theme` and `darkTheme` are right no
  /// matter which one is on.
  static ThemeData build(AppPalette p) {
    const radius = 12.0;
    const onPrimary = Colors.white;
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: onPrimary,
        secondary: p.secondary,
        onSecondary: onPrimary,
        tertiary: p.accent,
        onTertiary: p.ink,
        surface: p.card,
        onSurface: p.ink,
        error: p.error,
      ),
      scaffoldBackgroundColor: p.surface,
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: p.primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.ink,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.accentSoft,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.accentSoft : p.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.card,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        indicatorColor: p.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? p.primary : p.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: p.primary);
          }
          return TextStyle(fontSize: 12, color: p.textSecondary);
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: p.accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.accentSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? const Color(0xFF2A3430) : p.ink,
        contentTextStyle: TextStyle(color: p.isDark ? p.ink : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1),
    );

    // Global ~12% text scale is applied in `app.dart` via [TextScaler] — not
    // `fontSizeFactor` here (that assert-fails on some TextTheme styles).
    // Lexend is the brand body face (same as the landing page); headings get
    // a heavier weight instead of a second family to keep the inside calm.
    final textTheme = GoogleFonts.lexendTextTheme(base.textTheme).apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    );
    // Chinese glyphs come from the bundled Kai face (pubspec `fonts:`); the
    // report PDFs keep Noto Sans SC (`report_pdf_fonts.dart`).
    TextStyle? withChinese(TextStyle? style, {FontWeight? weight}) =>
        style?.copyWith(
          fontFamilyFallback: const [AppTextStyles.chineseFamily],
          fontWeight: weight ?? style.fontWeight,
        );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        bodyLarge: withChinese(textTheme.bodyLarge),
        bodyMedium: withChinese(textTheme.bodyMedium),
        bodySmall: withChinese(textTheme.bodySmall),
        titleLarge: withChinese(textTheme.titleLarge, weight: FontWeight.w700),
        titleMedium:
            withChinese(textTheme.titleMedium, weight: FontWeight.w600),
        titleSmall: withChinese(textTheme.titleSmall, weight: FontWeight.w600),
        headlineLarge:
            withChinese(textTheme.headlineLarge, weight: FontWeight.w700),
        headlineMedium:
            withChinese(textTheme.headlineMedium, weight: FontWeight.w700),
        headlineSmall:
            withChinese(textTheme.headlineSmall, weight: FontWeight.w700),
        displayLarge:
            withChinese(textTheme.displayLarge, weight: FontWeight.w700),
        displayMedium:
            withChinese(textTheme.displayMedium, weight: FontWeight.w700),
        displaySmall:
            withChinese(textTheme.displaySmall, weight: FontWeight.w700),
        labelLarge: withChinese(textTheme.labelLarge),
        labelMedium: withChinese(textTheme.labelMedium),
        labelSmall: withChinese(textTheme.labelSmall),
      ),
    );
  }
}
