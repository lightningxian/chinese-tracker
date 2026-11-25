#!/usr/bin/env python3
"""Draws the Bab II figures (Gambar 2.1 to 2.8) of the book.

usage:
  python3 -I docs/thesis/tools/make_bab2_figs.py [out_dir] [work_dir]

out_dir   where fig_2_N.png goes (default: docs/thesis/word)
work_dir  where the intermediate fig_2_N.html pages go (default: a temp folder)

Every figure is our own drawing: an SVG inside an HTML page, photographed
with headless Chrome at twice the drawing size (canvas 1000 px wide, so
13 cm in the book). Standard library only. Chrome is found in the usual
places or through the CHROME environment variable. The height of each
figure in the book is in FIG_SIZE_CM of build_book.py (13 cm x H/W).
"""
import os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(os.path.dirname(HERE), 'word')
WORK = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else tempfile.mkdtemp(prefix='bab2figs-')

INK = '#1f2937'
WHITE, SOFT, BLUE, YELLOW, GREY = '#ffffff', '#f8fafc', '#eef2ff', '#fffbe6', '#e5e7eb'
LH = {'t': 23, 'b': 24, 's': 20, 'm': 20, 'mb': 24, 'h': 26}
CSS = ('text{font-family:Helvetica,Arial,"PingFang SC",sans-serif;fill:%s}'
       '.t{font-size:18px}.b{font-size:19px;font-weight:bold}.s{font-size:16px}.h{font-size:21px;font-weight:bold}'
       '.m{font-size:16px;font-family:Menlo,"Courier New",monospace}'
       '.mb{font-size:18px;font-weight:bold;font-family:Menlo,"Courier New",monospace}'
       '.lbl{font-size:16px;paint-order:stroke;stroke:#fff;stroke-width:6px;stroke-linejoin:round}') % INK
DEFS = ('<defs>'
        '<marker id="ah" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto" markerUnits="userSpaceOnUse">'
        '<path d="M0,0 L12,6 L0,12 z" fill="%s"/></marker>'
        '<marker id="ahs" markerWidth="12" markerHeight="12" refX="2" refY="6" orient="auto" markerUnits="userSpaceOnUse">'
        '<path d="M12,0 L0,6 L12,12 z" fill="%s"/></marker>'
        '</defs>') % (INK, INK)
SIZES = {}


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def text(x, y, lines, cls='t', anchor='middle'):
    """Lines centred vertically on y. A line is a string (class cls) or a (string, class) pair."""
    rows = [(l, cls) if isinstance(l, str) else l for l in lines]
    total = sum(LH[c] for _, c in rows)
    top = y - total / 2
    out = []
    for s, c in rows:
        base = top + LH[c] * 0.74
        out.append('<text x="%.1f" y="%.1f" text-anchor="%s" class="%s">%s</text>' % (x, base, anchor, c, esc(s)))
        top += LH[c]
    return ''.join(out)


def box(x, y, w, h, lines=(), fill=WHITE, cls='t', rx=10, dash=False):
    d = ' stroke-dasharray="8 6"' if dash else ''
    return ('<rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="%s" stroke="%s" stroke-width="2"%s/>' % (x, y, w, h, rx, fill, INK, d)
            + (text(x + w / 2, y + h / 2, lines, cls) if lines else ''))


def arrow(pts, both=False, dash=False):
    d = ' '.join('%s%d,%d' % ('M' if i == 0 else 'L', x, y) for i, (x, y) in enumerate(pts))
    extra = (' marker-start="url(#ahs)"' if both else '') + (' stroke-dasharray="8 6"' if dash else '')
    return '<path d="%s" fill="none" stroke="%s" stroke-width="2" marker-end="url(#ah)"%s/>' % (d, INK, extra)


def label(x, y, s, anchor='start'):
    return '<text x="%d" y="%d" class="lbl" text-anchor="%s">%s</text>' % (x, y, anchor, esc(s))


def diamond(cx, cy, hw, hh, lines, cls='s'):
    return ('<path d="M%d,%d L%d,%d L%d,%d L%d,%d z" fill="%s" stroke="%s" stroke-width="2"/>' % (cx, cy - hh, cx + hw, cy, cx, cy + hh, cx - hw, cy, WHITE, INK)
            + text(cx, cy, lines, cls))


def page(name, w, h, parts):
    svg = ('<svg width="%d" height="%d" viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg">%s<rect width="%d" height="%d" fill="#fff"/>%s</svg>'
           % (w, h, w, h, DEFS, w, h, ''.join(parts)))
    html = ('<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#fff;overflow:hidden}svg{display:block}%s</style></head><body>%s</body></html>'
            % (CSS, svg))
    with open(os.path.join(WORK, name + '.html'), 'w', encoding='utf8') as f:
        f.write(html)
    SIZES[name] = (w, h)


