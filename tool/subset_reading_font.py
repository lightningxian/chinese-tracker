"""Cuts Noto Sans SC Regular down to the characters the app shows.

Owner 2026-11-26: Chinese text in the app reads in a plain sans face
(Noto Sans SC, OFL), never bold. The full font is ~10.5 MB; this keeps
GB2312 (the 6,763 common simplified characters) plus Latin, pinyin tone
letters and punctuation, the same cut as the old Kai font had.

Usage (fonttools on the path, e.g. `pip install --target <dir> fonttools`):
    py -I tool/subset_reading_font.py
Writes assets/fonts/NotoSansSC-Reading.ttf. The full NotoSansSC files stay
for the report PDFs (lib/core/reports/report_pdf_fonts.dart).
"""
import os
import sys

from fontTools import subset

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "assets", "fonts", "NotoSansSC-Regular.ttf")
OUT = os.path.join(ROOT, "assets", "fonts", "NotoSansSC-Reading.ttf")


def gb2312_chars():
    out = []
    for hi in range(0xA1, 0xF8):
        for lo in range(0xA1, 0xFF):
            try:
                out.append(bytes([hi, lo]).decode("gb2312"))
            except UnicodeDecodeError:
                pass
    return out


def codepoints():
    cps = set()
    for c in gb2312_chars():
        cps.add(ord(c))
    ranges = [
        (0x0020, 0x007E),  # ASCII
        (0x00A0, 0x024F),  # Latin-1, Latin Extended A/B (pinyin ü, ǎ ǐ ǒ ǔ ǚ …)
        (0x02C6, 0x02DD),  # spacing modifiers (tone marks)
        (0x0300, 0x036F),  # combining marks
        (0x1E00, 0x1EFF),  # Latin Extended Additional
        (0x2000, 0x206F),  # general punctuation
        (0x2190, 0x21FF),  # arrows
        (0x2460, 0x24FF),  # circled numbers ① ②
        (0x2500, 0x25FF),  # box drawing, shapes (★ ○ □)
        (0x2600, 0x26FF),
        (0x3000, 0x303F),  # CJK punctuation
        (0xFF00, 0xFFEF),  # fullwidth forms （ ）＿
    ]
    for a, b in ranges:
        cps.update(range(a, b + 1))
    return sorted(cps)


def main():
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.name_languages = ["*"]
    opts.notdef_outline = True
    opts.glyph_names = False
    font = subset.load_font(SRC, opts)
    sub = subset.Subsetter(options=opts)
    sub.populate(unicodes=codepoints())
    sub.subset(font)
    subset.save_font(font, OUT, opts)
    print(f"wrote {OUT}: {os.path.getsize(OUT) / 1e6:.1f} MB")


if __name__ == "__main__":
    sys.exit(main())
