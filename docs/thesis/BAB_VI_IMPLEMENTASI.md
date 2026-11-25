# BAB VI
# IMPLEMENTASI

Bab ini menguraikan hasil implementasi rancangan pada Bab V. Bagian pertama
memperlihatkan halaman utama aplikasi untuk setiap peran, dan bagian kedua
memuat segmen program dari bagian yang menentukan kebenaran sistem: aturan
akses, penjadwalan, voucher, penilaian, kenaikan tingkat, pembayaran, dan
laporan progress.

## 6.1 Implementasi Desain

Aplikasi dibangun dengan Flutter dan Firebase sesuai arsitektur pada Gambar
5.1, dipasang di Firebase Hosting pada alamat
https://chinese-tracker.web.app, dan dibagikan pula sebagai berkas APK
Android. Lingkungan implementasi dirangkum pada Tabel 6.1. Tangkapan layar
diambil dari Firebase Emulator Suite dengan data uji coba, dalam bahasa
Indonesia.

Tabel 6.1
Lingkungan Implementasi

| Komponen | Teknologi dan versi |
|---|---|
| Aplikasi | Dart dan Flutter 3.44, satu basis kode untuk web, Android, dan iOS; go_router 14, provider 6, fl_chart |
| Backend | Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging, App Check, Hosting |
| Logika server | Cloud Functions generasi kedua pada Node.js 22, 74 fungsi; opencc-js untuk konversi aksara tradisional |
| Pembayaran | Midtrans Snap (sandbox) dengan notifikasi HTTP ke Cloud Functions |
| Pengujian | flutter test (186 pengujian), pengujian logika Node.js per modul, pengujian Security Rules pada emulator, GitHub Actions |

Bagian ini hanya memuat halaman yang paling menentukan. Halaman lainnya
diperlihatkan pada video demonstrasi
⟦ISI: tautan atau kode QR video demonstrasi⟧, dan tangkapan layar
selengkapnya dimuat pada ⟦Lampiran⟧.

### 6.1.1 Halaman Umum

Halaman umum dapat dibuka tanpa masuk. Halaman masuk pada Gambar 6.1
menerima email dan kata sandi, mengingat akun yang pernah masuk, dan
menyediakan sakelar bahasa Indonesia dan Inggris.

[GAMBAR 6.1: halaman masuk]

Gambar 6.1
Halaman Masuk

Halaman umum lainnya adalah halaman depan, pendaftaran murid yang menunggu
persetujuan admin, dan tes penempatan tanpa akun dengan token dari guru.

### 6.1.2 Halaman Admin

Dasbor admin pada Gambar 6.2 dibuka dengan kartu Hari ini yang memuat hal
yang perlu ditindaklanjuti, empat angka ringkas, grafik murid baru per
bulan, dan murid yang perlu perhatian.

[GAMBAR 6.2: dashboard admin]

Gambar 6.2
Dasbor Admin

Halaman persetujuan pada Gambar 6.3 memuat murid yang mendaftar sendiri.
Admin menetapkan tingkat dan guru, lalu menyetujui atau menolak dengan
alasan (decideRegistration).

[GAMBAR 6.3: persetujuan pendaftaran]

Gambar 6.3
Persetujuan Pendaftaran

Jadwal mingguan pada Gambar 6.4 menampilkan kelas per ruang dan per hari.
Jadwal disimpan fungsi saveSchedule yang menolak bentrok guru dan ruang
(Segmen Program 6.2).

[GAMBAR 6.4: jadwal mingguan]

Gambar 6.4
Jadwal Mingguan

Halaman pembayaran pada Gambar 6.5 memuat tagihan beserta statusnya. Admin
mencatat pembayaran tunai dan transfer, sedangkan pembayaran Midtrans
tercatat sendiri melalui notifikasi.

[GAMBAR 6.5: daftar tagihan dan pembayaran]

Gambar 6.5
Daftar Tagihan dan Pembayaran

