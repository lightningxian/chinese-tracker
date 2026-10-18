import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens for the public landing page (design direction "A · Pensil").
///
/// Colours come from the logo artwork (see `assets/brand/README.md`): yellow
/// pencil body, green brush calligraphy, teal lettering and tip, black cap.
/// The signed-in app still uses `AppColors` until the design system lands.
abstract final class LandingBrand {
  static const yellow = Color(0xFFF5B800);
  static const yellowSoft = Color(0xFFFFF4CC);
  static const teal = Color(0xFF006B54);
  static const tealTint = Color(0xFFCFE7DE);
  static const green = Color(0xFF00A651);
  static const ink = Color(0xFF16211C);
  static const ink2 = Color(0xFF4A5A52);
  static const black = Color(0xFF0D0F0E);
  static const white = Colors.white;

  /// Chunky display face, close to the "EASY STUDY" lettering in the logo.
  static TextStyle display({
    double size = 32,
    Color color = teal,
    double height = 0.98,
  }) =>
      GoogleFonts.lilitaOne(
        fontSize: size,
        color: color,
        height: height,
        letterSpacing: 0.3,
      );

  /// Body face designed for reading fluency.
  static TextStyle body({
    double size = 16,
    Color color = ink,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
  }) =>
      GoogleFonts.lexend(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  /// Chinese characters (headline accents, speech bubble).
  static TextStyle han({double size = 28, Color color = ink}) =>
      GoogleFonts.notoSansSc(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        height: 1.1,
      );

  /// The flat "sticker" shadow used on buttons and cards.
  static List<BoxShadow> lift([double offset = 4]) => [
        BoxShadow(color: black, offset: Offset(0, offset)),
      ];

  static BoxDecoration card({
    Color color = white,
    double radius = 18,
    double liftBy = 5,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: black, width: 3),
        boxShadow: lift(liftBy),
      );
}
