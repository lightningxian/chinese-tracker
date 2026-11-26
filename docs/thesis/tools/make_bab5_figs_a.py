#!/usr/bin/env python3
"""Draws the Bab V figures that existed before the half-page rule, in the new format.

usage:
  python3 -I docs/thesis/tools/make_bab5_figs_a.py [out_dir] [work_dir]

out_dir   where the PNG files go (default: docs/thesis/word/bab5_new)
work_dir  where the intermediate HTML pages go (default: a temp folder)

The old figures 5.1 to 5.9 (architecture, use case per role, four activity
diagrams, page map) keep their content; only the layout changes. Rule of the
book: a diagram is 14 cm wide and at most half a page high, so a diagram that
does not fit is split in two at a natural point:

  a01, a02  architecture: the application side, the Firebase side   (old 5.1)
  a03, a04  use case admin, two areas each                          (old 5.2)
  a05       use case guru                                           (old 5.3)
  a06, a07  use case murid, use case orang tua                      (old 5.4)
  a08       activity: pendaftaran dan persetujuan                   (old 5.5)
  a09, a10  activity: pemesanan sesi; pelaksanaan dan penutupan     (old 5.6)
  a11, a12  activity: tes simulasi; penilaian akhir dan kenaikan    (old 5.7)
  a13       activity: pembelian voucher                             (old 5.8)
  a14, a15  page map: umum dan admin; guru, murid, orang tua        (old 5.9)

Needs figkit.py (same folder) and Chrome. Standard library only. Text widths
are checked against Helvetica metrics before drawing; a line that would leave
its shape is reported on the terminal.
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import figkit as k

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(os.path.dirname(HERE), 'word', 'bab5_new')
WORK = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else None
INK, WHITE, SOFT, BLUE, YELLOW, GREY = k.INK, k.WHITE, k.SOFT, k.BLUE, k.YELLOW, k.GREY

# ------------------------------------------------------------------ text widths (Helvetica, per 1000 units)
_REG = dict(zip('abcdefghijklmnopqrstuvwxyz', (556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500)))
_REG.update(zip('ABCDEFGHIJKLMNOPQRSTUVWXYZ', (667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611)))
_BOLD = dict(zip('abcdefghijklmnopqrstuvwxyz', (556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500)))
_BOLD.update(zip('ABCDEFGHIJKLMNOPQRSTUVWXYZ', (722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611)))
_PUNCT = {' ': 278, ',': 278, '.': 278, ':': 278, ';': 278, '/': 278, '(': 333, ')': 333, '-': 333, '+': 584, '?': 556, '_': 556, '=': 584, '!': 278}
_CLS = {'t': (18, 0), 'b': (19, 1), 's': (17, 0), 'h': (21, 1), 'sb': (17, 1), 'lbl': (17, 0), 'n': (17, 1), 'm': (17, 2), 'mb': (18, 2)}
WARN = []


def tw(s, cls='s'):
    """Width of a line in px (a little generous, so a small error cannot push text out of a shape)."""
    px, kind = _CLS[cls]
    if kind == 2:
        return len(s) * px * 0.602
    table = _BOLD if kind else _REG
    units = sum(table.get(c, _PUNCT.get(c, 556 if c.isdigit() else 600)) for c in s)
    return units * px / 1000.0 * 1.02


def rows_of(lines, cls):
    return [(l, cls) if isinstance(l, str) else l for l in lines]


def text_h(lines, cls='s'):
    return sum(k.LH.get(c, 22) for _, c in rows_of(lines, cls))


def check(where, lines, cls, room):
    for s, c in rows_of(lines, cls):
        if tw(s, c) > room:
            WARN.append('%s: "%s" is %.0f px, room %.0f px' % (where, s, tw(s, c), room))


# ------------------------------------------------------------------ small shapes
def tbox(name, cx, cy, lines, w, fill=WHITE, cls='s', h=None, dash=False):
    """A box centred on (cx, cy); its height follows the text. Returns (svg, left, top, right, bottom)."""
    h = h or max(40, text_h(lines, cls) + 14)
    check(name, lines, cls, w - 14)
    x, y = cx - w / 2.0, cy - h / 2.0
    return k.box(round(x), round(y), w, h, lines, fill, cls, 10, dash), x, y, x + w, y + h


def fillrect(x, y, w, h, fill):
    return '<rect x="%d" y="%d" width="%d" height="%d" fill="%s"/>' % (x, y, w, h, fill)


def connector(cx, cy, letter='A'):
    """An off-page connector: the flow goes on in the next diagram."""
    return ('<circle cx="%d" cy="%d" r="16" fill="#fff" stroke="%s" stroke-width="2"/>' % (cx, cy, INK)
            + k.t(cx, cy + 6.5, letter, 'b', 'middle'))


# ================================================================== architecture
def arsitektur_aplikasi():
    """a01: who uses the application, how the application is layered, and what it talks to."""
    H = 500
    p = []
    ax = 97
    for y, name, sub in ((30, 'Admin', '(PC)'), (185, 'Guru', '(telepon)'), (340, 'Murid / orang tua', '(Android, iPhone, web)')):
        p.append(k.stick(ax, y, ''))
        p.append(k.t(ax, y + 93, name, 'sb', 'middle'))
        p.append(k.t(ax, y + 115, sub, 's', 'middle'))
        check('a01 actor', [name], 'sb', 190); check('a01 actor', [sub], 's', 190)
        p.append(k.arrow([(128, y + 40), (216, y + 40)], both=True))
    # the application
    X0, X1 = 218, 660
    p.append(k.rect(X0, 12, X1 - X0, 476, SOFT, 14))
    p.append(k.t((X0 + X1) / 2, 40, 'Aplikasi Flutter', 'b', 'middle'))
    p.append(k.t((X0 + X1) / 2, 63, 'satu basis kode: web, Android, iOS', 's', 'middle'))
    bx, bw = X0 + 20, X1 - X0 - 40
    cx = bx + bw / 2
    layers = ((78, ['View', ('halaman per peran, l10n ID / EN', 's')]),
              (160, ['ViewModel', ('ChangeNotifier + Provider', 's')]),
              (242, ['Service / Repository', ('FlutterFire, satu-satunya jalur ke Firebase', 's')]))
    for y, lines in layers:
        check('a01 layer', lines, 't', bw - 14)
        p.append(k.box(bx, y, bw, 54, lines, WHITE, 't'))
    p.append(k.arrow([(cx, 132), (cx, 160)], both=True))
    p.append(k.arrow([(cx, 214), (cx, 242)], both=True))
    ocr = ['Di peramban admin (tanpa layanan luar)', 'PaddleOCR + onnxruntime-web:', 'pembaca naskah soal PDF', 'Whisper + transformers.js: transkrip']
    check('a01 ocr', ocr, 's', bw - 14)
    p.append(k.box(bx, 314, bw, 98, ocr, YELLOW, 's'))
    chk = ['Firebase App Check', ('reCAPTCHA Enterprise (AI Logic)', 's')]
    p.append(k.box(bx, 424, bw, 54, chk, WHITE, 't'))
    # Firebase, as one block here; its inside is the next diagram
    FX, FW = 735, 250
    p.append(k.rect(FX, 30, FW, 286, BLUE, 14))
    p.append(k.t(FX + FW / 2, 58, 'Firebase', 'b', 'middle'))
    p.append(k.t(FX + FW / 2, 81, '(proyek chinese-tracker)', 's', 'middle'))
    for i, s in enumerate(('Authentication', 'Cloud Firestore', 'Cloud Storage', 'Cloud Messaging', 'Hosting', 'Cloud Functions')):
        p.append(k.box(FX + 15, 96 + i * 35, FW - 30, 30, [s], WHITE, 's', 8))
    p.append(k.arrow([(bx + bw, 269), (FX, 269)], both=True))
    p.append(k.label((X1 + FX) / 2, 259, 'HTTPS', 'middle'))
    # Midtrans talks to Cloud Functions only
    mid = ['Midtrans', ('Snap (VA, e-wallet,', 's'), ('QRIS, kartu)', 's'), ('webhook notifikasi', 's')]
    check('a01 midtrans', mid, 'b', FW - 14)
    p.append(k.box(FX, 386, FW, 102, mid, WHITE, 'b'))
    p.append(k.arrow([(FX + 80, 316), (FX + 80, 386)]))
    p.append(k.label(FX + 72, 357, 'server key', 'end'))
    p.append(k.arrow([(FX + 170, 386), (FX + 170, 316)]))
    p.append(k.label(FX + 178, 357, 'webhook'))
    k.page('a01_arsitektur_aplikasi', 1000, H, p)


def arsitektur_firebase():
    """a02: the services inside Firebase, what Cloud Functions do, and the two lines to Midtrans."""
    H = 496
    p = []
    p.append(k.box(6, 190, 100, 64, ['Aplikasi', 'Flutter'], SOFT, 'b'))
    X0, X1 = 178, 778
    p.append(k.arrow([(106, 222), (X0, 222)], both=True))
    p.append(k.label((106 + X0) / 2, 212, 'HTTPS', 'middle'))
    p.append(k.rect(X0, 12, X1 - X0, 472, BLUE, 14))
    p.append(k.t((X0 + X1) / 2, 41, 'Firebase (proyek chinese-tracker)', 'b', 'middle'))
    sx, sw = X0 + 14, 322
    svc = (('Authentication', 'login, peran lewat profil users'), ('Cloud Firestore', 'basis data dokumen + Security Rules'),
           ('Cloud Storage', 'rekaman, gambar, naskah PDF'), ('Cloud Messaging', 'notifikasi web push'),
           ('Hosting', 'web app, APK, berkas model OCR/ASR'))
    for i, (n, d) in enumerate(svc):
        lines = [n, (d, 's')]
        check('a02 service', lines, 't', sw - 14)
        p.append(k.box(sx, 58 + i * 68, sw, 58, lines, WHITE, 't'))
    fx = sx + sw + 34
    fw = X1 - 14 - fx
    cf = ['Cloud Functions', ('Node.js 22', 's'), ('', 's'), ('callable', 's'), ('trigger Firestore', 's'), ('terjadwal', 's'), ('HTTP (webhook)', 's'),
          ('', 's'), ('penilaian, voucher,', 's'), ('bentrok, kenaikan tingkat,', 's'), ('laporan', 's')]
    check('a02 functions', cf, 'b', fw - 14)
    p.append(k.box(fx, 58, fw, 330, cf, WHITE, 'b'))
    p.append(k.arrow([(sx + sw, 155), (fx, 155)], both=True))            # Firestore <-> Functions
    emu = ['Firebase Emulator Suite', ('(pengembangan dan uji otomatis)', 's')]
    check('a02 emulator', emu, 't', sw - 14)
    p.append(k.box(sx, 408, sw, 60, emu, WHITE, 't', 10, True))
    bak = ['Backup Firestore', ('harian (7 hari)', 's')]
    p.append(k.box(fx, 408, fw, 60, bak, WHITE, 't', 10, True))
    # Midtrans
    mx, mw = 874, 120
    mid = ['Midtrans', ('Snap (VA,', 's'), ('e-wallet,', 's'), ('QRIS, kartu)', 's'), ('webhook', 's'), ('notifikasi', 's')]
    check('a02 midtrans', mid, 'b', mw - 12)
    p.append(k.box(mx, 150, mw, 150, mid, WHITE, 'b'))
    p.append(k.arrow([(fx + fw, 195), (mx, 195)]))
    p.append(k.label((X1 + mx) / 2 + 1, 185, 'server key', 'middle'))
    p.append(k.arrow([(mx, 255), (fx + fw, 255)]))
    p.append(k.label((X1 + mx) / 2 + 1, 277, 'webhook', 'middle'))
    k.page('a02_arsitektur_firebase', 1000, H, p)


# ================================================================== use case
def usecase(name, actor, left, right, pitch):
    """The actor stands between two areas of the system; each use case is tied to the actor by one line."""
    (lt, lc), (rt, rc) = left, right
    n = max(len(lc), len(rc))
    RX, RY = 172, 30
    top, band = 12, 40
    y0 = top + band + 10 + RY
    bottom = y0 + (n - 1) * pitch + RY + 14
    H = bottom + 12
    p = []
    for x, title in ((12, lt), (598, rt)):
        p.append(k.rect(x, top, 390, bottom - top, SOFT, 12))
        p.append(k.t(x + 195, top + 27, title, 'sb', 'middle'))
        check(name + ' title', [title], 'sb', 370)
    ax = 500
    ay = (top + bottom) / 2 - 52
    arm = ay + 33
    for cases, cx, hand, edge in ((lc, 207, ax - 19, 207 + RX), (rc, 793, ax + 19, 793 - RX)):
        ys = [y0 + i * pitch for i in range(len(cases))]
        if len(cases) < n:                                   # centre a shorter column
            shift = (n - len(cases)) * pitch / 2.0
            ys = [y + shift for y in ys]
        for lines, y in zip(cases, ys):
            p.append(k.line([(hand, arm), (edge, y)]))
            check(name + ' use case', lines, 's', 2 * RX * 0.80)
            p.append(k.ellipse(cx, round(y), RX, RY, lines, WHITE, 's'))
    p.append(k.stick(ax, round(ay), ''))
    p.append(k.t(ax, ay + 94, actor, 'n', 'middle'))
    k.page(name, 1000, round(H), p)


def usecases():
    usecase('a03_usecase_admin_1', 'Admin',
            ('Akun dan bank soal', [['Menyetujui atau menolak', 'pendaftaran murid'], ['Mengelola akun guru,', 'murid, dan orang tua'],
                                    ['Mengelola bank soal', 'dan kode tes'], ['Membaca naskah soal', 'HSK dari PDF']]),
            ('Jadwal dan pengumuman', [['Menyusun jadwal dengan', 'pengecekan bentrok'], ['Menunjuk guru pengganti'],
                                       ['Mengelola sesi, hari libur,', 'dan aturan jadwal'], ['Mengirim pengumuman']]), 84)
    usecase('a04_usecase_admin_2', 'Admin',
            ('Voucher dan pembayaran', [['Mengelola paket voucher', 'dan daftar harga'], ['Mencatat pembayaran', 'tunai atau transfer'],
                                        ['Memantau pembayaran', 'Midtrans dan invoice'], ['Memeriksa voucher', 'dan jejak audit']]),
            ('Kenaikan tingkat dan laporan', [['Mengatur aturan', 'kenaikan tingkat'], ['Memutuskan rekomendasi', 'kenaikan tingkat'],
                                              ['Melihat laporan progress', 'semua murid'], ['Melihat laporan bulanan', 'dan rekap guru']]), 84)
    usecase('a05_usecase_guru', 'Guru',
            ('Kelas dan murid', [['Melihat jadwal mengajar', 'dan sesi hari ini'], ['Mengisi ketersediaan', '(bila dinyalakan)'],
                                 ['Check-in dan', 'menutup sesi'], ['Mengisi absensi', 'hadir, izin, alpa'],
                                 ['Melihat data dan', 'progress murid'], ['Menulis catatan', 'tindak lanjut']]),
            ('Soal, latihan, dan tes', [['Menulis soal dan', 'lembar kerja'], ['Menyusun dan menugaskan', 'paket latihan'],
                                        ['Membuka dan', 'mengawasi tes'], ['Menilai jawaban', 'menulis bebas'],
                                        ['Meninjau jawaban Typing', 'yang ditandai'], ['Melihat leaderboard', 'dengan nama lengkap']]), 72)
    sisa = ['Melihat sisa sesi dan', 'tenggat voucher']
    beli = ['Membeli paket', '(Midtrans)']
    pesan = ['Memesan dan membatalkan', 'sesi; daftar tunggu']
    hadir = ['Melihat riwayat', 'kehadiran']
    progress = ['Melihat laporan', 'progress']
    taut = ['Menautkan akun orang tua', 'dengan kode anak']
    akun = ['Mengubah bahasa, kata sandi,', 'menghapus akun']
    usecase('a06_usecase_murid', 'Murid',
            ('Kelas dan voucher', [['Mendaftar sendiri, memilih', 'tes penempatan'], sisa, beli, pesan, hadir]),
            ('Belajar dan akun', [['Mengerjakan latihan', 'yang ditugaskan'], ['Mengikuti tes simulasi', 'dengan token'],
                                  ['Melihat nilai, ulasan,', 'dan leaderboard'], progress, taut, akun]), 72)
    usecase('a07_usecase_orang_tua', 'Orang tua',
            ('Kelas dan voucher anak', [sisa, beli, pesan, hadir]),
            ('Progress, tagihan, dan akun', [progress, taut, ['Membayar tagihan anak'], akun]), 84)


# ================================================================== activity (lanes run top to bottom)
def lanes(names, edges, H):
    p = []
    for i, nm in enumerate(names):
        x0, x1 = edges[i], edges[i + 1]
        p.append(fillrect(x0, 36, x1 - x0, H - 38, SOFT if i % 2 else WHITE))
        p.append(fillrect(x0, 2, x1 - x0, 34, GREY))
        p.append(k.t((x0 + x1) / 2, 26, nm, 'sb', 'middle'))
    p.append('<rect x="2" y="2" width="996" height="%d" fill="none" stroke="%s" stroke-width="2"/>' % (H - 4, INK))
    p.append(k.line([(2, 36), (998, 36)]))
    for x in edges[1:-1]:
        p.append(k.line([(x, 2), (x, H - 2)]))
    return p


def activity_pendaftaran():
    H = 516
    p = lanes(['Calon murid', 'Sistem', 'Admin'], [2, 333, 667, 998], H)
    A = lambda *a, **kw: tbox('a08', *a, **kw)
    p.append(k.dot(166, 52))
    p.append(k.arrow([(166, 61), (166, 80)]))
    s, *_ = A(166, 108, ['Isi formulir pendaftaran: data diri,', 'mulai Beginner atau tes penempatan'], 300); p.append(s)
    p.append(k.arrow([(316, 108), (355, 108)]))
    s, *_ = A(500, 108, ['Buat akun berstatus pending;', 'tampilkan di daftar Persetujuan'], 290); p.append(s)
    p.append(k.arrow([(500, 136), (500, 160)]))
    p.append(k.diamond(500, 200, 122, 40, ['Ada kode hasil', 'penempatan?'], 's'))
    p.append(k.arrow([(622, 200), (690, 200)]))
    p.append(k.label(634, 191, 'Ya'))
    s, *_ = A(834, 200, ['Lihat rekomendasi tingkat', 'dari tes penempatan'], 288); p.append(s)
    p.append(k.arrow([(834, 228), (834, 262)]))
    p.append(k.arrow([(500, 240), (500, 282), (724, 282)]))
    p.append(k.label(510, 263, 'Tidak'))
    s, *_ = A(834, 282, ['Tinjau pendaftaran'], 220, h=40); p.append(s)
    p.append(k.arrow([(744, 302), (744, 325)]))
    p.append(k.diamond(744, 355, 68, 30, ['Disetujui?'], 's'))
    p.append(k.arrow([(812, 355), (870, 355)]))
    p.append(k.label(840, 346, 'Tidak', 'middle'))
    s, *_ = A(931, 355, ['Tolak dengan', 'alasan'], 122); p.append(s)
    p.append(k.arrow([(931, 383), (931, 423)]))
    p.append(k.dot(931, 436, end=True))
    p.append(k.arrow([(744, 385), (744, 408)]))
    p.append(k.label(753, 401, 'Ya'))
    s, *_ = A(775, 436, ['Tetapkan tingkat awal', 'dan guru'], 196); p.append(s)
    p.append(k.arrow([(677, 436), (645, 436)]))
    s, *_ = A(500, 436, ['Status aktif; beri tahu murid', '(decideRegistration)'], 290); p.append(s)
    p.append(k.arrow([(355, 436), (316, 436)]))
    s, *_ = A(166, 436, ['Masuk ke beranda murid'], 300, h=40); p.append(s)
    p.append(k.arrow([(166, 456), (166, 478)]))
    p.append(k.dot(166, 491, end=True))
    k.page('a08_activity_pendaftaran', 1000, H, p)


def activity_pemesanan():
    H = 478
    p = lanes(['Sistem', 'Murid'], [2, 540, 998], H)
    A = lambda *a, **kw: tbox('a09', *a, **kw)
    p.append(k.dot(250, 52))
    p.append(k.arrow([(250, 61), (250, 80)]))
    s, *_ = A(250, 108, ['generateSessions: buat sesi', 'empat belas hari ke depan'], 330); p.append(s)
    p.append(k.arrow([(415, 108), (620, 108)]))
    s, *_ = A(770, 108, ['Pilih sesi pada kalender'], 300, h=40); p.append(s)
    p.append(k.arrow([(770, 128), (770, 200), (450, 200)]))
    s, *_ = A(250, 200, ['bookSession: periksa status, waktu, tingkat,', 'kuota, voucher, bentrok (Algoritma 5.2)'], 400); p.append(s)
    p.append(k.arrow([(250, 228), (250, 260)]))
    p.append(k.diamond(250, 290, 72, 30, ['Lolos?'], 's'))
    p.append(k.arrow([(322, 290), (620, 290)]))
    p.append(k.label(336, 281, 'Tidak'))
    s, *_ = A(770, 290, ['Lihat alasan; masuk daftar', 'tunggu bila penuh'], 300); p.append(s)
    p.append(k.arrow([(920, 290), (949, 290)]))
    p.append(k.dot(962, 290, end=True))
    p.append(k.arrow([(250, 320), (250, 354)]))
    p.append(k.label(260, 343, 'Ya'))
    s, *_ = A(250, 382, ['Pesan tempat: bookedCount +1,', 'sessionsBooked +1, attendance dibuat'], 400); p.append(s)
    p.append(k.arrow([(250, 410), (250, 432)]))
    p.append(connector(250, 448))
    p.append(k.t(278, 454, 'A: berlanjut ke pelaksanaan sesi', 's'))
    k.page('a09_activity_pemesanan_sesi', 1000, H, p)


def activity_penutupan():
    H = 466
    p = lanes(['Sistem', 'Guru'], [2, 540, 998], H)
    A = lambda *a, **kw: tbox('a10', *a, **kw)
    p.append(connector(40, 108))
    p.append(k.arrow([(56, 108), (95, 108)]))
    s, *_ = A(265, 108, ['Pengingat satu jam sebelumnya;', 'sesi mulai sendiri pada jam mulai'], 340); p.append(s)
    p.append(k.arrow([(435, 108), (620, 108)]))
    s, *_ = A(770, 108, ['Check-in (catat kedatangan)'], 300, h=40); p.append(s)
    p.append(k.arrow([(770, 128), (770, 168)]))
    s, *_ = A(770, 196, ['Isi absensi: hadir, izin, alpa;', 'bandingkan papan kehadiran'], 300); p.append(s)
    p.append(k.arrow([(770, 224), (770, 264)]))
    s, *_ = A(770, 284, ['Tutup sesi'], 200, h=40); p.append(s)
    p.append(k.arrow([(670, 284), (485, 284)]))
    s, *_ = A(265, 284, ['closeSession dalam satu transaksi: potong', 'voucher, buku besar, rekap guru (Algoritma 5.3)'], 440); p.append(s)
    p.append(k.arrow([(265, 312), (265, 348)]))
    s, *_ = A(265, 376, ['Perbarui ringkasan progress', 'dan beri tahu bila ada peringatan'], 340); p.append(s)
    p.append(k.arrow([(265, 404), (265, 428)]))
    p.append(k.dot(265, 441, end=True))
    k.page('a10_activity_penutupan_sesi', 1000, H, p)


def activity_tes():
    H = 404
    p = lanes(['Guru', 'Murid', 'Sistem'], [2, 333, 667, 998], H)
    A = lambda *a, **kw: tbox('a11', *a, **kw)
    p.append(k.dot(166, 52))
    p.append(k.arrow([(166, 61), (166, 80)]))
    s, *_ = A(166, 108, ['Buka sesi tes untuk', 'satu kode tes'], 250); p.append(s)
    p.append(k.arrow([(291, 108), (698, 108)]))
    s, *_ = A(833, 108, ['Token enam karakter,', 'berlaku lima belas menit'], 270); p.append(s)
    p.append(k.arrow([(833, 136), (833, 154), (500, 154), (500, 172)]))
    s, *_ = A(500, 200, ['Masukkan token,', 'mulai tes'], 250); p.append(s)
    p.append(k.arrow([(625, 200), (698, 200)]))
    s, *_ = A(833, 200, ['startTest: jam server', 'per bagian'], 270); p.append(s)
    p.append(k.arrow([(833, 228), (833, 246), (500, 246), (500, 264)]))
    s, *_ = A(500, 292, ['Kerjakan bagian; kirim', 'jawaban per bagian'], 250); p.append(s)
    p.append(k.arrow([(625, 292), (698, 292)]))
    s, *_ = A(833, 292, ['Nilai per bagian', '(Algoritma 5.5)'], 270); p.append(s)
    p.append(k.arrow([(724, 320), (724, 350)]))
    p.append(connector(724, 366))
    p.append(k.t(750, 372, 'A: berlanjut ke penilaian akhir', 's'))
    k.page('a11_activity_tes_simulasi', 1000, H, p)


def activity_kenaikan():
    H = 516
    p = lanes(['Guru', 'Sistem', 'Admin'], [2, 333, 667, 998], H)
    A = lambda *a, **kw: tbox('a12', *a, **kw)
    X = 540
    p.append(connector(X, 58))
    p.append(k.arrow([(X, 74), (X, 94)]))
    p.append(k.diamond(X, 134, 112, 40, ['Ada menulis', 'bebas?'], 's'))
    p.append(k.arrow([(X - 112, 134), (291, 134)]))
    p.append(k.label(380, 125, 'Ya', 'middle'))
    s, *_ = A(166, 134, ['Nilai di antrean', 'penilaian (markAnswer)'], 250); p.append(s)
    p.append(k.arrow([(166, 162), (166, 234), (370, 234)]))
    p.append(k.arrow([(X, 174), (X, 206)]))
    p.append(k.label(X + 10, 196, 'Tidak'))
    s, *_ = A(515, 234, ['Hasil final; leaderboard;', 'hitung kenaikan (Algoritma 5.6)'], 290); p.append(s)
    p.append(k.arrow([(X, 262), (X, 292)]))
    p.append(k.diamond(X, 332, 112, 40, ['Syarat naik', 'terpenuhi?'], 's'))
    p.append(k.arrow([(X - 112, 332), (368, 332)]))
    p.append(k.label(401, 323, 'Tidak', 'middle'))
    p.append(k.dot(355, 332, end=True))
    p.append(k.arrow([(X + 112, 332), (710, 332)]))
    p.append(k.label(673, 323, 'Ya'))
    s, *_ = A(840, 332, ['Setujui atau tolak', 'rekomendasi'], 260); p.append(s)
    p.append(k.arrow([(840, 360), (840, 430), (660, 430)]))
    s, *_ = A(515, 430, ['Naik tingkat; catat riwayat;', 'beri tahu murid dan orang tua'], 290); p.append(s)
    p.append(k.arrow([(515, 458), (515, 479)]))
    p.append(k.dot(515, 492, end=True))
    k.page('a12_activity_kenaikan_tingkat', 1000, H, p)


def activity_voucher():
    H = 546
    edges = [2, 266, 437, 767, 998]
    p = lanes(['Murid / orang tua', 'Admin', 'Sistem', 'Midtrans'], edges, H)
    A = lambda *a, **kw: tbox('a13', *a, **kw)
    MO, AD, SI, MI = 132, 352, 602, 882
    R = [106, 194, 282, 370, 458]
    p.append(k.dot(MO, 52))
    p.append(k.arrow([(MO, 61), (MO, 78)]))
    s, *_ = A(MO, R[0], ['Pilih paket pada daftar harga', '(8 atau 16 sesi)'], 240); p.append(s)
    p.append(k.arrow([(MO + 120, R[0]), (SI - 153, R[0])]))
    s, *_ = A(SI, R[0], ['createInvoice: tagihan terbuka;', 'tagihan lama dipakai ulang'], 306); p.append(s)
    p.append(k.arrow([(SI, R[0] + 28), (SI, 146), (MO, 146), (MO, R[1] - 32)]))
    p.append(k.diamond(MO, R[1], 108, 32, ['Bayar daring?'], 's'))
    p.append(k.arrow([(MO + 108, R[1]), (SI - 153, R[1])]))
    p.append(k.label(276, R[1] - 9, 'Ya'))
    s, *_ = A(SI, R[1], ['Minta Snap token', '(server key di fungsi)'], 306); p.append(s)
    p.append(k.arrow([(SI + 153, R[1]), (MI - 106, R[1])]))
    s, *_ = A(MI, R[1], ['Halaman pembayaran:', 'VA, e-wallet, QRIS'], 212); p.append(s)
    p.append(k.arrow([(MI, R[1] + 28), (MI, R[2] - 28)]))
    s, *_ = A(MI, R[2], ['Kirim notifikasi', 'pembayaran (webhook)'], 212); p.append(s)
    p.append(k.arrow([(MI - 106, R[2]), (SI + 153, R[2])]))
    s, *_ = A(SI, R[2], ['midtransNotification: periksa', 'tanda tangan; tandai invoice lunas'], 306); p.append(s)
    p.append(k.arrow([(MO, R[1] + 32), (MO, R[2] - 28)]))
    p.append(k.label(MO + 10, R[1] + 52, 'Tidak'))
    s, *_ = A(MO, R[2], ['Bayar tunai atau transfer', 'kepada admin'], 240); p.append(s)
    p.append(k.arrow([(MO + 120, R[2]), (AD - 78, R[2])]))
    s, *_ = A(AD, R[2], ['markInvoicePaid:', 'catat pembayaran'], 156); p.append(s)
    p.append(k.arrow([(AD, R[2] + 28), (AD, R[3]), (SI - 153, R[3])]))
    p.append(k.arrow([(SI, R[2] + 28), (SI, R[3] - 28)]))
    s, *_ = A(SI, R[3], ['Buat term voucher dengan masa', 'berlaku; catat voucher_history'], 306); p.append(s)
    p.append(k.arrow([(SI, R[3] + 28), (SI, R[4] - 28)]))
    s, *_ = A(SI, R[4], ['Beri tahu murid; expireVouchers', 'menghanguskan sisa setelah tenggat'], 306); p.append(s)
    p.append(k.arrow([(SI, R[4] + 28), (SI, 509)]))
    p.append(k.dot(SI, 522, end=True))
    k.page('a13_activity_pembelian_voucher', 1000, H, p)


# ================================================================== page map
def peta(name, groups, cols, bw, bh, pitch):
    """groups: (role, [columns]); a column is a list of pages; a page is a list of lines."""
    gap = (1000 - 24 - cols * bw) / float(cols - 1)
    xs = [12 + i * (bw + gap) for i in range(cols)]
    rows = max(len(c) for _, cl in groups for c in cl)
    y0 = 74
    H = y0 + (rows - 1) * pitch + bh + 14
    p = []
    ci = 0
    spine, boxes = [], []
    for role, cl in groups:
        x0, x1 = xs[ci], xs[ci + len(cl) - 1] + bw
        boxes.append(k.box(round(x0), 12, round(x1 - x0), 40, [role], GREY, 'b', 10))
        for j, col in enumerate(cl):
            x = xs[ci + j]
            cx = x + bw / 2.0
            spine.append(k.line([(cx, 52), (cx, y0 + (len(col) - 1) * pitch)]))
            for r, lines in enumerate(col):
                check(name, lines, 's', bw - 14)
                boxes.append(k.box(round(x), y0 + r * pitch, bw, bh, lines, WHITE, 's', 8))
        ci += len(cl)
    k.page(name, 1000, round(H), p + spine + boxes)


def peta_halaman():
    peta('a14_peta_halaman_umum_admin',
         [('Umum', [[['Halaman depan (landing)'], ['Login, bahasa ID / EN'], ['Daftar murid baru'],
                     ['Tes penempatan', 'pengunjung'], ['Menunggu persetujuan'], ['Kebijakan privasi']]]),
          ('Admin', [[['Dashboard: hari ini,', 'angka, berita'], ['Pengguna dan Persetujuan'], ['Bank soal, kode tes,', 'pembaca naskah'], ['Paket latihan']],
                     [['Timetable: jadwal,', 'kalender, libur, aturan'], ['Halaman kelas (sesi)'], ['Voucher, daftar harga,', 'invoice'], ['Promosi tingkat']],
                     [['Laporan bulanan,', 'rekap guru'], ['News (pengumuman)'], ['Pengaturan organisasi,', 'audit'], ['Profil']]])],
         4, 232, 52, 62)
    peta('a15_peta_halaman_guru_murid_orang_tua',
         [('Guru', [[['Jadwal mengajar:', 'hari ini, minggu,', 'ketersediaan'], ['Pelaksanaan sesi', 'dan absensi'], ['Murid saya:', 'progress, catatan'],
                     ['Bank soal dan', 'lembar kerja'], ['Paket latihan', 'dan penugasan']],
                    [['Sesi tes dan', 'pengawasan'], ['Antrean penilaian'], ['Materi'], ['Profil']]]),
          ('Murid', [[['Beranda:', 'kelas berikutnya,', 'pengumuman'], ['Pesan sesi: kalender,', 'daftar tunggu'], ['Voucher dan', 'pembayaran:', 'beli paket'],
                      ['Latihan: ditugaskan,', 'riwayat']],
                     [['Tes: kode tes, hasil,', 'leaderboard'], ['Progress'], ['Profil: bahasa,', 'kata sandi,', 'hapus akun']]]),
          ('Orang tua', [[['Progress anak'], ['Kehadiran anak'], ['Tagihan dan', 'pembayaran'], ['Profil']]])],
         5, 188, 74, 82)


if __name__ == '__main__':
    k.setup(WORK)
    arsitektur_aplikasi()
    arsitektur_firebase()
    usecases()
    activity_pendaftaran()
    activity_pemesanan()
    activity_penutupan()
    activity_tes()
    activity_kenaikan()
    activity_voucher()
    peta_halaman()
    k.shoot(OUT)
    for w in WARN:
        print('CHECK', w)