# ------------------------------------------------------------------ 2.1 Flutter layers
def flutter_layers():
    W, H = 1000, 440
    p = []

    def band(y, h, fill, name, cells):
        p.append(box(20, y, 960, h, fill=fill, rx=12))
        p.append(text(135, y + h / 2, name, 'b'))
        if isinstance(cells, str):
            p.append(text(615, y + h / 2, [cells], 't'))
            return
        n = len(cells); gap = 10; x0 = 260; cw = (710 - gap * (n - 1)) / n
        for i, c in enumerate(cells):
            p.append(box(x0 + i * (cw + gap), y + 10, cw, h - 20, c, cls='s', rx=8))

    band(16, 46, YELLOW, ['Aplikasi'], 'widget dan logika yang ditulis pengembang')
    band(74, 100, BLUE, ['Framework', ('(Dart)', 's')],
         [['Material /', 'Cupertino'], ['Widgets'], ['Rendering'], ['Animation,', 'Painting,', 'Gestures'], ['Foundation']])
    band(186, 80, SOFT, ['Engine', ('(C/C++)', 's')],
         [['Rendering', 'grafis'], ['Tata letak', 'teks'], ['Dart', 'runtime'], ['Platform', 'channels']])
    band(278, 80, SOFT, ['Embedder', ('(khusus platform)', 's')],
         [['Permukaan', 'render'], ['Masukan dan', 'event loop'], ['Plugin', 'native']])
    band(370, 54, GREY, ['Platform'], [['Android'], ['iOS'], ['Peramban web']])
    page('fig_2_1', W, H, p)


# ------------------------------------------------------------------ 2.2 one code base, three platforms
def one_code_base():
    W, H = 1000, 400
    p = []
    p.append(box(30, 120, 250, 160, [('Satu basis kode', 'b'), 'Dart + Flutter', ('folder lib/', 's')], fill=BLUE, rx=12))
    rows = [(70, ['Kompilasi ke', 'JavaScript / WebAssembly'], [('Web', 'b'), ('peramban di komputer', 's'), ('dan telepon', 's')]),
            (200, ['Kompilasi AOT', 'ke kode mesin native'], [('Android', 'b'), ('berkas APK', 's')]),
            (330, ['Kompilasi AOT', 'ke kode mesin native'], [('iOS', 'b'), ('iPhone', 's')])]
    for yc, mid, right in rows:
        p.append(box(370, yc - 38, 290, 76, mid, fill=SOFT))
        p.append(box(740, yc - 38, 235, 76, right, fill=YELLOW))
        p.append(arrow([(280, 200), (325, 200), (325, yc), (370, yc)] if yc != 200 else [(280, 200), (370, 200)]))
        p.append(arrow([(660, yc), (740, yc)]))
    page('fig_2_2', W, H, p)


# ------------------------------------------------------------------ 2.3 Firebase services
def firebase_services():
    W, H = 1000, 480
    p = []
    p.append(box(25, 170, 215, 140, [('Aplikasi Flutter', 'b'), ('web, Android, iOS', 's'), ('paket FlutterFire', 's')], fill=YELLOW, rx=12))
    p.append(box(330, 15, 650, 450, fill=BLUE, rx=14))
    p.append(text(655, 40, ['Firebase'], 'h'))
    cells = {(0, 0): [('Authentication', 'b'), ('login, ID token pengguna', 's')],
             (1, 0): [('Hosting', 'b'), ('berkas aplikasi web (HTTPS)', 's')],
             (0, 1): [('Cloud Firestore', 'b'), ('data + Security Rules', 's')],
             (1, 1): [('Cloud Functions', 'b'), ('logika server, Admin SDK', 's')],
             (0, 2): [('Cloud Storage', 'b'), ('rekaman dan gambar soal', 's')],
             (1, 2): [('Cloud Messaging', 'b'), ('notifikasi ke perangkat', 's')]}
    for (c, r), lines in cells.items():
        p.append(box(350 + c * 325, 65 + r * 130, 285, 104, lines))
    p.append(arrow([(240, 240), (330, 240)], both=True))
    p.append(label(285, 226, 'HTTPS', 'middle'))
    p.append(arrow([(675, 247), (635, 247)], both=True))
    p.append(arrow([(817, 299), (817, 325)]))
    page('fig_2_3', W, H, p)


