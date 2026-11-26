#!/usr/bin/env python3
"""Draws the diagrams of Bab III of the book (Gambar 3.5 to 3.13): the old,
manual way of working at Easy Study.

usage:
  python3 -I docs/thesis/tools/make_bab3_figs.py [out_dir] [work_dir]

out_dir   where fig_3_N.png goes (default: docs/thesis/word)
work_dir  where the intermediate fig_3_N.html pages go (default: a temp folder)

Every figure is our own drawing, made with figkit.py: a canvas 1000 px wide
(14 cm in the book) and at most 550 px high, because a diagram takes at most
half a page. That is why the rich picture is two figures, the use case
diagram three (one per group of actors) and each activity diagram two (cut
where the process changes hands). The content follows the owner's answers
of 2026-11-24 about the old system; nothing is read from the code.

  3.5   rich picture: registration, daily session list, payment
  3.6   rich picture: teaching, attendance, marks
  3.7   use case: prospective student and student
  3.8   use case: admin
  3.9   use case: teacher and owner
  3.10  activity: registration
  3.11  activity: payment
  3.12  activity: sitting a simulation test
  3.13  activity: marking and moving up a level

The height of each figure in the book is 14 cm x H/W; enter it in
FIG_SIZE_CM of build_book.py (shoot() prints it).
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import figkit as k

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(os.path.dirname(HERE), 'word')
WORK = sys.argv[2] if len(sys.argv) > 2 else None
W = k.W
RED = '#b91c1c'


# ------------------------------------------------------------------ small helpers
def tx(x, y, s, cls='s', anchor='middle', style=''):
    st = ' style="%s"' % style if style else ''
    return '<text x="%.1f" y="%.1f" text-anchor="%s" class="%s"%s>%s</text>' % (x, y, anchor, cls, st, k.esc(s))


def rows(x, y0, lines, cls='lbl', anchor='middle', lh=21, style=''):
    """Several lines; the first baseline is at y0."""
    return ''.join(tx(x, y0 + i * lh, s, cls, anchor, style) for i, s in enumerate(lines))


def actor2(cx, y, line1, line2):
    """An actor whose name needs two lines."""
    return k.stick(cx, y, line1) + tx(cx, y + 92 + 20, line2, 'sb')


# ------------------------------------------------------------------ rich picture icons
def whatsapp(cx, cy):
    g = '#15803d'
    return ('<rect x="%d" y="%d" width="60" height="84" rx="10" fill="#dcfce7" stroke="%s" stroke-width="3"/>' % (cx - 30, cy - 42, g)
            + '<rect x="%d" y="%d" width="44" height="60" rx="5" fill="#fff" stroke="%s" stroke-width="1.5"/>' % (cx - 22, cy - 32, g)
            + tx(cx, cy + 6, 'WA', 'sb') + tx(cx, cy + 42 + 21, 'WhatsApp', 'sb'))


def sheet(cx, cy, name='Spreadsheet'):
    x, y, w, h = cx - 55, cy - 33, 110, 66
    p = [k.rect(x, y, w, h, k.WHITE, rx=2),
         '<rect x="%d" y="%d" width="%d" height="16" fill="#dbeafe" stroke="%s" stroke-width="2"/>' % (x, y, w, k.INK)]
    for i in (1, 2, 3):
        p.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s" stroke-width="1"/>' % (x + i * w / 4, y, x + i * w / 4, y + h, k.INK))
    for j in (1, 2):
        yy = y + 16 + j * (h - 16) / 3
        p.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="%s" stroke-width="1"/>' % (x, yy, x + w, yy, k.INK))
    p.append(tx(cx, cy + 33 + 23, name, 'sb'))
    return ''.join(p)


def paper(cx, cy, name):
    x, y, w, h, f = cx - 28, cy - 36, 56, 72, 15
    p = ['<path d="M%d,%d H%d L%d,%d V%d H%d Z" fill="#fffbe6" stroke="%s" stroke-width="2"/>' % (x, y, x + w - f, x + w, y + f, y + h, x, k.INK),
         '<path d="M%d,%d V%d H%d" fill="none" stroke="%s" stroke-width="2"/>' % (x + w - f, y, y + f, x + w, k.INK)]
    for j in range(4):
        yy = y + 26 + j * 11
        p.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="1"/>' % (x + 9, yy, x + w - 9, yy, k.INK))
    p.append(tx(cx, cy + 36 + 26, name, 'sb'))
    return ''.join(p)


def monitor(cx, cy, name):
    x, y, w, h = cx - 52, cy - 36, 104, 62
    return (k.rect(x, y, w, h, '#eef2ff', rx=5) + k.rect(x + 9, y + 9, w - 18, h - 18, k.WHITE, rx=2, sw=1)
            + tx(cx, y + h / 2 + 6, 'HSK: 78', 's')
            + '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (cx, y + h, cx, y + h + 10, k.INK)
            + '<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (cx - 26, y + h + 10, cx + 26, y + h + 10, k.INK)
            + tx(cx, cy + 36 + 26, name, 'sb'))


def bubble(x, y, w, lines, dots):
    """What a person wonders about: a rounded yellow note and the small circles that lead to the head."""
    h = 14 + 21 * len(lines) + 8
    p = ['<rect x="%d" y="%d" width="%d" height="%d" rx="22" fill="#fffbe6" stroke="%s" stroke-width="2"/>' % (x, y, w, h, k.INK)]
    p.append(rows(x + w / 2, y + 14 + 15, lines, 's', 'middle', 21, 'font-style:italic'))
    for cx, cy, r in dots:
        p.append('<circle cx="%d" cy="%d" r="%d" fill="#fffbe6" stroke="%s" stroke-width="2"/>' % (cx, cy, r, k.INK))
    return ''.join(p)


def cross(cx, cy, r=9):
    return ''.join('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#dc2626" stroke-width="3"/>' % a
                   for a in ((cx - r, cy - r, cx + r, cy + r), (cx - r, cy + r, cx + r, cy - r)))


# ------------------------------------------------------------------ 3.5 rich picture, front office
def rich_front():
    p = []
    # flows first, so that the icons and the labels lie on top
    p.append(k.arrow([(100, 80), (316, 215)]))                      # calon murid -> WhatsApp
    p.append(k.arrow([(100, 335), (316, 262)]))                     # murid -> WhatsApp
    p.append(k.arrow([(384, 240), (628, 240)], both=True))          # WhatsApp <-> admin
    p.append(k.arrow([(858, 62), (692, 210)]))                      # pemilik usaha -> admin
    p.append(k.arrow([(660, 292), (660, 380)]))                     # admin -> spreadsheet
    p.append(k.stick(70, 30, 'Calon murid'))
    p.append(k.stick(70, 290, 'Murid'))
    p.append(k.stick(660, 190, 'Admin'))
    p.append(k.stick(900, 15, 'Pemilik usaha'))
    p.append(whatsapp(350, 240))
    p.append(sheet(660, 416))
    p.append(rows(135, 62, ['tanya kelas, biaya, jam belajar,', 'lalu mendaftar'], anchor='start'))
    p.append(rows(135, 352, ['tulis nama di daftar sesi,', 'bukti transfer, izin'], anchor='start'))
    p.append(rows(506, 208, ['pesan masuk satu per satu;', 'daftar sesi harian ke grup']))
    p.append(rows(790, 168, ['bertanya keadaan kursus'], anchor='start'))
    p.append(rows(674, 328, ['catat murid, pembayaran,', 'sisa sesi'], anchor='start'))
    p.append(bubble(8, 198, 172, ['Sisa sesi saya', 'tinggal berapa?'], [(80, 284, 5), (88, 269, 7)]))
    p.append(bubble(438, 78, 208, ['Chat menumpuk, semua', 'harus lewat saya'], [(650, 174, 5), (642, 158, 7)]))
    k.page('fig_3_5', W, 490, p)


# ------------------------------------------------------------------ 3.6 rich picture, teaching
def rich_teaching():
    p = []
    p.append(k.arrow([(520, 104), (520, 196)]))                     # pemilik usaha -> guru
    p.append(k.arrow([(156, 236), (492, 236)], both=True))          # admin <-> guru
    p.append(k.arrow([(550, 236), (875, 236)]))                     # guru -> murid
    p.append(k.arrow([(126, 300), (126, 424)]))                     # admin -> spreadsheet
    p.append(k.arrow([(505, 300), (407, 416)]))                     # guru -> daftar hadir kertas
    p.append(k.arrow([(535, 300), (632, 416)]))                     # guru -> web nilai
    p.append(k.arrow([(370, 461), (185, 461)], dash=True))          # daftar hadir -> spreadsheet
    p.append(k.stick(520, 4, 'Pemilik usaha'))
    p.append(k.stick(126, 200, 'Admin'))
    p.append(k.stick(520, 200, 'Guru'))
    p.append(k.stick(905, 200, 'Murid'))
    p.append(sheet(126, 461))
    p.append(paper(400, 456, 'Daftar hadir kertas'))
    p.append(monitor(640, 456, 'Web Nilai Simulasi HSK'))
    p.append(rows(532, 156, ['bertanya perkembangan murid'], anchor='start'))
    p.append(rows(324, 205, ['kabari siapa yang datang hari itu,', 'tanya kesediaan guru (WhatsApp)']))
    p.append(cross(324, 262))
    p.append(rows(324, 294, ['tidak ada jadwal tertulis:', 'pemakaian guru dan ruang', 'tidak terpantau'],
                  style='fill:%s;font-weight:bold' % RED))
    p.append(rows(712, 205, ['koreksi latihan dan tes di kertas,', 'nilai diberitahukan lisan']))
    p.append(rows(114, 344, ['catat murid,', 'pembayaran,', 'sisa sesi'], anchor='end'))
    p.append(rows(418, 388, ['catat kehadiran'], anchor='end'))
    p.append(rows(607, 372, ['input nilai per bagian'], anchor='start'))
    p.append(rows(278, 428, ['disetor berkala, sisa', 'sesi dihitung manual']))
    p.append(bubble(600, 6, 250, ['Bagaimana perkembangan', 'tiap murid?'], [(552, 22, 5), (575, 26, 7)]))
    p.append(bubble(262, 104, 216, ['Besok mengajar siapa,', 'jam berapa?'], [(497, 188, 5), (485, 173, 7)]))
    k.page('fig_3_6', W, 542, p)


# ------------------------------------------------------------------ use case diagrams
RX, RY, PITCH, ROW1 = 145, 27, 61, 76
XL, XR = 310, 640                     # centres of the two columns of use cases


def row(i):
    return ROW1 + PITCH * (i - 1)


def uc(cx, cy, lines, rx=RX):
    return k.ellipse(cx, cy, rx, RY, lines, k.SOFT, 's')


def system(x1, x2, y2):
    return (k.rect(x1, 6, x2 - x1, y2 - 6, k.WHITE, rx=8)
            + tx((x1 + x2) / 2, 31, 'Sistem lama Easy Study (manual)', 'sb'))


def usecase_students():
    """Prospective student and student; the teacher and the admin are the other party of three use cases.
    A left actor stands level with an empty row of the left column, so its lines to the right column cross nothing."""
    left = {1: ['Menghubungi admin', '(WhatsApp / datang)'], 2: ['Mengisi Google Form', 'data diri'],
            4: ['Membayar paket', '(transfer / tunai)'], 5: ['Mengirim bukti transfer'],
            7: ['Menulis nama di', 'daftar sesi harian'], 8: ['Mengerjakan latihan dan', 'tes simulasi di kertas']}
    y_c3, y_m4, y_m6 = row(3), row(6) - PITCH / 2, row(6) + PITCH / 2
    calon, murid, guru, admin = (95, 190), (95, 373), (875, 262), (875, 438)
    p = [system(150, 800, 542)]
    for i in (1, 2):
        p.append(k.line([calon, (XL - RX, row(i))]))
    p.append(k.line([calon, (XR - RX, y_c3)]))
    for i in (4, 5, 7, 8):
        p.append(k.line([murid, (XL - RX, row(i))]))
    p.append(k.line([murid, (XR - RX, y_m4)]))
    p.append(k.line([murid, (XR - RX, y_m6)]))
    p.append(k.line([guru, (XR + RX, y_c3)]))
    p.append(k.line([guru, (XR + RX, y_m4)]))
    p.append(k.line([admin, (XR + RX, y_m6)]))
    for i, lines in left.items():
        p.append(uc(XL, row(i), lines))
    p.append(uc(XR, y_c3, ['Memilih mulai Beginner', 'atau tes singkat']))
    p.append(uc(XR, y_m4, ['Mengikuti sesi', '(tingkat campuran)']))
    p.append(uc(XR, y_m6, ['Menanyakan sisa sesi']))
    p.append(k.stick(70, 152, 'Calon murid'))
    p.append(actor2(70, 335, 'Murid /', 'orang tua'))
    p.append(k.stick(905, 224, 'Guru'))
    p.append(k.stick(905, 400, 'Admin'))
    k.page('fig_3_7', W, 548, p)


def usecase_admin():
    left = {1: ['Mengirim tautan', 'Google Form'], 2: ['Meneruskan bukti transfer', 'ke pemilik usaha'],
            3: ['Menulis kwitansi, mencatat', 'paket di Excel voucher'],
            5: ['Mengirim daftar sesi', 'harian ke grup WhatsApp'], 6: ['Mengurangi sesi dari', 'daftar hadir kertas'],
            7: ['Mengingatkan paket', 'hampir habis'], 8: ['Mencetak dan menstok', 'soal HSK lama']}
    y_a8, y_a9 = row(4) - PITCH / 2, row(4) + PITCH / 2
    admin, guru = (95, 251), (875, 285)
    p = [system(150, 800, 542)]
    for i in left:
        p.append(k.line([admin, (XL - RX, row(i))]))
    p.append(k.line([admin, (XR - RX, y_a8)]))
    p.append(k.line([admin, (XR - RX, y_a9)]))
    p.append(k.line([guru, (XR + RX, y_a9)]))
    for i, lines in left.items():
        p.append(uc(XL, row(i), lines))
    p.append(uc(XR, y_a8, ['Membuat rekap bulanan']))
    p.append(uc(XR, y_a9, ['Mencari guru pengganti']))
    p.append(k.stick(70, 213, 'Admin'))
    p.append(k.stick(905, 247, 'Guru'))
    k.page('fig_3_8', W, 548, p)


def usecase_teacher_owner():
    """One column: the owner on the left, the teacher on the right, the shared use case between their own."""
    cx, rx, pitch, y1 = 500, 175, 62, 80
    items = [['Menerima pemberitahuan pembayaran'], ['Membaca rekap bulanan'], ['Menanyakan perkembangan murid'],
             ['Mencatat kehadiran di kertas'], ['Mengawasi tes dan memutar audio'],
             ['Mengoreksi; memutuskan tes', 'dan kenaikan tingkat']]
    ys = [y1 + pitch * i for i in range(len(items))]
    owner, teacher = (165, 142), (835, 297)
    p = [system(290, 710, ys[-1] + RY + 16)]
    for i in (0, 1, 2):
        p.append(k.line([owner, (cx - rx, ys[i])]))
    for i in (2, 3, 4, 5):
        p.append(k.line([teacher, (cx + rx, ys[i])]))
    for y, lines in zip(ys, items):
        p.append(uc(cx, y, lines, rx))
    p.append(k.stick(140, 104, 'Pemilik usaha'))
    p.append(k.stick(860, 259, 'Guru'))
    k.page('fig_3_9', W, ys[-1] + RY + 16 + 8, p)


# ------------------------------------------------------------------ activity diagrams (lanes are rows, time runs to the right)
STRIP = 92


def lanes(specs, h):
    """specs: (name lines, y0, y1) from top to bottom."""
    p = []
    for i, (names, y0, y1) in enumerate(specs):
        p.append('<rect x="0" y="%d" width="%d" height="%d" fill="%s"/>' % (y0, W, y1 - y0, k.SOFT if i % 2 else k.WHITE))
        p.append('<rect x="0" y="%d" width="%d" height="%d" fill="%s"/>' % (y0, STRIP, y1 - y0, k.GREY))
        p.append(k.text(STRIP / 2, (y0 + y1) / 2, names, 'sb'))
        if i:
            p.append('<line x1="0" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (y0, W, y0, k.INK))
    p.append('<line x1="%d" y1="0" x2="%d" y2="%d" stroke="%s" stroke-width="2"/>' % (STRIP, STRIP, h, k.INK))
    p.append('<rect x="1" y="1" width="%d" height="%d" fill="none" stroke="%s" stroke-width="2"/>' % (W - 2, h - 2, k.INK))
    return ''.join(p)


def act(x, cy, w, lines):
    """An action, centred on cy. Returns (svg, top, bottom)."""
    h = 22 * len(lines) + 10
    return k.box(x, cy - h / 2, w, h, lines, k.WHITE, 's', rx=12), cy - h / 2, cy + h / 2


def activity_registration():
    h = 430
    c, a, g = 75, 225, 365
    p = [lanes([(['Calon', 'murid'], 0, 150), (['Admin'], 150, 300), (['Guru'], 300, h)], h)]
    b1, t1, u1 = act(140, c, 200, ['Hubungi admin lewat', 'WhatsApp atau datang', 'langsung'])
    b2, t2, u2 = act(250, a, 205, ['Jelaskan kelas, biaya,', 'jam sesi; kirim tautan', 'Google Form'])
    b3, t3, u3 = act(400, c, 190, ['Isi Google Form', 'data diri'])
    b4, t4, u4 = act(490, a, 185, ['Tanya: mulai dari', 'Beginner atau tes', 'singkat?'])
    b5, t5, u5 = act(670, g, 200, ['Beri tes singkat lisan,', 'tentukan tingkat awal'])
    b6, t6, u6 = act(862, a, 132, ['Sebutkan paket', '8 / 16 sesi', 'dan harganya'])
    p += [k.dot(110, c), k.arrow([(119, c), (140, c)]),
          k.arrow([(300, u1), (300, t2)]),                      # hubungi -> jelaskan
          k.arrow([(430, t2), (430, u3)]),                      # jelaskan -> isi form
          k.arrow([(550, u3), (550, t4)]),                      # isi form -> tanya
          k.arrow([(675, a), (702, a)]),                        # tanya -> keputusan
          k.arrow([(770, a + 40), (770, t5)]),                  # ya -> tes singkat
          k.arrow([(838, a), (862, a)]),                        # tidak -> sebutkan paket
          k.arrow([(870, g), (928, g), (928, u6)]),             # tes singkat -> sebutkan paket
          k.arrow([(928, t6), (928, c + 14)]),                  # sebutkan paket -> selesai
          b1, b2, b3, b4, b5, b6,
          k.diamond(770, a, 68, 40, ['Tes', 'singkat?']),
          k.dot(928, c, end=True),
          k.label(780, a + 66, 'Ya'), k.label(918, a - 50, 'Tidak (Beginner)', 'end'),
          k.label(905, c + 6, 'lanjut ke pembayaran', 'end')]
    k.page('fig_3_10', W, h, p)


def activity_payment():
    h = 450
    c, a, o = 88, 215, 390
    p = [lanes([(['Calon', 'murid'], 0, 150), (['Admin'], 150, 330), (['Pemilik', 'usaha'], 330, h)], h)]
    b1, t1, u1 = act(140, c, 132, ['Bayar paket:', 'transfer atau', 'tunai'])
    b2, t2, u2 = act(462, c, 170, ['Kirim bukti transfer', 'ke admin'])
    b3, t3, u3 = act(457, a, 180, ['Teruskan bukti', 'transfer ke pemilik', 'usaha'])
    b4, t4, u4 = act(452, o, 190, ['Terima pemberitahuan', 'pembayaran'])
    b5, t5, u5 = act(655, a, 160, ['Tulis kwitansi', 'fisik; catat paket', 'di Excel voucher', 'aktif'])
    b6, t6, u6 = act(845, a, 148, ['Masukkan murid', 'ke grup', 'WhatsApp siswa'])
    p += [k.dot(110, c), k.arrow([(119, c), (140, c)]),
          k.arrow([(272, c), (298, c)]),                        # bayar -> keputusan
          k.arrow([(422, c), (462, c)]),                        # ya -> kirim bukti
          k.arrow([(360, c - 38), (360, 16), (735, 16), (735, t5)]),   # tidak (tunai) -> kwitansi
          k.arrow([(547, u2), (547, t3)]),                      # kirim bukti -> teruskan
          k.arrow([(547, u3), (547, t4)]),                      # teruskan -> pemilik menerima
          k.arrow([(642, o), (735, o), (735, u5)]),             # pemilik -> kwitansi
          k.arrow([(815, a), (845, a)]),                        # kwitansi -> grup WhatsApp
          k.arrow([(919, u6), (919, 287)]),                     # grup -> selesai
          b1, b2, b3, b4, b5, b6,
          k.diamond(360, c, 62, 38, ['Transfer?']),
          k.dot(919, 300, end=True),
          k.label(442, c - 9, 'Ya', 'middle'), k.label(372, 40, 'Tidak (tunai)')]
    k.page('fig_3_11', W, h, p)


def activity_test():
    h = 380
    g, a, m = 75, 210, 325
    p = [lanes([(['Guru'], 0, 150), (['Admin'], 150, 270), (['Murid'], 270, h)], h)]
    b1, t1, u1 = act(132, g, 215, ['Nilai murid perlu dites:', 'sudah lama tidak dites', 'atau mencapai titik', 'tertentu'])
    b2, t2, u2 = act(300, a, 200, ['Ambil soal HSK lama', 'yang sudah dicetak', 'dari stok arsip'])
    b3, t3, u3 = act(455, g, 190, ['Awasi tes dan putar', 'rekaman bagian', 'mendengarkan'])
    b4, t4, u4 = act(525, m, 170, ['Kerjakan tes', 'di kertas'])
    b5, t5, u5 = act(690, g, 215, ['Koreksi; hitung nilai per', 'bagian (mendengarkan,', 'membaca, menulis)'])
    p += [k.dot(106, g), k.arrow([(115, g), (132, g)]),
          k.arrow([(325, u1), (325, t2)]),                      # perlu dites -> ambil soal
          k.arrow([(478, t2), (478, u3)]),                      # ambil soal -> awasi tes
          k.arrow([(610, u3), (610, t4)]),                      # awasi -> murid mengerjakan
          k.arrow([(695, m), (797, m), (797, u5)]),             # murid -> koreksi
          k.arrow([(905, g), (946, g)]),                        # koreksi -> selesai
          b1, b2, b3, b4, b5,
          k.dot(960, g, end=True),
          rows(955, g + 36, ['lanjut ke', 'penilaian'])]
    k.page('fig_3_12', W, h, p)


def activity_promotion():
    h = 385
    top, low, m = 75, 205, 328
    p = [lanes([(['Guru'], 0, 270), (['Murid'], 270, h)], h)]
    b7, t7, u7 = act(352, top, 180, ['Catat nilai; hitung', 'tes simulasi yang', 'sudah lulus'])
    b9, t9, u9 = act(818, top, 176, ['Nyatakan naik', 'tingkat; beri tahu', 'murid secara lisan'])
    b6, t6, u6 = act(131, low, 190, ['Lanjut latihan,', 'tes ulang nanti'])
    b8, t8, u8 = act(577, low, 190, ['Lanjut belajar di', 'tingkat yang sama'])
    b10, t10, u10 = act(767, m, 225, ['Terima kabar naik tingkat', '(misalnya "selamat datang', 'di HSK 2")'])
    p += [k.dot(106, top), k.arrow([(115, top), (134, top)]),
          k.arrow([(318, top), (352, top)]),                    # ya -> catat nilai
          k.arrow([(532, top), (560, top)]),                    # catat nilai -> keputusan kedua
          k.arrow([(784, top), (818, top)]),                    # ya -> naik tingkat
          k.arrow([(226, top + 46), (226, t6)]),                # tidak -> lanjut latihan
          k.arrow([(672, top + 50), (672, t8)]),                # tidak -> tingkat yang sama
          k.arrow([(321, low), (577, low)]),                    # lanjut latihan -> tingkat yang sama
          k.arrow([(767, low), (816, low)]),                    # -> selesai
          k.arrow([(906, u9), (906, t10)]),                     # naik tingkat -> murid menerima kabar
          k.arrow([(767, m), (738, m)]),                        # -> selesai
          b6, b7, b8, b9, b10,
          k.diamond(226, top, 92, 46, ['Sekitar 60 %', 'tiap bagian?']),
          k.diamond(672, top, 112, 50, ['Lulus 2–3 tes dan', 'latihan cukup?']),
          k.dot(830, low, end=True), k.dot(725, m, end=True),
          k.label(335, top - 9, 'Ya', 'middle'), k.label(801, top - 9, 'Ya', 'middle'),
          k.label(236, top + 82, 'Tidak'), k.label(682, top + 86, 'Tidak')]
    k.page('fig_3_13', W, h, p)


if __name__ == '__main__':
    k.setup(WORK)
    rich_front()
    rich_teaching()
    usecase_students()
    usecase_admin()
    usecase_teacher_owner()
    activity_registration()
    activity_payment()
    activity_test()
    activity_promotion()
    k.shoot(OUT)
