import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import 'paper_image_ops.dart';
import 'paper_ocr.dart';

/// One page as the built-in reader saw it.
class PaperPage {
  const PaperPage({
    required this.number,
    required this.width,
    required this.height,
    required this.text,
    required this.png,
    required this.pictureBoxes,
  });

  /// 1-based page of the file.
  final int number;
  final int width;
  final int height;

  /// What the engine read (page mode 6, watermark removed).
  final String text;

  /// The cleaned page, shown on the proofreading screen and cut for
  /// pictures.
  final Uint8List png;

  /// Large non-text regions, in reading order (pictures of a picture page).
  final List<PixelBox> pictureBoxes;
}

/// One rendered page before reading: RGBA bytes.
class RgbaPage {
  const RgbaPage(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;
}

/// Progress: fraction 0–1, page being read (1-based) and page count.
typedef PaperReadProgress = void Function(double fraction, int page, int pages);

class HskPaperReaderException implements Exception {
  const HskPaperReaderException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The built-in HSK paper reader (docs/PLAN.md, Build 1B): every page is
/// rendered in the browser, the watermark removed, the text read with page
/// mode 6 and the picture boxes found. Nothing leaves the computer.
class HskPaperReader {
  HskPaperReader({PaperOcrEngine? engine})
      : _engine = engine ?? const BrowserPaperOcrEngine();

  final PaperOcrEngine _engine;

  /// The page mode the reader always uses (one uniform block of text).
  static const pageMode = 6;

  /// Up to 30 pages on this path (the old scanner stops at 8).
  static const maxPages = 30;

  /// Page width in pixels: about 3× a 72-dpi A4 page, as measured.
  static const renderWidth = 1738;

  Future<List<PaperPage>> readPdf(
    Uint8List bytes, {
    PaperReadProgress? onProgress,
  }) async {
    final doc = await PdfDocument.openData(bytes);
    try {
      final count = doc.pages.length;
      if (count > maxPages) {
        throw HskPaperReaderException(
            'This paper has $count pages; the reader takes up to $maxPages.');
      }
      final out = <PaperPage>[];
      for (var i = 0; i < count; i++) {
        onProgress?.call(i / count, i + 1, count);
        final page = doc.pages[i];
        final scale = renderWidth / page.width;
        const w = renderWidth;
        final h = (page.height * scale).round().clamp(1, 6000);
        final rendered = await page.render(
          width: w,
          height: h,
          fullWidth: page.width * scale,
          fullHeight: page.height * scale,
          backgroundColor: 0xffffffff,
        );
        if (rendered == null) {
          throw HskPaperReaderException('Could not draw page ${i + 1}.');
        }
        // pdfrx hands out BGRA; the cleaning rule weighs red and blue
        // differently, so swap to RGBA first.
        final rgba = Uint8List.fromList(rendered.pixels);
        for (var k = 0; k < rgba.length; k += 4) {
          final b = rgba[k];
          rgba[k] = rgba[k + 2];
          rgba[k + 2] = b;
        }
        final pw = rendered.width, ph = rendered.height;
        rendered.dispose();
        out.add(await readPage(
          RgbaPage(pw, ph, rgba),
          number: i + 1,
          onProgress: (f) => onProgress?.call((i + f) / count, i + 1, count),
        ));
      }
      onProgress?.call(1, count, count);
      return out;
    } finally {
      await doc.dispose();
    }
  }

  /// Cleans, reads and analyses one rendered page.
  Future<PaperPage> readPage(
    RgbaPage page, {
    required int number,
    void Function(double fraction)? onProgress,
  }) async {
    final gray = PaperImageOps.cleanToGray(page.rgba);
    final boxes = PaperImageOps.findPictureBoxes(gray, page.width, page.height);
    final png = encodeGrayPng(gray, page.width, page.height);
    final text = await _engine.read(
      png,
      pageMode: pageMode,
      onProgress: onProgress,
    );
    return PaperPage(
      number: number,
      width: page.width,
      height: page.height,
      text: text,
      png: png,
      pictureBoxes: boxes,
    );
  }

  static Uint8List encodeGrayPng(Uint8List gray, int width, int height) {
    final bitmap = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: gray.buffer,
      numChannels: 1,
    );
    return Uint8List.fromList(img.encodePng(bitmap));
  }

  /// A part of a cleaned page as PNG (a picture choice to upload).
  static Uint8List cropPng(PaperPage page, PixelBox box, {int pad = 8}) {
    final decoded = img.decodePng(page.png);
    if (decoded == null) throw const HskPaperReaderException('Bad page image.');
    final x0 = (box.x0 - pad).clamp(0, decoded.width - 1);
    final y0 = (box.y0 - pad).clamp(0, decoded.height - 1);
    final x1 = (box.x1 + pad).clamp(x0 + 1, decoded.width);
    final y1 = (box.y1 + pad).clamp(y0 + 1, decoded.height);
    final cropped =
        img.copyCrop(decoded, x: x0, y: y0, width: x1 - x0, height: y1 - y0);
    return Uint8List.fromList(img.encodePng(cropped));
  }
}
