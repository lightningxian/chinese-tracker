import 'dart:typed_data';

/// A rectangle on a rendered page, in pixels (x1/y1 exclusive).
class PixelBox {
  const PixelBox(this.x0, this.y0, this.x1, this.y1);

  final int x0;
  final int y0;
  final int x1;
  final int y1;

  int get width => x1 - x0;
  int get height => y1 - y0;
  int get area => width * height;
  double get centerY => (y0 + y1) / 2;

  PixelBox union(PixelBox o) => PixelBox(
        x0 < o.x0 ? x0 : o.x0,
        y0 < o.y0 ? y0 : o.y0,
        x1 > o.x1 ? x1 : o.x1,
        y1 > o.y1 ? y1 : o.y1,
      );

  /// Gap between two boxes along each axis (0 when they overlap there).
  (int dx, int dy) gapTo(PixelBox o) {
    final dx = (x0 > o.x0 ? x0 : o.x0) - (x1 < o.x1 ? x1 : o.x1);
    final dy = (y0 > o.y0 ? y0 : o.y0) - (y1 < o.y1 ? y1 : o.y1);
    return (dx < 0 ? 0 : dx, dy < 0 ? 0 : dy);
  }

  @override
  bool operator ==(Object other) =>
      other is PixelBox &&
      other.x0 == x0 &&
      other.y0 == y0 &&
      other.x1 == x1 &&
      other.y1 == y1;

  @override
  int get hashCode => Object.hash(x0, y0, x1, y1);

  @override
  String toString() => 'PixelBox($x0, $y0, $x1, $y1)';
}

/// Image steps of the built-in paper reader (docs/PLAN.md, Build 1B), pure
/// Dart so they run in tests and in the browser alike.
abstract final class PaperImageOps {
  /// Removes the centre's coloured watermark and greys the page, the rule
  /// measured on a real paper: a saturated, light pixel
  /// (`max − min > 28` and `max > 150`) is watermark → white; a pixel whose
  /// luminance is above 205 → white; every other pixel keeps its grey value.
  /// A hard black/white threshold made the reading worse.
  ///
  /// [rgba] is 4 bytes per pixel; returns 1 byte per pixel.
  static Uint8List cleanToGray(Uint8List rgba) {
    final n = rgba.length ~/ 4;
    final out = Uint8List(n);
    for (var i = 0, j = 0; i < n; i++, j += 4) {
      final r = rgba[j], g = rgba[j + 1], b = rgba[j + 2];
      var mx = r, mn = r;
      if (g > mx) mx = g;
      if (b > mx) mx = b;
      if (g < mn) mn = g;
      if (b < mn) mn = b;
      if (mx - mn > 28 && mx > 150) {
        out[i] = 255;
        continue;
      }
      final lum = (299 * r + 587 * g + 114 * b) ~/ 1000;
      out[i] = lum > 205 ? 255 : lum;
    }
    return out;
  }

  /// Grey bytes back to RGBA (for PNG encoding).
  static Uint8List grayToRgba(Uint8List gray) {
    final out = Uint8List(gray.length * 4);
    for (var i = 0, j = 0; i < gray.length; i++, j += 4) {
      final v = gray[i];
      out[j] = v;
      out[j + 1] = v;
      out[j + 2] = v;
      out[j + 3] = 255;
    }
    return out;
  }