# ------------------------------------------------------------------ 2.4 Firestore structure
def firestore_structure():
    W, H = 1000, 420
    p = []
    p.append(text(115, 32, ['Koleksi'], 's'))
    p.append(box(30, 50, 170, 70, [('users', 'mb')], fill=GREY))
    p.append(arrow([(200, 85), (290, 85)]))
    p.append(text(430, 32, ['Dokumen'], 's'))
    p.append(box(290, 50, 280, 130, [('{uid}', 'mb'), ('name: "…"', 'm'), ('role: "student"', 'm'), ('level: "HSK 2"', 'm')]))
    p.append(box(620, 60, 355, 100, [('Dokumen berisi pasangan field', 's'), ('dan nilai, serta dapat', 's'), ('memiliki subkoleksi.', 's')], fill=YELLOW, dash=True))
    p.append(arrow([(430, 180), (430, 250)]))
    p.append(text(205, 285, ['Subkoleksi'], 's'))
    p.append(box(290, 250, 280, 70, [('level_history', 'mb')], fill=GREY))
    p.append(arrow([(570, 285), (650, 285)]))
    p.append(text(812, 203, ['Dokumen'], 's'))
    p.append(box(650, 220, 325, 150, [('{id}', 'mb'), ('kind: "promotion"', 'm'), ('from: "HSK 1"', 'm'), ('to: "HSK 2"', 'm'), ('date: (waktu)', 'm')]))
    p.append(text(30, 395, [('Alamat dokumen:  users/{uid}/level_history/{id}', 'm')], anchor='start'))
    page('fig_2_4', W, H, p)


# ------------------------------------------------------------------ 2.5 Security Rules and the Admin SDK path
def rules_paths():
    W, H = 1000, 420
    p = []
    p.append(box(25, 160, 200, 120, [('Aplikasi klien', 'b'), ('SDK Firebase', 's'), ('+ ID token', 's')], fill=YELLOW, rx=12))
    p.append(box(370, 40, 270, 110, [('Security Rules', 'b'), ('periksa identitas, peran,', 's'), ('dan isi data', 's')], fill=BLUE))
    p.append(box(370, 290, 270, 110, [('Cloud Functions', 'b'), ('periksa pemanggil;', 's'), ('memakai Admin SDK', 's')], fill=BLUE))
    p.append(box(780, 160, 195, 120, [('Cloud Firestore', 'b'), ('dokumen', 's')], fill=SOFT, rx=12))
    p.append(box(780, 40, 195, 60, [('Ditolak', 'b')], dash=True))
    p.append(arrow([(125, 160), (125, 95), (370, 95)]))
    p.append(label(140, 86, 'baca / tulis langsung'))
    p.append(arrow([(125, 280), (125, 345), (370, 345)]))
    p.append(label(140, 336, 'memanggil fungsi'))
    p.append(arrow([(640, 70), (780, 70)]))
    p.append(label(648, 61, 'tidak memenuhi'))
    p.append(arrow([(640, 120), (735, 120), (735, 200), (780, 200)]))
    p.append(label(646, 142, 'diizinkan'))
    p.append(arrow([(640, 345), (877, 345), (877, 280)]))
    p.append(label(648, 369, 'tidak melewati Security Rules'))
    page('fig_2_5', W, H, p)


# ------------------------------------------------------------------ 2.6 transaction, retry, idempotent key
def transaction():
    W, H = 1000, 500
    p = []
    p.append('<circle cx="38" cy="100" r="11" fill="%s"/>' % INK)
    p.append(arrow([(49, 100), (75, 100)]))
    p.append(box(75, 58, 290, 84, ['1. Baca dokumen:', 'sesi, voucher, dan catatan', ('{sesiId}_{muridId}', 'm')]))
    p.append(arrow([(365, 100), (395, 100)]))
    p.append(diamond(520, 100, 125, 62, ['Sudah pernah', 'diproses?']))
    p.append(arrow([(645, 100), (715, 100)]))
    p.append(label(655, 91, 'Ya'))
    p.append(box(715, 62, 265, 76, ['Selesai tanpa perubahan', '(idempoten)'], fill=SOFT))
    p.append(arrow([(520, 162), (520, 292)]))
    p.append(label(532, 232, 'Belum'))
    p.append(box(390, 292, 260, 84, ['2. Tulis semua', 'perubahan sekaligus']))
    p.append(arrow([(390, 334), (352, 334)]))
    p.append(diamond(220, 334, 132, 64, ['Dokumen yang dibaca', 'diubah proses lain?']))
    p.append(arrow([(220, 270), (220, 142)]))
    p.append(label(232, 212, 'Ya: ulangi dengan data terbaru'))
    p.append(arrow([(220, 398), (220, 432)]))
    p.append(label(232, 421, 'Tidak'))
    p.append(box(80, 432, 280, 56, ['Semua perubahan tersimpan'], fill=SOFT))
    p.append(box(690, 250, 290, 200, [('Kunci idempoten', 'b'), ('ID dokumen disusun dari', 's'), ('data lain, sehingga catatan', 's'), ('yang sama tidak dapat', 's'), ('dibuat dua kali.', 's')], fill=YELLOW, dash=True))
    page('fig_2_6', W, H, p)


