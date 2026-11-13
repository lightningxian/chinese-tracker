import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../models/ai_worksheet.dart';

/// The pages of a scanned paper as bitmaps, to cut the pictures the AI
/// reader located ([AiBox]) out of them. A PDF is rendered page by page on
/// demand; an image file is one page.
class WorksheetPageImages {
  WorksheetPageImages._(this._pdf, this._single);

  final PdfDocument? _pdf;
  final img.Image? _single;
  final Map<int, img.Image> _rendered = {};

  /// Render scale for PDF pages: enough for a crisp picture, small enough
  /// for the browser.
  static const _scale = 2.0;

  static Future<WorksheetPageImages> open(
    Uint8List bytes, {
    required bool isPdf,
  }) async {
    if (isPdf) {
      return WorksheetPageImages._(await PdfDocument.openData(bytes), null);
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Could not decode the image.');
    return WorksheetPageImages._(null, decoded);
  }

  int get pageCount => _pdf?.pages.length ?? 1;

  Future<img.Image> _page(int page) async {
    final single = _single;
    if (single != null) return single;
    final cached = _rendered[page];
    if (cached != null) return cached;
    final doc = _pdf!;
    if (page < 1 || page > doc.pages.length) {
      throw StateError('Page $page is not in the file.');
    }
    final pdfPage = doc.pages[page - 1];
    final width = (pdfPage.width * _scale).round().clamp(1, 4096);
    final height = (pdfPage.height * _scale).round().clamp(1, 4096);
    final rendered = await pdfPage.render(
      width: width,
      height: height,
      fullWidth: pdfPage.width * _scale,
      fullHeight: pdfPage.height * _scale,
    );
    if (rendered == null) throw StateError('Could not render page $page.');
    try {
      final bitmap = img.Image.fromBytes(
        width: rendered.width,
        height: rendered.height,
        bytes: rendered.pixels.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      // The renderer's buffer is reused: keep our own copy.
      final copy = bitmap.clone();
      _rendered[page] = copy;
      return copy;
    } finally {
      rendered.dispose();
    }
  }

  /// PNG of the box, with a small margin so a tight box does not clip.
  Future<Uint8List> crop(AiBox box) async {
    final page = await _page(box.page);
    const pad = 6; // thousandths of the page
    double f(int v) => (v / 1000).clamp(0.0, 1.0);
    final x0 = (f(box.xmin - pad) * page.width).floor();
    final y0 = (f(box.ymin - pad) * page.height).floor();
    final x1 = (f(box.xmax + pad) * page.width).ceil();
    final y1 = (f(box.ymax + pad) * page.height).ceil();
    final w = (x1 - x0).clamp(1, page.width - x0);
    final h = (y1 - y0).clamp(1, page.height - y0);
    final cropped = img.copyCrop(page, x: x0, y: y0, width: w, height: h);
    return Uint8List.fromList(img.encodePng(cropped));
  }

  Future<void> dispose() async {
    _rendered.clear();
    await _pdf?.dispose();
  }
}
