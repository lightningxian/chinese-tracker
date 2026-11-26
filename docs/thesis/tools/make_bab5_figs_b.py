#!/usr/bin/env python3
"""Draws the new diagrams of Bab V: data model, sequence and status diagrams.

usage:
  python3 -I docs/thesis/tools/make_bab5_figs_b.py [out_dir] [work_dir]

out_dir   where the PNG files go (default: docs/thesis/word/bab5_new)
work_dir  where the intermediate HTML pages go (default: a temp folder)

Eleven figures, each at most half a page (figkit.py: canvas 1000 px wide =
14 cm, at most 550 px high, text of 17 px or more):

  b01 to b06  data model: the collections, how a document ID is formed,
              key fields, and the field that refers to another collection
  b07 to b09  sequence: closing a class session, a supervised test with a
              token, booking a session
  b10, b11    status: a class session; an invoice and a voucher term

Collection names, document IDs, fields, function names and status values
are the ones the code writes (functions/index.js, scheduling.js,
teaching_day.js, payments.js, promotion.js, marking.js, lib/models; read
2026-11-26, after Build 9D). Change them here when the code changes;
nothing is read from the code at run time.
"""
import os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)                    # python3 -I leaves the script's folder out
import figkit as k

OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(os.path.dirname(HERE), 'word', 'bab5_new')
WORK = sys.argv[2] if len(sys.argv) > 2 else None

BW = 268                       # width of a collection box: three in a row with room for the referring field
COLS = (4, 366, 728)
ID_STYLE = 'font-size:17px;fill:#374151'
SUB_STYLE = ("font-size:17px;font-family:Menlo,'Courier New',monospace;"
             'paint-order:stroke;stroke:#fff;stroke-width:6px;stroke-linejoin:round')


def st(x, y, s, style, anchor='start'):
    """One line with an inline style (for the two text kinds the kit has no class for)."""
    return '<text x="%.1f" y="%.1f" text-anchor="%s" style="%s">%s</text>' % (x, y, anchor, style, k.esc(s))


# ------------------------------------------------------------------ data model pieces
T_LH, I_LH, F_LH = 23, 21, 21


def ent_h(titles, ids, fields):
    return 8 + T_LH * len(titles) + I_LH * len(ids) + 7 + 8 + F_LH * len(fields) + 8


def ent(x, y, titles, ids, fields, fill=k.BLUE, bw=BW):
    """A collection: name and how its document ID is formed in the band, key fields under it."""
    band = 8 + T_LH * len(titles) + I_LH * len(ids) + 7
    h = ent_h(titles, ids, fields)
    p = [k.rect(x, y, bw, h, k.WHITE)]
    p.append('<path d="M%d,%d h%d a8,8 0 0 1 8,8 v%d h-%d v-%d a8,8 0 0 1 8,-8 z" fill="%s" stroke="%s" stroke-width="2"/>'
             % (x + 8, y, bw - 16, band - 8, bw, band - 8, fill, k.INK))
    yy = y + 8
    for s in titles:
        p.append(k.t(x + bw / 2, yy + T_LH * 0.76, s, 'mb', 'middle'))
        yy += T_LH
    for s in ids:
        p.append(st(x + bw / 2, yy + I_LH * 0.76, s, ID_STYLE, 'middle'))
        yy += I_LH
    yy = y + band + 8
    for s in fields:
        p.append(k.t(x + 12, yy + F_LH * 0.76, s, 'm'))
        yy += F_LH
    return ''.join(p)