Verifikasi kenaikan tingkat pada Gambar 6.6 memuat syarat jumlah kode dan
rekomendasi yang ditulis fungsi ketika murid memenuhi syarat. Admin
menyetujui atau menolak dengan alasan.

[GAMBAR 6.6: verifikasi kenaikan tingkat]

Gambar 6.6
Verifikasi Kenaikan Tingkat

Laporan pada Gambar 6.7 menampilkan rekap bulanan dari fungsi
monthlyReport: murid baru, pendapatan, murid aktif, kehadiran, dan jam
mengajar, dengan ekspor CSV dan PDF.

[GAMBAR 6.7: laporan bulanan]

Gambar 6.7
Laporan Bulanan

Halaman admin lainnya (pengguna, bank soal, kode tes, kalender sesi,
voucher, daftar harga, dan berita) mengikuti pola yang sama.

### 6.1.3 Halaman Guru

Halaman sesi pada Gambar 6.8 adalah tempat guru menjalankan kelas: daftar
pemesan, status hadir, izin, atau alpa, dan tombol tutup sesi yang
memanggil closeSession (Segmen Program 6.3).

[GAMBAR 6.8: halaman sesi dan absensi]

Gambar 6.8
Halaman Sesi dan Absensi

Pengawasan sesi tes pada Gambar 6.9 menampilkan token untuk murid, murid
yang sudah bergabung beserta bagian yang dikerjakan, dan tombol memutar
rekaman serta menutup sesi.

[GAMBAR 6.9: pengawasan sesi tes]

Gambar 6.9
Pengawasan Sesi Tes

Antrean penilaian pada Gambar 6.10 memuat jawaban ketik yang meleset satu
aksara atau nada dan tulisan bebas. Guru memberi poin dengan rubrik melalui
fungsi markAnswer.

[GAMBAR 6.10: antrean penilaian]

Gambar 6.10
Antrean Penilaian

Guru juga memiliki dasbor, jadwal mengajar, paket latihan sendiri, dan
laporan progress murid bimbingannya.

### 6.1.4 Halaman Murid

Beranda murid pada Gambar 6.11 menampilkan sisa sesi, pengumuman, dan sesi
kelas empat belas hari ke depan dengan tombol Daftar. Pemesanan dijalankan
fungsi bookSession (Algoritma 5.2).

[GAMBAR 6.11: beranda murid dan pemesanan sesi]

Gambar 6.11
Beranda Murid dan Pemesanan Sesi

Pemutar latihan pada Gambar 6.12 menampilkan soal satu per satu, termasuk
soal ketik hanzi dan pinyin. Jawaban dikumpulkan satu kali dan dinilai di
server (Segmen Program 6.5).

[GAMBAR 6.12: pemutar latihan (soal ketik)]

Gambar 6.12
Pemutar Latihan dengan Soal Ketik

Halaman tes pada Gambar 6.13 meminta token dari guru pengawas. Murid
mengerjakan naskah per bagian dengan jam dari server dan menerima kartu
nilai bergaya HSK.

[GAMBAR 6.13: tes memasukkan token]

Gambar 6.13
Halaman Tes dan Masukan Token

Leaderboard pada Gambar 6.14 memuat peringkat pada satu kode tes menurut
nilai total lalu waktu pengerjaan. Murid melihat temannya dengan nama
Tionghoa saja.

[GAMBAR 6.14: leaderboard kode tes]

Gambar 6.14
Leaderboard Kode Tes

Halaman pembayaran murid pada Gambar 6.15 memuat voucher aktif, tagihan,
dan tombol Beli. Sesi dikreditkan begitu notifikasi lunas Midtrans diterima
server (Segmen Program 6.7).

[GAMBAR 6.15: voucher dan pembayaran murid]

Gambar 6.15
Voucher dan Pembayaran Murid

Laporan progress pada Gambar 6.16 sama dengan yang dilihat guru dan orang
tua: tingkat, grafik nilai latihan per minggu, riwayat tes, kehadiran,
voucher, dan peringatan (Segmen Program 6.8).

