#!/usr/bin/env python3
"""Shared drawing helpers for the diagrams of the book (Bab III and Bab V).

A diagram is an SVG inside an HTML page, photographed with headless Chrome
at twice the drawing size. Standard library only. Import it from a generator
script in this folder:

    import figkit as k
    k.setup(work_dir)                       # where the intermediate HTML goes
    k.page('fig_5_1', 1000, 520, parts)     # parts = list of SVG strings
    k.shoot(out_dir)                        # writes fig_5_1.png, prints sizes

Rule of the book (owner and supervisor, 2026-11-26): a diagram takes at most
half a page, so that one page holds two diagrams, each with its
explanation. A canvas is 1000 px wide (14 cm in the book) and at most
MAX_H px high (7.7 cm); page() refuses a taller one. A diagram that does not
fit is split into two diagrams. Text is at least 17 px (about 7 pt in print).

Colours and classes are the ones of the Bab II figures (make_bab2_figs.py).
"""
import os, subprocess, sys, tempfile

INK = '#1f2937'
WHITE, SOFT, BLUE, YELLOW, GREY = '#ffffff', '#f8fafc', '#eef2ff', '#fffbe6', '#e5e7eb'
W = 1000                      # canvas width in px = 14 cm in the book
MAX_H = 550                   # 7.7 cm: half a page with caption and explanation
WIDTH_CM = 14.0
LH = {'t': 23, 'b': 24, 's': 21, 'm': 21, 'mb': 24, 'h': 26}
CSS = ('text{font-family:Helvetica,Arial,"PingFang SC",sans-serif;fill:%s}'
       '.t{font-size:18px}.b{font-size:19px;font-weight:bold}.s{font-size:17px}.h{font-size:21px;font-weight:bold}'
       '.sb{font-size:17px;font-weight:bold}'
       '.m{font-size:17px;font-family:Menlo,"Courier New",monospace}'
       '.mb{font-size:18px;font-weight:bold;font-family:Menlo,"Courier New",monospace}'
       '.id{font-size:14px;font-family:Menlo,"Courier New",monospace;fill:#374151}'
       '.lbl{font-size:17px;paint-order:stroke;stroke:#fff;stroke-width:6px;stroke-linejoin:round}'
       '.n{font-size:17px;font-weight:bold;paint-order:stroke;stroke:#fff;stroke-width:5px;stroke-linejoin:round}') % INK
DEFS = ('<defs>'
        '<marker id="ah" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto" markerUnits="userSpaceOnUse">'
        '<path d="M0,0 L12,6 L0,12 z" fill="%s"/></marker>'
        '<marker id="ahs" markerWidth="12" markerHeight="12" refX="2" refY="6" orient="auto" markerUnits="userSpaceOnUse">'
        '<path d="M12,0 L0,6 L12,12 z" fill="%s"/></marker>'
        '</defs>') % (INK, INK)
_STATE = {'work': None, 'sizes': {}}


def setup(work=None):
    _STATE['work'] = os.path.abspath(work) if work else tempfile.mkdtemp(prefix='figkit-')
    os.makedirs(_STATE['work'], exist_ok=True)
    _STATE['sizes'] = {}


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


# ------------------------------------------------------------------ text
def t(x, y, s, cls='t', anchor='start'):
    """One line with its baseline at y."""
    return '<text x="%.1f" y="%.1f" text-anchor="%s" class="%s">%s</text>' % (x, y, anchor, cls, esc(s))


def text(x, y, lines, cls='t', anchor='middle'):
    """Lines centred vertically on y. A line is a string (class cls) or a (string, class) pair."""
    rows = [(l, cls) if isinstance(l, str) else l for l in lines]
    total = sum(LH.get(c, 22) for _, c in rows)
    top = y - total / 2
    out = []
    for s, c in rows:
        out.append(t(x, top + LH.get(c, 22) * 0.74, s, c, anchor))
        top += LH.get(c, 22)
    return ''.join(out)


def label(x, y, s, anchor='start'):
    """A label on a line, with a white halo so the line does not cross it."""
    return t(x, y, s, 'lbl', anchor)


