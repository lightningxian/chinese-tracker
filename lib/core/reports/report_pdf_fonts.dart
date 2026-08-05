import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Loads bundled PDF fonts that support Latin + Chinese characters.
abstract final class ReportPdfFonts {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static const _regularAsset = 'assets/fonts/NotoSansSC-Regular.ttf';
  static const _boldAsset = 'assets/fonts/NotoSansSC-Bold.ttf';

  static Future<pw.ThemeData> loadTheme() async {
    _regular ??= await _loadTtf(_regularAsset);
    _bold ??= await _loadTtf(_boldAsset);
    return pw.ThemeData.withFont(
      base: _regular!,
      bold: _bold!,
    );
  }

  static Future<pw.Font> _loadTtf(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }
}