  /// Picture boxes on a cleaned page: ink is grouped into connected shapes
  /// on a [cell]-pixel grid; shapes close to a large one ([gap] pixels) are
  /// merged into it (a picture drawn in pieces); what is left at least
  /// [minSide] wide, half that tall and not a long thin strip (a line of
  /// text) is a picture. Characters and answer boxes are far smaller.
  /// Measured on a 1738 px wide page.
  static List<PixelBox> findPictureBoxes(
    Uint8List gray,
    int width,
    int height, {
    int cell = 4,
    int dark = 200,
    int minSide = 120,
    int gap = 30,
    double maxAspect = 4,
    int minTall = 100,
  }) {
    final gw = (width + cell - 1) ~/ cell;
    final gh = (height + cell - 1) ~/ cell;
    final grid = Uint8List(gw * gh);
    for (var y = 0; y < height; y++) {
      final row = y * width;
      final grow = (y ~/ cell) * gw;
      for (var x = 0; x < width; x++) {
        if (gray[row + x] < dark) grid[grow + x ~/ cell] = 1;
      }
    }
    final seen = Uint8List(gw * gh);
    final shapes = <PixelBox>[];
    final stack = <int>[];
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] == 0 || seen[i] == 1) continue;
      var x0 = gw, y0 = gh, x1 = -1, y1 = -1;
      seen[i] = 1;
      stack.add(i);
      while (stack.isNotEmpty) {
        final k = stack.removeLast();
        final x = k % gw, y = k ~/ gw;
        if (x < x0) x0 = x;
        if (x > x1) x1 = x;
        if (y < y0) y0 = y;
        if (y > y1) y1 = y;
        for (var dy = -1; dy <= 1; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= gh) continue;
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= gw) continue;
            final j = ny * gw + nx;
            if (grid[j] == 1 && seen[j] == 0) {
              seen[j] = 1;
              stack.add(j);
            }
          }
        }
      }
      shapes.add(PixelBox(
          x0 * cell, y0 * cell, (x1 + 1) * cell, (y1 + 1) * cell));
    }
    // Specks (single dots of the scan) never start a merge.
    var boxes = shapes.where((b) => b.width >= 12 || b.height >= 12).toList();
    bool large(PixelBox b) => b.width >= 40 && b.height >= 40;
    var merged = true;
    while (merged) {
      merged = false;
      outer:
      for (var i = 0; i < boxes.length; i++) {
        for (var j = i + 1; j < boxes.length; j++) {
          final a = boxes[i], b = boxes[j];
          if (!large(a) && !large(b)) continue;
          final (dx, dy) = a.gapTo(b);
          if (dx <= gap && dy <= gap) {
            boxes[i] = a.union(b);
            boxes.removeAt(j);
            merged = true;
            break outer;
          }
        }
      }
    }
    boxes = boxes
        .where((b) =>
            b.width >= minSide &&
            b.height >= minSide / 2 &&
            b.area >= minSide * minSide &&
            b.width / b.height <= maxAspect &&
            b.height / b.width <= maxAspect &&
            // Not a frame around the whole page.
            b.area < width * height * 0.5 &&
            // Build 1C: a picture has a shape taller than a line of text;
            // closely set text lines merge into a box too, but each of
            // their shapes is at most a character high.
            shapes.any((s) =>
                s.height >= minTall &&
                s.x0 >= b.x0 &&
                s.x1 <= b.x1 &&
                s.y0 >= b.y0 &&
                s.y1 <= b.y1))
        .toList();
    return readingOrder(boxes);
  }

  /// Rows top to bottom (boxes whose centres are within half a box height
  /// share a row), left to right inside a row: the order of the letters
  /// A, B, C… on a picture page.
  static List<PixelBox> readingOrder(List<PixelBox> boxes) {
    final sorted = [...boxes]..sort((a, b) => a.centerY.compareTo(b.centerY));
    final rows = <List<PixelBox>>[];
    for (final b in sorted) {
      final row = rows.isEmpty ? null : rows.last;
      if (row != null) {
        final ref = row.first;
        final tolerance = (ref.height < b.height ? ref.height : b.height) / 2;
        if ((b.centerY - ref.centerY).abs() <= tolerance) {
          row.add(b);
          continue;
        }
      }
      rows.add([b]);
    }
    return [
      for (final row in rows) ...(row..sort((a, b) => a.x0.compareTo(b.x0))),
    ];
  }
}