[GAMBAR 6.16: laporan progress murid]

Gambar 6.16
Laporan Progress Murid

Halaman murid lainnya memuat riwayat kelas dan voucher, kelas yang dipesan,
dan daftar latihan yang ditugaskan.

## 6.2 Implementasi Program

Kode aplikasi disusun seperti pada Tabel 6.2. Logika yang menentukan uang,
nilai, dan tingkat berada di Cloud Functions, dan modul logika murni diuji
dengan node tanpa emulator. Segmen program dikutip dari kode produksi per
24 November 2026; baris yang diringkas ditandai `// ...`.

Tabel 6.2
Susunan Kode Sumber

| Folder atau berkas | Isi |
|---|---|
| lib/main.dart, lib/core/router/ | Inisialisasi Firebase dan pengalihan halaman menurut peran dan status akun |
| lib/features/, lib/services/, lib/models/ | Halaman per fitur, lapisan layanan Firebase, dan model data |
| lib/l10n/ | Terjemahan Indonesia dan Inggris (sekitar 1.380 kunci) |
| functions/ | index.js (74 Cloud Functions) dan modul logika murni beserta pengujiannya |
| firestore.rules, storage.rules | Aturan akses beserta pengujiannya di rules-tests/ |

Di sisi aplikasi, fungsi redirect pada go_router mengunci setiap peran pada
bagiannya sendiri, dan pemutar latihan mengirim jawaban satu kali ke
finishExercise tanpa pernah memegang kunci jawaban.

### 6.2.1 Aturan Akses Firestore

Penjaga yang sebenarnya adalah Firestore Security Rules, karena aplikasi
dapat dilewati oleh siapa pun yang memanggil Firestore langsung. Segmen
Program 6.1 memuat tiga koleksi yang mewakili pola aturannya.

Segmen Program 6.1
Aturan Akses exercise_results, schedules, dan voucher_history
01: match /schedules/{scheduleId} {
02:   allow read: if isApprovedUser();
03:   allow write: if false;
04: }
05: match /exercise_results/{resultId} {
06:   allow read: if isApprovedUser() && (
07:     resource == null ||
08:     resource.data.studentId == request.auth.uid ||
09:     isStaff() ||
10:     isParentOf(resource.data.get('studentId', ''))
11:   );
12: }
13: match /voucher_history/{entryId} {
14:   allow read: if isApprovedUser() && (
15:     isStaff() ||
16:     resource.data.get('studentId', '') == request.auth.uid ||
17:     isParentOf(resource.data.get('studentId', ''))
18:   );
19:   allow write: if false;
20: }

Koleksi schedules dan voucher_history tidak dapat ditulis dari aplikasi,
sehingga hanya fungsi saveSchedule dan closeSession yang menulisnya. Koleksi
exercise_results tidak memiliki aturan tulis, sehingga nilai hanya ditulis
fungsi finishExercise. Aturan ini diuji dengan 86 pengujian pada emulator.

### 6.2.2 Penjadwalan dan Penutupan Sesi

Pengecekan bentrok dari Algoritma 5.1 adalah dua fungsi murni pada
scheduling.js (Segmen Program 6.2): overlaps membandingkan dua rentang
waktu, dan conflicts mengumpulkan setiap alasan bentrok.

Segmen Program 6.2
Fungsi overlaps dan conflicts
01: function overlaps(a, b, gapMinutes = 0) {
02:   const g = Number(gapMinutes) || 0;
03:   return a.startMinutes < b.endMinutes + g && b.startMinutes < a.endMinutes + g;
04: }
05: function conflicts(s, ctx) {
06:   const out = [];
07:   const gap = ctx.gapMinutes === undefined ? DEFAULTS.minGapMinutes : ctx.gapMinutes;
08:   const day = WEEKDAY_NAMES[s.weekday] || "";
09:   const who = ctx.teacherName || "The teacher";
10:   // ... (ketersediaan guru diperiksa bila sakelar kesiapan guru dinyalakan)
11:   const live = (x) => x.active !== false && x.id !== s.id;
12:   for (const o of (ctx.teacherSchedules || []).filter(live)) {
13:     if (o.weekday === s.weekday && periodsOverlap(o, s) && overlaps(o, s, gap)) {
14:       out.push({code: "teacher", text: `${who} already teaches ${o.className} on ${day} ` +
15:         `${clock(o.startMinutes)}–${clock(o.endMinutes)}${gapNote(o)}.`});
16:     }
17:   }
18:   // ... (ruang, lalu sesi lepas guru dan ruang, diperiksa dengan cara yang sama)
19:   return out;
20: }