# ------------------------------------------------------------------ 2.7 MVVM with Provider
def mvvm():
    W, H = 1000, 490
    p = []
    rows = [(16, YELLOW, 'View', 'widget halaman: Consumer, context.watch()'),
            (146, BLUE, 'ViewModel', 'ChangeNotifier, keadaan halaman'),
            (276, SOFT, 'Service / Repository', 'satu-satunya jalur ke Firebase'),
            (406, GREY, 'Firebase', 'Firestore, Authentication, Cloud Functions')]
    for y, fill, title, sub in rows:
        p.append(box(300, y, 400, 64, [(title, 'b'), (sub, 's')], fill=fill))
    down = ['memanggil fungsi', 'meminta data atau aksi', 'membaca, menulis, memanggil fungsi server']
    up = ['notifyListeners()', 'data (Model)', 'Stream atau Future']
    for i in range(3):
        y1 = rows[i][0] + 64; y2 = rows[i + 1][0]
        p.append(arrow([(420, y1), (420, y2)]))
        p.append(label(406, (y1 + y2) // 2 + 6, down[i], 'end'))
        p.append(arrow([(580, y2), (580, y1)]))
        p.append(label(594, (y1 + y2) // 2 + 6, up[i]))
    page('fig_2_7', W, H, p)


# ------------------------------------------------------------------ 2.8 Midtrans Snap sequence
def snap_sequence():
    W, H = 1000, 500
    A, S, M = 150, 500, 850
    p = []
    for x, name, fill in ((A, 'Aplikasi Flutter', YELLOW), (S, 'Cloud Functions', BLUE), (M, 'Midtrans', SOFT)):
        p.append('<line x1="%d" y1="62" x2="%d" y2="492" stroke="%s" stroke-width="1.6" stroke-dasharray="6 6"/>' % (x, x, INK))
        p.append(box(x - 125, 12, 250, 50, [(name, 'b')], fill=fill))

    def msg(x1, x2, y, s, dash=False):
        p.append(arrow([(x1, y), (x2, y)], dash=dash))
        p.append(label((x1 + x2) // 2, y - 9, s, 'middle'))

    msg(A, S, 105, '1. Membuat tagihan (fungsi callable)')
    msg(S, M, 155, '2. Membuat transaksi Snap (server key)')
    msg(M, S, 205, '3. Token Snap', dash=True)
    msg(S, A, 255, '4. Token Snap', dash=True)
    msg(A, M, 310, '5. Murid membayar di halaman Snap (Virtual Account, e-wallet, QRIS)')
    msg(M, S, 362, '6. HTTP notification + signature key')
    p.append(box(512, 384, 326, 60, ['7. Verifikasi signature; tandai lunas', 'dan buat voucher dalam satu transaksi'], fill=YELLOW, cls='s', rx=8))
    msg(S, A, 480, '8. Status lunas tampil di aplikasi', dash=True)
    page('fig_2_8', W, H, p)


def chrome():
    for c in (os.environ.get('CHROME'), '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
              'C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
              '/usr/bin/google-chrome', '/usr/bin/chromium'):
        if c and os.path.exists(c):
            return c
    sys.exit('Chrome not found (set CHROME)')


def shoot():
    exe = chrome()
    os.makedirs(OUT, exist_ok=True)
    for name, (w, h) in sorted(SIZES.items()):
        png = os.path.join(OUT, name + '.png')
        url = 'file://' + os.path.join(WORK, name + '.html').replace(os.sep, '/')
        profile = tempfile.mkdtemp(prefix='bab2chrome-')
        subprocess.run([exe, '--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--user-data-dir=' + profile,
                        '--force-device-scale-factor=2', '--window-size=%d,%d' % (w, h), '--screenshot=' + png, url],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print('%s  %d x %d px  ->  13 x %.2f cm' % (png, w * 2, h * 2, 13.0 * h / w))


if __name__ == '__main__':
    os.makedirs(WORK, exist_ok=True)
    flutter_layers()
    one_code_base()
    firebase_services()
    firestore_structure()
    rules_paths()
    transaction()
    mvvm()
    snap_sequence()
    shoot()