# ------------------------------------------------------------------ shapes
def rect(x, y, w, h, fill=WHITE, rx=8, dash=False, sw=2):
    d = ' stroke-dasharray="8 6"' if dash else ''
    return '<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="%s" stroke="%s" stroke-width="%s"%s/>' % (x, y, w, h, rx, fill, INK, sw, d)


def box(x, y, w, h, lines=(), fill=WHITE, cls='t', rx=10, dash=False):
    return rect(x, y, w, h, fill, rx, dash) + (text(x + w / 2, y + h / 2, lines, cls) if lines else '')


def ellipse(cx, cy, rx, ry, lines=(), fill=WHITE, cls='s'):
    """A use case."""
    return ('<ellipse cx="%d" cy="%d" rx="%d" ry="%d" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, cy, rx, ry, fill, INK)
            + (text(cx, cy, lines, cls) if lines else ''))


def diamond(cx, cy, hw, hh, lines=(), cls='s'):
    return ('<path d="M%d,%d L%d,%d L%d,%d L%d,%d z" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, cy - hh, cx + hw, cy, cx, cy + hh, cx - hw, cy, WHITE, INK)
            + (text(cx, cy, lines, cls) if lines else ''))


def dot(cx, cy, r=9, end=False):
    """Start node of an activity diagram; end=True draws the end node."""
    if end:
        return ('<circle cx="%d" cy="%d" r="%d" fill="#fff" stroke="%s" stroke-width="2"/><circle cx="%d" cy="%d" r="%d" fill="%s"/>'
                % (cx, cy, r + 4, INK, cx, cy, r - 2, INK))
    return '<circle cx="%d" cy="%d" r="%d" fill="%s"/>' % (cx, cy, r, INK)


def stick(cx, y, name, cls='sb'):
    """An actor: the head's top is at y, the name sits under the feet (about 95 px high in all)."""
    p = ['<circle cx="%d" cy="%d" r="11" fill="#fff" stroke="%s" stroke-width="2"/>' % (cx, y + 11, INK)]
    for x1, y1, x2, y2 in ((cx, y + 22, cx, y + 50), (cx - 18, y + 33, cx + 18, y + 33), (cx, y + 50, cx - 14, y + 72), (cx, y + 50, cx + 14, y + 72)):
        p.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (x1, y1, x2, y2, INK))
    p.append(t(cx, y + 92, name, cls, 'middle'))
    return ''.join(p)


# ------------------------------------------------------------------ lines
def line(pts, dash=False, arrow=False, both=False):
    d = ' '.join('%s%d,%d' % ('M' if i == 0 else 'L', x, y) for i, (x, y) in enumerate(pts))
    extra = ((' stroke-dasharray="8 6"' if dash else '') + (' marker-end="url(#ah)"' if arrow or both else '')
             + (' marker-start="url(#ahs)"' if both else ''))
    return '<path d="%s" fill="none" stroke="%s" stroke-width="2"%s/>' % (d, INK, extra)


def arrow(pts, both=False, dash=False):
    return line(pts, dash=dash, arrow=True, both=both)


# ------------------------------------------------------------------ data model
TITLE_LH, ID_LH, FIELD_LH = 23, 18, 21


def entity_height(titles, ids, fields):
    return 8 + TITLE_LH * len(titles) + ID_LH * len(ids) + 7 + 8 + FIELD_LH * len(fields) + 8


def entity(x, y, titles, ids, fields, fill=BLUE, bw=230):
    """A collection: name band (name, how the document ID is formed), then its key fields. Returns (svg, height)."""
    band = 8 + TITLE_LH * len(titles) + ID_LH * len(ids) + 7
    h = entity_height(titles, ids, fields)
    p = [rect(x, y, bw, h, WHITE)]
    p.append('<path d="M%d,%d h%d a8,8 0 0 1 8,8 v%d h-%d v-%d a8,8 0 0 1 8,-8 z" fill="%s" stroke="%s" stroke-width="2"/>'
             % (x + 8, y, bw - 16, band - 8, bw, band - 8, fill, INK))
    yy = y + 8
    for s in titles:
        p.append(t(x + bw / 2, yy + TITLE_LH * 0.76, s, 'mb', 'middle'))
        yy += TITLE_LH
    for s in ids:
        p.append(t(x + bw / 2, yy + ID_LH * 0.76, s, 'id', 'middle'))
        yy += ID_LH
    yy = y + band + 8
    for s in fields:
        p.append(t(x + 12, yy + FIELD_LH * 0.76, s, 'm'))
        yy += FIELD_LH
    return ''.join(p), h