Fungsi saveSchedule memanggil conflicts di dalam transaksi yang membaca
dokumen kunci per guru dan per ruang (schedule_locks), sehingga dua admin
tidak dapat menyimpan jadwal yang bentrok pada saat yang sama.

Pemotongan voucher yang konsisten, syarat dari pembimbing kedua, berada di
dalam fungsi closeSession. Segmen Program 6.3 memuat inti transaksinya.

Segmen Program 6.3
Transaksi closeSession dan Kunci Idempoten voucher_history
01: return db.runTransaction(async (tx) => {
02:   const cur = await tx.get(ref);
03:   const s = cur.data() || {};
04:   const status = tday.effectiveStatus(s, Date.now());
05:   const decision = tday.closeDecision(status, byAdmin || s.generated !== true);
06:   if (decision === "already-done") {
07:     return {status: "done", already: true, credited: 0, excused: 0, failed: []};
08:   }
09:   // ... (daftar hadir dan voucher yang terkait dibaca di dalam transaksi)
10:   for (const {ref: aRef, a, termId} of atts) {
11:     // ... (st = status kehadiran murid: hadir, izin, atau alpa)
12:     const raw = tday.closeEffect(st);
13:     const eff = {...raw, booked: a.booked === true ? raw.booked : 0};
14:     // ... (usable: voucher ada dan sisanya cukup; charged = usable && eff.used > 0)
15:     tx.set(db.collection(VOUCHER_HISTORY).doc(`${ref.id}_${a.studentId}`), {
16:       kind: "session", studentId: a.studentId, termId: usable ? termId : "",
17:       sessionId: ref.id, sessionDate: s.sessionDate || "", status: st,
18:       sessions: charged ? eff.delta : 0, date: FieldValue.serverTimestamp(),
19:     });
20:     tx.update(aRef, {attendanceStatus: st, sessionCredited: charged, closed: true});
21:   }
22:   // ... (tx.update setiap voucher; tx.set rekap guru bulan itu)
23:   tx.update(ref, {status: "done", isConcluded: true, isOpen: false,
24:     concludedAt: FieldValue.serverTimestamp()});
25:   return {status: "done", credited, excused, failed};
26: });

Seluruh pembacaan dan penulisan berada dalam satu transaksi. Buku besar
memakai id sessionId_studentId dan sesi yang sudah berstatus done langsung
dikembalikan, sehingga pemanggilan kedua tidak memotong voucher dua kali.

### 6.2.3 Penilaian Latihan dan Tes

Pencocokan jawaban ketik dari Algoritma 5.4 berada pada typing_matcher.js
(Segmen Program 6.4). Jawaban dan kunci dinormalkan dengan cara yang sama,
lalu jarak Levenshtein menentukan nilainya.

Segmen Program 6.4
Normalisasi dan Pencocokan Hanzi
01: function normalizeHanzi(text) {
02:   let s = toHalfWidth(text);
03:   s = Array.from(s).map((ch) => CJK_PUNCT[ch] || ch).join("");
04:   s = s.replace(/\s+/g, "");
05:   s = s.replace(ENDING, "");
06:   return toSimplified(s);
07: }
08: function matchHanzi(answer, keys) {
09:   const typed = Array.from(normalizeHanzi(answer));
10:   if (!typed.length) return ZERO;
11:   let best = ZERO;
12:   for (const key of keyList(keys)) {
13:     const want = Array.from(normalizeHanzi(key));
14:     const d = levenshtein(typed, want);
15:     if (d === 0) return FULL;
16:     if (d === 1 && similarity(typed, want, d) >= 0.75) {
17:       best = {credit: 0.5, review: true, reason: "one_character"};
18:     }
19:   }
20:   return best;
21: }

