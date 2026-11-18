import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../core/constants/worksheet_import_platform.dart';
import '../../core/utils/question_import_utils.dart';
import '../../features/question_bank/question_bank_ai_import_utils.dart';
import '../../models/ai_worksheet.dart';
import '../../models/app_user.dart';
import '../../models/hsk_paper_draft.dart';
import '../../models/question_bank_item.dart';
import 'hsk_paper_reader.dart';
import 'paper_image_ops.dart';

/// From the pages the reader returned to a draft, and from a proofread
/// draft to bank items (docs/PLAN.md, Build 1B).
abstract final class HskPaperImport {
  /// Parts and slots from the page texts; picture questions get the
  /// picture boxes of their page as choices A, B, C…
  static HskPaperDraft draftFrom(List<PaperPage> pages) {
    final draft =
        QuestionImportUtils.parseHskPaper([for (final p in pages) p.text]);
    assignPictures(draft, pages);
    return draft;
  }

  static void assignPictures(HskPaperDraft draft, List<PaperPage> pages) {
    // A block with picture questions on a page that has pictures: every
    // listening slot of it without choices is a picture question too (the
    // engine can read stray marks on a picture page as a sentence).
    final pictureBlocks = <String, int>{
      for (final s in draft.slots)
        if (s.form == HskForm.picture &&
            s.section.isNotEmpty &&
            s.picturePage >= 1 &&
            s.picturePage <= pages.length &&
            pages[s.picturePage - 1].pictureBoxes.length >= 2)
          s.section: s.picturePage,
    };
    for (final slot in draft.slots) {
      final page = pictureBlocks[slot.section];
      if (page != null &&
          slot.form != HskForm.picture &&
          slot.skill == 'listening' &&
          slot.options.where((o) => o.trim().isNotEmpty).length < 2) {
        slot.form = HskForm.picture;
        slot.picturePage = page;
        slot.prompt = '';
      }
    }
    for (final slot in draft.slots) {
      if (slot.form != HskForm.picture) continue;
      final page = slot.picturePage >= 1 && slot.picturePage <= pages.length
          ? pages[slot.picturePage - 1]
          : null;
      final boxes = page?.pictureBoxes ?? const <PixelBox>[];
      slot.pictures = [...boxes];
      if (boxes.length >= 2) {
        // A picture question needs no text: what matters is its pictures.
        slot.missing = false;
        slot.unsure = false;
      }
    }
    // The block check again, now that the picture questions are known.
    draft.markOddForms();
  }

  static Map<int, (int, int)> pageSizes(List<PaperPage> pages) =>
      {for (final p in pages) p.number: (p.width, p.height)};

  /// Numbers that cannot be saved as they stand (shown before saving).
  static List<int> unsavable(HskPaperDraft draft, List<PaperPage> pages) =>
      QuestionBankAiImportUtils.unsavable(
          draft.toAiWorksheet(pageSizes(pages)));

  /// Bank items of the draft. [upload] stores one picture (PNG) and
  /// returns its URL; pictures are cut from the page drawn again in colour
  /// (the cleaned page has the colours removed). Admin on web only: the
  /// check is here too, not only in the UI
  /// (`.claude/rules/worksheet-import-web-only.md`).
  static Future<List<QuestionBankItem>> toBankItems(
    HskPaperDraft draft,
    List<PaperPage> pages, {
    required AppUser? user,
    required Uint8List pdfBytes,
    required String ownerId,
    required String fileName,
    required Future<String> Function(Uint8List png, String name) upload,
    void Function(int done, int total)? onPicture,
  }) async {
    WorksheetImportPlatform.ensureSupportedFor(user);
    final worksheet = draft.toAiWorksheet(pageSizes(pages));
    final boxes = worksheet.boxes;
    final urls = <String, String>{};
    if (boxes.isNotEmpty) {
      final cutter = await ColourPageCutter.open(pdfBytes);
      try {
        var n = 0;
        for (final entry in boxes.entries) {
          n++;
          onPicture?.call(n, boxes.length);
          final png = await cutter.crop(entry.value);
          urls[entry.key] = await upload(
            png,
            '${QuestionBankAiImportUtils.sheetCodeFor(worksheet, fileName)}_${entry.key}.png',
          );
        }
      } finally {
        await cutter.dispose();
      }
    }
    return QuestionBankAiImportUtils.toBankItems(
      worksheet,
      ownerId: ownerId,
      imageUrls: urls,
      fileName: fileName,
    );
  }
}

/// Cuts pictures out of the original (colour) pages, drawn at the reader's
/// width so the boxes line up.
class ColourPageCutter {
  ColourPageCutter._(this._doc);

  final PdfDocument _doc;
  final Map<int, img.Image> _pages = {};

  static Future<ColourPageCutter> open(Uint8List bytes) async =>
      ColourPageCutter._(await PdfDocument.openData(bytes));

  Future<img.Image> _page(int number) async {
    final cached = _pages[number];
    if (cached != null) return cached;
    final page = _doc.pages[number - 1];
    final scale = HskPaperReader.renderWidth / page.width;
    final rendered = await page.render(
      width: HskPaperReader.renderWidth,
      height: (page.height * scale).round(),
      fullWidth: page.width * scale,
      fullHeight: page.height * scale,
      backgroundColor: 0xffffffff,
    );
    if (rendered == null) {
      throw HskPaperReaderException('Could not draw page $number.');
    }
    try {
      final bitmap = img.Image.fromBytes(
        width: rendered.width,
        height: rendered.height,
        bytes: Uint8List.fromList(rendered.pixels).buffer,
        numChannels: 4,
        order: img.ChannelOrder.bgra, // pdfrx hands out BGRA
      );
      _pages[number] = bitmap;
      return bitmap;
    } finally {
      rendered.dispose();
    }
  }

  Future<Uint8List> crop(AiBox box) async {
    final page = await _page(box.page);
    int x(int v) => (v / 1000 * page.width).round();
    int y(int v) => (v / 1000 * page.height).round();
    const pad = 8;
    final x0 = (x(box.xmin) - pad).clamp(0, page.width - 1);
    final y0 = (y(box.ymin) - pad).clamp(0, page.height - 1);
    final x1 = (x(box.xmax) + pad).clamp(x0 + 1, page.width);
    final y1 = (y(box.ymax) + pad).clamp(y0 + 1, page.height);
    final cropped =
        img.copyCrop(page, x: x0, y: y0, width: x1 - x0, height: y1 - y0);
    return Uint8List.fromList(img.encodePng(cropped));
  }

  Future<void> dispose() async {
    _pages.clear();
    await _doc.dispose();
  }
}