def pill(cx, y, w, s, h=44):
    """A collection that is drawn in full in another figure."""
    return k.rect(cx - w // 2, y, w, h, k.GREY, rx=22) + k.t(cx, y + h / 2 + 6, s, 'mb', 'middle')


def draw(name, parts, h):
    k.page(name, k.W, h, parts)


# ------------------------------------------------------------------ b01 users, schedules, class sessions
def b01():
    c1, c2, c3 = COLS
    y = 14
    E = [(c1, ['users'], ['ID: {uid} dari Firebase Auth'],
          ['role · status', 'name', 'nameChinese', 'level', 'teacherId'], k.GREY),
         (c2, ['schedules'], ['ID: otomatis'],
          ['className · weekday', 'startMinutes', 'endMinutes', 'room · capacity', 'teacherId'], k.BLUE),
         (c3, ['class_sessions'], ['ID: {scheduleId}_{yyyyMMdd}'],
          ['scheduleId', 'sessionDate', 'teacherId · room', 'capacity · bookedCount', 'status'], k.BLUE)]
    h = max(ent_h(t, i, f) for _, t, i, f, _ in E)
    p = [k.rel_h(c1 + BW, c2, y + 30, 'teacherId', '1', 'N'),
         k.rel_h(c2 + BW, c3, y + 30, 'scheduleId', '1', 'N')]
    yb = y + h + 40
    p.append(k.line([(c1 + 134, y + h), (c1 + 134, yb), (c3 + 134, yb), (c3 + 134, y + h)]))
    p.append(k.t(500, yb - 8, 'teacherId: guru sesi (berubah bila ada guru pengganti)', 'lbl', 'middle'))
    p.append(k.mult(c1 + 146, y + h + 20, '1', 'start'))
    p.append(k.mult(c3 + 122, y + h + 20, 'N', 'end'))
    for x, t, i, f, fill in E:
        p.append(ent(x, y, t, i, f, fill))
    n, nh = k.note(4, yb + 18, 992, [
        'Garis menunjukkan field yang merujuk dokumen lain: satu dokumen (1) dirujuk banyak dokumen (N).',
        'class_sessions dibuat fungsi generateSessions dari schedules untuk 14 hari ke depan.'])
    p.append(n)
    draw('b01_data_pengguna_jadwal', p, yb + 18 + nh + 12)


# ------------------------------------------------------------------ b02 booking and attendance
def b02():
    c1, c2, c3 = COLS
    y = 14
    A = (['attendance'], ['ID: {sessionId}_{studentId}'],
         ['sessionId · studentId', 'booked · attended', 'attendanceStatus', 'classTermId', 'sessionCredited'])
    S = (['class_sessions'], ['ID: {scheduleId}_{yyyyMMdd}'], ['sessionDate', 'capacity · bookedCount', 'status'])
    Wt = (['waitlist'], ['ID: {sessionId}_{studentId}'], ['sessionId', 'studentId', 'sessionDate', 'createdAt'])
    ha, hw = ent_h(*A), ent_h(*Wt)
    p = [k.rel_h(c1 + BW, c2, y + 30, 'sessionId', 'N', '1'),
         k.rel_h(c2 + BW, c3, y + 30, 'sessionId', '1', 'N')]
    py = y + ha + 74                                   # top of the two pills
    # attendance -> student_class_terms
    p.append(k.rel_v(c1 + 86, y + ha, py, 'classTermId', 'N', '1'))
    # attendance -> users
    ym = y + ha + 42
    p.append(k.line([(c1 + 226, y + ha), (c1 + 226, ym), (500, ym), (500, py)]))
    p.append(k.t(372, ym - 8, 'studentId', 'lbl', 'middle'))
    p.append(k.mult(c1 + 238, y + ha + 20, 'N', 'start'))
    p.append(k.mult(512, py - 7, '1', 'start'))
    # waitlist -> users
    p.append(k.line([(c3 + 134, y + hw), (c3 + 134, py + 22), (555, py + 22)]))
    p.append(k.t(708, py + 14, 'studentId', 'lbl', 'middle'))
    p.append(k.mult(c3 + 146, y + hw + 20, 'N', 'start'))
    p.append(k.mult(563, py + 41, '1', 'start'))
    p.append(ent(c1, y, *A))
    p.append(ent(c2, y, *S))
    p.append(ent(c3, y, *Wt))
    p.append(pill(c1 + 134, py, 244, 'student_class_terms'))
    p.append(pill(500, py, 110, 'users'))
    n, nh = k.note(4, py + 62, 992, [
        'ID {sessionId}_{studentId} membuat seorang murid hanya memiliki satu dokumen attendance per sesi.',
        'waitlist: daftar tunggu kelas penuh; kursi yang kosong diberikan kepada antrean pertama.'])
    p.append(n)
    draw('b02_data_pemesanan_kehadiran', p, py + 62 + nh + 12)


# ------------------------------------------------------------------ b03 vouchers and payments
def b03():
    bw = 250
    c1, c2, c3 = 4, 394, 746
    y = 14
    I = (['invoices'], ['ID: otomatis'],
         ['studentId', 'kind · sessions', 'amount · status', 'paymentMethod', 'midtransOrderId'])
    T = (['student_class_terms'], ['ID: otomatis (satu voucher)'],
         ['studentId', 'sessionsUsed', 'sessionsBooked', 'sessionsRemaining', 'deadlineDate · status', 'sourceInvoiceId'])
    V = (['voucher_history'], ['ID: {sessionId}_{studentId}', 'atau {invoiceId}_purchase'],
         ['kind', 'studentId', 'termId', 'sessionId', 'sessions'])
    hi, ht, hv = ent_h(*I), ent_h(*T), ent_h(*V)
    p = [k.rel_h(c1 + bw, c2, y + 30, 'sourceInvoiceId', '1', '0..1'),
         k.rel_h(c2 + bw, c3, y + 30, 'termId', '1', 'N')]
    py = y + max(ht, hv) + 64
    ux = 324                                           # centre of the users pill
    p.append(k.line([(c1 + 125, y + hi), (c1 + 125, py + 22), (ux - 55, py + 22)]))
    p.append(k.t((c1 + 125 + ux - 55) / 2, py + 14, 'studentId', 'lbl', 'middle'))
    p.append(k.mult(c1 + 137, y + hi + 20, 'N', 'start'))
    p.append(k.mult(ux - 62, py + 41, '1', 'end'))
    p.append(k.line([(c2 + 125, y + ht), (c2 + 125, py + 22), (ux + 55, py + 22)]))
    p.append(k.t((c2 + 125 + ux + 55) / 2, py + 14, 'studentId', 'lbl', 'middle'))
    p.append(k.mult(c2 + 137, y + ht + 20, 'N', 'start'))
    p.append(k.mult(ux + 62, py + 41, '1', 'start'))
    p.append(k.rel_v(c3 + 125, y + hv, py, 'sessionId', 'N', '1'))
    p.append(ent(c1, y, *I, bw=bw))
    p.append(ent(c2, y, *T, bw=bw))
    p.append(ent(c3, y, *V, bw=bw))
    p.append(pill(ux, py, 110, 'users'))
    p.append(pill(c3 + 125, py, 184, 'class_sessions'))
    n, nh = k.note(4, py + 62, 992, [
        'voucher_history adalah buku besar voucher: kind purchase (pembelian), session (pemakaian), atau expiry (hangus).',
        'Sisa sesi yang masih dapat dipesan = sessionsRemaining − sessionsBooked (Rumus 5.1).'])
    p.append(n)
    draw('b03_data_voucher_pembayaran', p, py + 62 + nh + 12)


# ------------------------------------------------------------------ b04 exercises
def b04():
    bw = 260
    c1, c2, c3 = 4, 376, 736
    y = 14
    Q = (['question_bank'], ['ID: otomatis (satu butir soal)'],
         ['sheetCode · sheetTitle', 'type · skillCategory', 'category · level', 'question', 'createdBy'])
    X = (['exercises'], ['ID: otomatis (satu paket)'],
         ['title · teacherId', 'bankSheets[]', 'bankQuestionIds[]', 'timeLimitMinutes', 'isPublished'])
    R = (['exercise_results'], ['ID: otomatis'],
         ['studentId · exerciseId', 'category · attemptNo', 'score · status', 'submittedAt'])
    M = (['marking_items'], ['ID: {resultId}_{questionId}'],
         ['source · resultId', 'questionId · studentId', 'answerText', 'maxPoints · mark', 'status'])
    hr = ent_h(*R)
    y2 = y + hr + 62
    p = [k.rel_h(c1 + bw, c2, y + 30, 'bankSheets', 'N', 'N'),
         k.rel_h(c2 + bw, c3, y + 30, 'exerciseId', '1', 'N'),
         k.rel_v(c3 + 130, y + hr, y2, 'resultId', '1', 'N')]
    p += [ent(c1, y, *Q, bw=bw), ent(c2, y, *X, bw=bw), ent(c3, y, *R, bw=bw), ent(c3, y2, *M, bw=bw)]
    n, nh = k.note(4, y + ent_h(*Q) + 32, 660, [
        ('Keterangan', 'sb'),
        'exercises berisi daftar lembar (bankSheets) dan butir soal (bankQuestionIds)',
        'dari question_bank; kunci jawaban tidak pernah dikirim ke aplikasi.',
        'exercise_results hanya ditulis oleh fungsi finishExercise.',
        'marking_items: jawaban yang dinilai guru. source = exercise atau test;',
        'resultId merujuk exercise_results atau test_results.'])
    p.append(n)
    draw('b04_data_latihan', p, y2 + ent_h(*M) + 14)


# ------------------------------------------------------------------ b05 supervised tests
def b05():
    c1, c2, c3 = COLS
    y = 14
    C = (['test_codes'], ['ID: kode tes (code)'],
         ['code · level', 'sheetKey', 'format · releaseYear', 'active · placement'])
    S = (['test_sessions'], ['ID: otomatis'],
         ['codeId', 'token · joinUntil', 'openedBy', 'partClocks · placement', 'status'])
    A = (['test_attempts'], ['ID: {codeId}_{studentId}', 'duduk ulang ke-n: akhiran _s{n}'],
         ['codeId · studentId', 'sessionId · sittingNo', 'partIndex · answers', 'status · finishedAt', 'latestSitting'])
    R = (['test_results'], ['ID: sama dengan test_attempts'],
         ['codeId · studentId', 'parts · total', 'passed · valid', 'sittingNo · counts', 'status · finishedAt'])
    ha = ent_h(*A)
    y2 = y + ha + 62
    p = [k.rel_h(c1 + BW, c2, y + 30, 'codeId', '1', 'N'),
         k.rel_h(c2 + BW, c3, y + 30, 'sessionId', '1', 'N'),
         k.rel_v(c3 + 134, y + ha, y2, 'ID sama', '1', '1')]
    p += [ent(c1, y, *C), ent(c2, y, *S), ent(c3, y, *A), ent(c3, y2, *R)]
    n, nh = k.note(4, y + ent_h(*S) + 60, 660, [
        ('Keterangan', 'sb'),
        'sheetKey pada test_codes menunjuk lembar soal di question_bank.',
        'Token sesi berlaku 15 menit (joinUntil); murid masuk dengan fungsi startTest.',
        'Duduk pertama memakai ID {codeId}_{studentId}; duduk ulang hanya dapat',
        'dimulai pada sesi baru dan disimpan dengan akhiran _s{n}.',
        'counts bernilai true hanya pada duduk pertama yang sah.'])
    p.append(n)
    draw('b05_data_tes', p, y2 + ent_h(*R) + 14)


# ------------------------------------------------------------------ b06 leaderboard, promotion, progress summary
def b06():
    c1, c2, c3 = COLS
    L = (['leaderboards/{codeId}', '/entries'], ['ID: {studentId}'],
         ['name', 'parts · total', 'seconds · rankKey', 'finishedAt'])
    P = (['level_promotions'], ['ID: {studentId}_{levelKey}'],
         ['studentId', 'fromLevel · toLevel', 'codes · count', 'minCodes · status'])
    G = (['progress_summary'], ['ID: {studentId}'],
         ['level', 'practice · tests', 'attendance · voucher', 'warnings · status'])
    ye = 150                                           # top of the three derived collections
    bus = 104
    p = []
    # test_results -> the three collections
    p.append(k.line([(300, 58), (300, bus)], dash=True))
    p.append(k.line([(c1 + 134, bus), (c3 + 60, bus)], dash=True))
    for x in (c1 + 134, c2 + 134, c3 + 60):
        p.append(k.line([(x, bus), (x, ye)], dash=True, arrow=True))
    p.append(k.t(314, 90, 'trigger onTestResultWritten', 'lbl'))
    # the other sources -> progress_summary
    p.append(k.line([(c3 + 200, 70), (c3 + 200, ye)], dash=True, arrow=True))
    p.append(k.t(c3 + 190, 128, 'trigger', 'lbl', 'end'))
    p.append(pill(300, 14, 170, 'test_results'))
    p.append(k.box(640, 8, 356, 62, [('exercise_results, attendance,', 'm'), ('student_class_terms', 'm')], k.GREY, rx=22))
    p += [ent(c1, ye, *L), ent(c2, ye, *P), ent(c3, ye, *G)]
    ny = ye + ent_h(*L) + 16
    n, nh = k.note(4, ny, 992, [
        'Ketiga koleksi turunan ini hanya ditulis Cloud Functions (garis putus); aplikasi hanya membacanya.',
        'level_promotions menunggu keputusan admin (decidePromotion); progress_summary juga diperbarui setiap pukul 07.00.'])
    p.append(n)
    draw('b06_data_kenaikan_laporan', p, ny + nh + 12)


# ------------------------------------------------------------------ sequence pieces
def lifelines(p, heads, h):
    for x, _, _, _ in heads:
        p.append('<line x1="%d" y1="50" x2="%d" y2="%d" stroke="%s" stroke-width="1.6" stroke-dasharray="6 6"/>' % (x, x, h - 8, k.INK))


def head_boxes(p, heads):
    for x, name, fill, w in heads:
        p.append(k.box(x - w // 2, 8, w, 42, [(name, 'b')], fill))


def msg(p, x1, x2, y, s, dash=False, at=None, sub=None):
    p.append(k.line([(x1, y), (x2, y)], dash=dash, arrow=True))
    cx = at if at is not None else (x1 + x2) / 2
    p.append(k.t(cx, y - 9, s, 'lbl', 'middle'))
    if sub:
        p.append(st(cx, y + 21, sub, SUB_STYLE, 'middle'))


def frame(p, x, y, w, h, title, tabw):
    p.append(k.rect(x, y, w, h, k.SOFT, rx=6, dash=True, sw=1.6))
    p.append('<path d="M%d,%d h%d v20 l-10,10 h-%d z" fill="%s" stroke="%s" stroke-width="1.6"/>' % (x, y, tabw, tabw - 10, k.GREY, k.INK))
    p.append(k.t(x + 10, y + 21, title, 'sb'))


def step(p, cx, y, w, lines):
    """What the function decides between two messages."""
    h = 12 + 21 * len(lines)
    p.append(k.rect(cx - w // 2, y, w, h, k.YELLOW, rx=6, sw=1.6))
    p.append(k.text(cx, y + h / 2, lines, 's'))
    return h


# ------------------------------------------------------------------ b07 closing a class session
def b07():
    G, A, F, D = 58, 215, 515, 878
    H = 530
    heads = ((G, 'Guru', k.YELLOW, 100), (A, 'Aplikasi Flutter', k.YELLOW, 176),
             (F, 'Fungsi closeSession', k.BLUE, 216), (D, 'Cloud Firestore', k.SOFT, 176))
    p = []
    frame(p, 255, 150, 735, 268, 'Satu transaksi Firestore', 226)
    lifelines(p, heads, H)
    head_boxes(p, heads)
    msg(p, G, A, 92, '1. Tutup sesi')
    msg(p, A, F, 130, '2. closeSession(sessionId, statuses)')
    msg(p, F, D, 214, '3. Baca sesi, absensi, dan voucher')
    step(p, F, 228, 420, ['4. Sesi sudah done? Berhenti tanpa perubahan'])
    msg(p, F, D, 300, '5. Tulis buku besar voucher_history', sub='ID {sessionId}_{studentId}')
    msg(p, F, D, 362, '6. Ubah attendance dan sisa sesi voucher')
    msg(p, F, D, 400, '7. Sesi menjadi done; rekap guru')
    msg(p, F, A, 454, '8. {status: done, credited}', dash=True)
    msg(p, A, G, 492, '9. Sesi selesai', dash=True)
    n, _ = k.note(560, 430, 430, ['Pemanggilan kedua berhenti di langkah 4 dan',
                                 'mengembalikan {status: done, already: true,',
                                 'credited: 0}: voucher tidak terpotong lagi.'])
    p.append(n)
    draw('b07_sequence_tutup_sesi', p, H)


# ------------------------------------------------------------------ b08 a supervised test with a token
def b08():
    G, M, F, D = 60, 215, 500, 872
    H = 544
    heads = ((G, 'Guru', k.YELLOW, 100), (M, 'Murid', k.YELLOW, 110),
             (F, 'Cloud Functions', k.BLUE, 190), (D, 'Cloud Firestore', k.SOFT, 176))
    mid = (M + F) / 2
    rows = [90 + 36 * i for i in range(11)]
    p = []
    lifelines(p, heads, H)
    head_boxes(p, heads)
    msg(p, G, F, rows[0], '1. openTestSession(codeId)', at=mid)
    msg(p, F, D, rows[1], '2. Buat test_sessions: token, joinUntil')
    msg(p, F, G, rows[2], '3. Token', dash=True, at=mid)
    msg(p, G, M, rows[3], '4. Sebut token')
    msg(p, M, F, rows[4], '5. startTest(token)')
    msg(p, F, D, rows[5], '6. Buat test_attempts, buka bagian 1')
    msg(p, F, M, rows[6], '7. Soal tanpa kunci, sisa waktu', dash=True)
    msg(p, M, F, rows[7], '8. submitTestPart (tiap bagian)')
    msg(p, F, D, rows[8], '9. Akhir: hitung nilai, tulis test_results')
    msg(p, F, M, rows[9], '10. Kartu hasil', dash=True)
    msg(p, D, F, rows[10], '11. Trigger onTestResultWritten', dash=True)
    n, _ = k.note(440, rows[10] + 14, 552, ['Duduk pertama yang sah (counts = true) memperbarui leaderboard,',
                                            'hitungan kenaikan tingkat, dan progress_summary.'])
    p.append(n)
    draw('b08_sequence_tes_token', p, H)


# ------------------------------------------------------------------ b09 booking a session
def b09():
    U, A, F, D = 62, 215, 515, 878
    H = 508
    heads = ((U, 'Murid', k.YELLOW, 110), (A, 'Aplikasi Flutter', k.YELLOW, 176),
             (F, 'Fungsi bookSession', k.BLUE, 210), (D, 'Cloud Firestore', k.SOFT, 176))
    p = []
    frame(p, 255, 150, 735, 250, 'Satu transaksi Firestore', 226)
    lifelines(p, heads, H)
    head_boxes(p, heads)
    msg(p, U, A, 92, '1. Pesan kelas')
    msg(p, A, F, 130, '2. bookSession(sessionId)')
    msg(p, F, D, 214, '3. Baca sesi, voucher, pesanan lain')
    step(p, F, 228, 440, ['4. bookingRefusal: kelas penuh, sisa sesi habis,',
                         'voucher kedaluwarsa, jam bentrok, kelas berakhir'])
    msg(p, F, D, 320, '5. Buat dokumen attendance (booked)', sub='ID {sessionId}_{studentId}')
    msg(p, F, D, 382, '6. bookedCount +1, sessionsBooked +1')
    msg(p, F, A, 436, '7. {booked: true, termId}', dash=True)
    msg(p, A, U, 474, '8. Kelas terpesan', dash=True)
    n, _ = k.note(560, 412, 430, ['Bila ditolak, fungsi mengembalikan alasannya',
                                 'dan tidak ada data yang berubah. Kelas penuh:',
                                 'murid dapat masuk daftar tunggu (joinWaitlist).'])
    p.append(n)
    draw('b09_sequence_pesan_sesi', p, H)


# ------------------------------------------------------------------ status pieces
def state(x, y, w, name, h=56, fill=k.BLUE):
    return k.rect(x, y, w, h, fill, rx=18) + k.t(x + w / 2, y + h / 2 + 6, name, 'mb', 'middle')


# ------------------------------------------------------------------ b10 the life of a class session
def b10():
    p = []
    # transitions first, states on top
    p.append(k.arrow([(49, 198), (230, 198)]))
    p.append(k.t(139, 189, 'generateSessions', 'lbl', 'middle'))
    p.append(k.t(139, 220, '(14 hari ke depan)', 'lbl', 'middle'))
    p.append(k.arrow([(40, 189), (40, 52), (230, 52)]))
    p.append(k.t(135, 43, 'guru libur hari itu', 'lbl', 'middle'))
    p.append(k.arrow([(315, 80), (315, 170)]))
    p.append(k.t(327, 131, 'assignSubstitute', 'lbl'))
    p.append(k.arrow([(400, 198), (520, 198)]))
    p.append(k.t(460, 189, 'jam mulai tiba', 'lbl', 'middle'))
    p.append(k.arrow([(690, 198), (830, 198)]))
    p.append(k.t(760, 189, 'closeSession', 'lbl', 'middle'))
    p.append(k.arrow([(900, 226), (900, 276)]))
    # scheduled -> cancelled
    p.append(k.arrow([(285, 226), (285, 338), (520, 338)]))
    for i, s in enumerate(('cancelSession,', 'setDayClosed (hari ditutup),', 'murid terlalu sedikit,', 'jadwal dihapus')):
        p.append(k.t(273, 262 + 22 * i, s, 'lbl', 'end'))
    # cancelled -> scheduled
    p.append(k.arrow([(560, 310), (560, 264), (360, 264), (360, 226)]))
    p.append(k.t(460, 256, 'hari dibuka lagi', 'lbl', 'middle'))
    # ongoing -> cancelled
    p.append(k.arrow([(640, 226), (640, 310)]))
    p.append(k.t(652, 274, 'cancelSession', 'lbl'))
    p.append(k.dot(40, 198))
    p.append(state(230, 24, 170, 'needs_teacher', fill=k.YELLOW))
    p.append(state(230, 170, 170, 'scheduled'))
    p.append(state(520, 170, 170, 'ongoing'))
    p.append(state(830, 170, 140, 'done'))
    p.append(state(520, 310, 170, 'cancelled', fill=k.GREY))
    p.append(k.dot(900, 290, end=True))
    n, nh = k.note(716, 322, 278, [('Keterangan', 'sb'), 'Status sesi hanya ditulis', 'Cloud Functions. Sesi tanpa',
                                   'guru (needs_teacher) juga', 'dapat dibatalkan.'])
    p.append(n)
    draw('b10_status_sesi_kelas', p, 322 + nh + 14)


# ------------------------------------------------------------------ b11 the life of an invoice and of a voucher
def b11():
    p = []
    p.append(k.t(16, 30, 'Tagihan: field status pada invoices', 'b'))
    p.append(k.arrow([(49, 90), (180, 90)]))
    p.append(k.t(114, 81, 'createInvoice', 'lbl', 'middle'))
    p.append(k.arrow([(340, 90), (640, 90)]))
    p.append(k.t(490, 81, 'pembayaran Midtrans berhasil', 'lbl', 'middle'))
    p.append(k.t(490, 112, 'atau markInvoicePaid (admin)', 'lbl', 'middle'))
    p.append(k.arrow([(310, 118), (310, 178), (640, 178)]))
    p.append(k.t(475, 169, 'batas waktu pembayaran habis', 'lbl', 'middle'))
    p.append(k.arrow([(270, 118), (270, 250), (640, 250)]))
    p.append(k.t(455, 241, 'pembayaran ditolak atau dibatalkan', 'lbl', 'middle'))
    p.append(k.line([(210, 118), (210, 222), (190, 222)], both=True))
    p.append(k.t(198, 150, 'discardInvoice', 'lbl', 'end'))
    p.append(k.t(198, 172, '(dapat dipulihkan)', 'lbl', 'end'))
    p.append(k.dot(40, 90))
    p.append(state(180, 62, 160, 'pending'))
    p.append(state(640, 62, 160, 'paid'))
    p.append(state(640, 150, 160, 'expired', fill=k.GREY))
    p.append(state(640, 222, 160, 'failed', fill=k.GREY))
    p.append(state(30, 194, 160, 'discarded', fill=k.GREY))
    p.append('<line x1="16" y1="304" x2="984" y2="304" stroke="%s" stroke-width="1.4" stroke-dasharray="6 6"/>' % k.INK)
    p.append(k.t(16, 338, 'Voucher: field status pada student_class_terms', 'b'))
    p.append(k.arrow([(49, 398), (250, 398)]))
    p.append(k.t(149, 389, 'tagihan menjadi paid', 'lbl', 'middle'))
    p.append(k.arrow([(410, 398), (640, 398)]))
    p.append(k.t(525, 389, 'closeSession: sisa sesi 0', 'lbl', 'middle'))
    p.append(k.arrow([(330, 426), (330, 484), (640, 484)]))
    p.append(k.t(485, 475, 'expireVouchers: lewat deadlineDate', 'lbl', 'middle'))
    p.append(k.dot(40, 398))
    p.append(state(250, 370, 160, 'active'))
    p.append(state(640, 370, 160, 'depleted', fill=k.GREY))
    p.append(state(640, 456, 160, 'expired', fill=k.GREY))
    n, _ = k.note(826, 360, 168, ['Selama active:', 'bookSession,', 'cancelBooking,', 'closeSession', 'mengubah angka', 'sesi.'])
    p.append(n)
    draw('b11_status_tagihan_voucher', p, 526)


if __name__ == '__main__':
    k.setup(WORK)
    for f in (b01, b02, b03, b04, b05, b06, b07, b08, b09, b10, b11):
        f()
    k.shoot(OUT)