Jarak nol berarti nilai penuh; jarak satu dengan kemiripan paling sedikit
0,75 (Rumus 2.1) berarti setengah nilai dan ditandai untuk guru. Soal dengan
beberapa rumpang dinilai per rumpang.

Penilaian satu paket dilakukan fungsi finishExercise (Segmen Program 6.5),
yang dipanggil satu kali setelah murid menjawab semua soal.

Segmen Program 6.5
Fungsi finishExercise
01: exports.finishExercise = onCall(async (request) => {
02:   const {uid, profile} = await requireCaller(request);
03:   // ... (exerciseId dan answers dibaca dari request.data)
04:   const exercise = await loadAssignedPackage(exerciseId, uid);
05:   const items = await loadPackageItems(exercise);
06:   let late = false;
07:   // ... (paket ujian satu kali: exercise_attempts ditutup dalam transaksi; late dari jam server)
08:   const scored = play.scoreAttempt(items, answers);
09:   // ... (jawaban yang terlambat dinilai 0; ulasan tetap dikembalikan)
10:   const status = result.open > 0 ? "pending_marking" : "final";
11:   // ... (hasil ditulis ke exercise_results; jawaban terbuka ke marking_items)
12:   return {...result, late, status, resultId: resultRef.id};
13: });

Hasil dengan jawaban terbuka berstatus pending_marking sampai guru
menilainya melalui markAnswer, dan kunci baru dikirim bersama ulasan setelah
jawaban diterima. Tes simulasi HSK memakai jalur submitTestPart dengan
nilai per bagian (Rumus 5.2).

### 6.2.4 Kenaikan Tingkat

Hitungan menuju kenaikan tingkat (Algoritma 5.6) berada pada promotion.js
(Segmen Program 6.6): countsAt menyaring hasil yang dihitung, dan
promotionState menghitung kode berbeda yang sudah dilulusi.

Segmen Program 6.6
Fungsi countsAt dan promotionState
01: function countsAt(result, code, levelKey) {
02:   const c = code || {};
03:   if (!result || !isFinal(result) || !isValid(result) || result.passed !== true) return false;
04:   if (isPlacement(result, c)) return false;
05:   if (c.countsForPromotion === false) return false;
06:   // ... (hanya kode keluarga HSK yang dihitung)
07:   const key = levelKeyOf(result.levelKey || c.levelKey || result.level || c.level);
08:   return key !== "" && key === String(levelKey);
09: }
10: function promotionState(rows, levelKey, minCodes = DEFAULT_MIN_CODES) {
11:   const min = Number(minCodes) >= 1 ? Math.floor(Number(minCodes)) : DEFAULT_MIN_CODES;
12:   const codes = [];
13:   for (const {result, code} of rows || []) {
14:     if (!countsAt(result, code, levelKey)) continue;
15:     const id = String(result.codeId || "");
16:     if (id && !codes.includes(id)) codes.push(id);
17:   }
18:   codes.sort();
19:   const next = nextLevelKey(levelKey);
20:   return {levelKey: String(levelKey || ""), next, codes, count: codes.length,
21:     minCodes: min, reached: next !== null && levelKey !== "" && codes.length >= min};
22: }

Kedua fungsi dipanggil trigger onTestResultWritten, yang juga memperbarui
leaderboard. Bila reached bernilai benar, trigger membuat dokumen
level_promotions untuk admin; keputusan admin (decidePromotion) menaikkan
users.level dan menulis level_history.

### 6.2.5 Pembayaran Midtrans

