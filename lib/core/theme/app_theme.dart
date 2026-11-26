import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for the signed-in app.
///
/// Owner 2026-11-26: the first "Pensil" colours (bright teal, yellow, cream)
/// were tiring for daily use. Two calmer styles replace them ([AppStyle]):
/// **Kertas** (paper grey, soft teal, no yellow) for teachers, students and
/// parents, and **Sepia** (warm paper, olive) for admins. The landing page
/// keeps its own `LandingBrand` tokens.
///
/// Each style has a light and a dark [AppPalette]. [AppColors] keeps the
/// names the screens already use (`AppColors.navy`, `AppColors.card`, ...)
/// and reads them from the palette that is on: [ThemeController] swaps it
/// before the app rebuilds, so a screen never has to know which one is on.
///
/// `navy` and `teal` are legacy names kept so the existing call sites keep
/// compiling; they resolve to the primary / secondary. New code should use
/// `primary`, `secondary`, `accent`.
enum AppStyle {
  /// Teachers, students, parents and the sign-in screens.
  kertas,

  /// Admins.
  sepia,
}

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

  /// The palette for a style and brightness.
  static AppPalette of(AppStyle style, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (style) {
      AppStyle.kertas => dark ? kertasDark : kertasLight,
      AppStyle.sepia => dark ? sepiaDark : sepiaLight,
    };
  }

  /// The default (Kertas) palettes.
  static const light = kertasLight;
  static const dark = kertasDark;

  /// Kertas: neutral paper-grey page, white cards, a softened brand teal for
  /// buttons and the active item, sand instead of yellow for highlights.
  static const kertasLight = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF2F6F62),
    primaryDark: Color(0xFF23564C),
    secondary: Color(0xFF3C7A5A), // success, readable as text on white
    secondaryLight: Color(0xFF7FB89A),
    accent: Color(0xFFC9A35E), // sand
    accentSoft: Color(0xFFF3EEE3),
    ink: Color(0xFF22282A),
    navyLight: Color(0xFF4E8A7C),
    brandGreen: Color(0xFF3F8F63),
    surface: Color(0xFFF4F5F3),
    card: Colors.white,
    border: Color(0xFFE3E6E3),
    tableLine: Color(0xFFC9CEC9),
    textSecondary: Color(0xFF636C68),
    error: Color(0xFFB04545),
    inputFill: Color(0xFFFAFBFA),
    chipGreenBg: Color(0xFFE6F0EB),
    chipBlueBg: Color(0xFFE7EFEC),
    chipPurpleBg: Color(0xFFEFEBF6),
    chipPurpleFg: Color(0xFF67589A),
    chipAmberFg: Color(0xFF7A6340),
  );

  /// Kertas at night: soft charcoal, the teal lifted to read as text.
  static const kertasDark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF4E9A86),
    primaryDark: Color(0xFF3B7D6C),
    secondary: Color(0xFF6DB58E),
    secondaryLight: Color(0xFF97CDAE),
    accent: Color(0xFFD4B276),
    accentSoft: Color(0xFF33302A),
    ink: Color(0xFFE4E7E5),
    navyLight: Color(0xFF7DBBAB),
    brandGreen: Color(0xFF6DB58E),
    surface: Color(0xFF16191A),
    card: Color(0xFF1E2224),
    border: Color(0xFF30363A),
    tableLine: Color(0xFF3E4549),
    textSecondary: Color(0xFFA2AAA6),
    error: Color(0xFFDD7373),
    inputFill: Color(0xFF1A1E20),
    chipGreenBg: Color(0xFF22362C),
    chipBlueBg: Color(0xFF1F3330),
    chipPurpleBg: Color(0xFF2C2838),
    chipPurpleFg: Color(0xFFB7AADF),
    chipAmberFg: Color(0xFFDEC28E),
  );

  /// Sepia: warm paper like an e-reader, olive for actions, soft contrast
  /// for long days at the admin tables.
  static const sepiaLight = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF5E6B4F),
    primaryDark: Color(0xFF47523B),
    secondary: Color(0xFF5A7146),
    secondaryLight: Color(0xFF9AAE84),
    accent: Color(0xFFB98A4A),
    accentSoft: Color(0xFFF0E6D4),
    ink: Color(0xFF2E2A24),
    navyLight: Color(0xFF7A8767),
    brandGreen: Color(0xFF6B8A4E),
    surface: Color(0xFFF2EDE3),
    card: Color(0xFFFAF7F1),
    border: Color(0xFFE5DDCE),
    tableLine: Color(0xFFCFC5B2),
    textSecondary: Color(0xFF756C5F),
    error: Color(0xFFA84638),
    inputFill: Color(0xFFFDFBF7),
    chipGreenBg: Color(0xFFE7E9DA),
    chipBlueBg: Color(0xFFE9E6DA),
    chipPurpleBg: Color(0xFFEEE6EA),
    chipPurpleFg: Color(0xFF7A5266),
    chipAmberFg: Color(0xFF7A5A2E),
  );

  /// Sepia at night: warm brown-black, olive and sand lifted.
  static const sepiaDark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF7C8A66),
    primaryDark: Color(0xFF66734F),
    secondary: Color(0xFF9DB585),
    secondaryLight: Color(0xFFBFD0A8),
    accent: Color(0xFFD6AE72),
    accentSoft: Color(0xFF3A3226),
    ink: Color(0xFFEAE3D6),
    navyLight: Color(0xFFB6C2A0),
    brandGreen: Color(0xFF9DB585),
    surface: Color(0xFF1B1915),
    card: Color(0xFF24211C),
    border: Color(0xFF39342C),
    tableLine: Color(0xFF4A443A),
    textSecondary: Color(0xFFB0A795),
    error: Color(0xFFDB7B6B),
    inputFill: Color(0xFF201D19),
    chipGreenBg: Color(0xFF2E3324),
    chipBlueBg: Color(0xFF2E2D25),
    chipPurpleBg: Color(0xFF36292F),
    chipPurpleFg: Color(0xFFD7B3C4),
    chipAmberFg: Color(0xFFE2C08C),
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
  /// Chinese text falls back to this family (the Latin face has no CJK
  /// glyphs). Owner 2026-11-26: a plain sans face that is easy to read for
  /// a long time (Noto Sans SC Regular), never bold (pubspec maps weight 700
  /// to the same Regular file).
  static const chineseFamily = 'Noto Sans SC Reading';

  /// A question, sentence or option as the admin or student reads it: larger
  /// than body text and with room between the lines.
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
  static ThemeData light([AppStyle style = AppStyle.kertas]) =>
      build(AppPalette.of(style, Brightness.light));
  static ThemeData dark([AppStyle style = AppStyle.kertas]) =>
      build(AppPalette.of(style, Brightness.dark));

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
        backgroundColor: p.isDark ? p.border : p.ink,
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
    // Owner 2026-11-26: Noto Sans inside the app, calm for long reading and
    // drawn to match Noto Sans SC (the landing page keeps Lexend). Headings
    // get a heavier weight instead of a second family.
    final textTheme = GoogleFonts.notoSansTextTheme(base.textTheme).apply(
      bodyColor: p.ink,
      displayColor: p.ink,
    );
    // Chinese glyphs come from the bundled Noto Sans SC Reading cut (pubspec
    // `fonts:`), never bold; the report PDFs keep the full Noto Sans SC.
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