def mult(x, y, s, anchor='middle'):
    """A multiplicity mark (1, N, 0..1) next to the end of a relation."""
    return t(x, y, s, 'n', anchor)


def rel_h(x1, x2, y, name, m1, m2, dash=False):
    """Horizontal relation between two boxes: the referring field above the line, m1 at x1, m2 at x2."""
    p = [line([(x1, y), (x2, y)], dash), t((x1 + x2) / 2, y - 8, name, 'lbl', 'middle')]
    if m1:
        p.append(mult(x1 + 7, y + 19, m1, 'start'))
    if m2:
        p.append(mult(x2 - 7, y + 19, m2, 'end'))
    return ''.join(p)


def rel_v(x, y1, y2, name, m1, m2, dash=False):
    """Vertical relation: m1 at the y1 end, m2 at the y2 end, the referring field to the right."""
    p = [line([(x, y1), (x, y2)], dash), t(x + 10, (y1 + y2) / 2 + 5, name, 'lbl')]
    if m1:
        p.append(mult(x - 12, y1 + 18, m1))
    if m2:
        p.append(mult(x - 12, y2 - 7, m2))
    return ''.join(p)


def note(x, y, w, lines, fill=YELLOW):
    """A dashed note. A line is a string or a (string, class) pair. Returns (svg, height)."""
    lh = 21
    h = 12 + lh * len(lines) + 10
    p = [rect(x, y, w, h, fill, dash=True)]
    yy = y + 12
    for l in lines:
        s, c = (l, 's') if isinstance(l, str) else l
        p.append(t(x + 12, yy + lh * 0.76, s, c))
        yy += lh
    return ''.join(p), h


# ------------------------------------------------------------------ page and PNG
def page(name, w, h, parts, tall=False):
    """Writes the page. w is W; h may not pass MAX_H (half a page) unless tall=True, which the book does not use."""
    if _STATE['work'] is None:
        setup()
    if w != W or (h > MAX_H and not tall):
        sys.exit('%s: canvas %d x %d; the book wants %d wide and at most %d high (split the diagram)' % (name, w, h, W, MAX_H))
    svg = ('<svg width="%d" height="%d" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">%s<rect width="%d" height="%d" fill="#fff"/>%s</svg>'
           % (w, h, w, h, DEFS, w, h, ''.join(parts)))
    html = ('<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#fff;overflow:hidden}svg{display:block}%s</style></head><body>%s</body></html>'
            % (CSS, svg))
    with open(os.path.join(_STATE['work'], name + '.html'), 'w', encoding='utf8') as f:
        f.write(html)
    _STATE['sizes'][name] = (w, h)


def chrome():
    for c in (os.environ.get('CHROME'), '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
              'C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
              '/usr/bin/google-chrome', '/usr/bin/chromium'):
        if c and os.path.exists(c):
            return c
    sys.exit('Chrome not found (set CHROME)')


def shoot(out):
    """Photographs every page written since setup() into out/<name>.png and prints the size in the book."""
    exe = chrome()
    out = os.path.abspath(out)
    os.makedirs(out, exist_ok=True)
    for name, (w, h) in sorted(_STATE['sizes'].items()):
        png = os.path.join(out, name + '.png')
        url = 'file://' + os.path.join(_STATE['work'], name + '.html').replace(os.sep, '/')
        profile = tempfile.mkdtemp(prefix='figkit-chrome-')
        subprocess.run([exe, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--user-data-dir=' + profile,
                        '--force-device-scale-factor=2', '--window-size=%d,%d' % (w, h), '--screenshot=' + png, url],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print('%s  %d x %d px  ->  %.0f x %.2f cm' % (os.path.basename(png), w * 2, h * 2, WIDTH_CM, WIDTH_CM * h / w))