Fungsi createInvoice mengambil harga dari daftar harga di server, lalu
meminta token Snap dengan server key dari Secret Manager. Notifikasi
pembayaran dari Midtrans diperiksa tanda tangannya (SHA-512 dari order_id,
status_code, gross_amount, dan server key); yang salah ditolak dengan kode
403 (MT-02). Notifikasi yang sah memasuki transaksi pada Segmen Program 6.7.

Segmen Program 6.7
Transaksi Pengkreditan Voucher dan creditDecision
01: function creditDecision(invoice, newStatus, grossAmount) {
02:   const status = (invoice || {}).status || "pending";
03:   if (status === "discarded" && newStatus !== "paid") return "ignore-final";
04:   if (status !== "pending" && status !== "discarded") return "ignore-final";
05:   if (!newStatus) return "no-change";
06:   if (newStatus !== "paid") return "flip";
07:   if (Math.round(Number(grossAmount)) !== Math.round(Number((invoice || {}).amount))) {
08:     return "amount-mismatch";
09:   }
10:   return "credit";
11: }
12: // di dalam midtransNotification (functions/index.js):
13: await db.runTransaction(async (tx) => {
14:   const snap = await tx.get(invoiceRef);
15:   const invoice = snap.data() || {};
16:   const decision = payments.creditDecision(invoice, newStatus, grossAmount);
17:   if (decision === "ignore-final" || decision === "no-change") return;
18:   // ... (amount-mismatch: tidak dikreditkan, dicatat untuk admin)
19:   const termSnap = newStatus === "paid" ? await linkedTermSnap(tx, invoice) : null;
20:   tx.update(invoiceRef, {status: newStatus,
21:     ...(newStatus === "paid" ? {paidAt: FieldValue.serverTimestamp()} : {})});
22:   if (newStatus !== "paid") return;
23:   credited = creditPaidInvoice(tx, invoiceRef, withPriceItem(invoice, pricing), termValidDays, termSnap);
24: });

Status tagihan dan periode voucher ditulis dalam satu transaksi, sehingga
tidak ada tagihan lunas tanpa voucher. Notifikasi yang terkirim dua kali
(MT-03) berhenti pada ignore-final.

### 6.2.6 Laporan Progress

Lima peringatan laporan progress dari Algoritma 5.8 berada pada fungsi
warningsOf di progress.js (Segmen Program 6.8), yang mempertahankan tanggal
mulai peringatan sebelumnya.

Segmen Program 6.8
Fungsi warningsOf
01: function warningsOf(summary, nowMs, previous = []) {
02:   const prevSince = new Map((previous || []).map((w) => [Number(w.id), Number(w.since)]));
03:   const out = [];
04:   const add = (id, detail) => out.push({id, detail,
05:     since: Number.isFinite(prevSince.get(id)) ? prevSince.get(id) : nowMs});
06:   const a = summary.attendance || {};
07:   if (a.records30 >= 4 && a.percent !== null && a.percent < 75) {
08:     add(1, `Attendance ${a.percent}% in 30 days (${a.hadir} present, ${a.alpa} absent)`);
09:   }
10:   const p = summary.practice || {};
11:   if (p.attempts14 >= 2 && p.average14 !== null) {
12:     if (p.average14 < 60) {
13:       add(2, `Practice average ${p.average14} in the last 14 days`);
14:     } else if (p.attemptsPrev14 >= 2 && p.averagePrev14 !== null &&
15:         p.averagePrev14 - p.average14 >= 10) {
16:       add(2, `Practice average fell from ${p.averagePrev14} to ${p.average14}`);
17:     }
18:   }
19:   // ... (3: tidak berlatih 14 hari; 4: voucher hampir habis; 5: gagal dua tes berturut-turut)
20:   return out;
21: }

Ringkasan ditulis fungsi refreshProgressSummary ke progress_summary setiap
kali data murid berubah dan oleh pekerjaan harian pukul 07.00 yang mengirim
notifikasi peringatan. Aplikasi hanya membaca ringkasan ini, sehingga
laporan murid, guru, admin, dan orang tua selalu sama.
