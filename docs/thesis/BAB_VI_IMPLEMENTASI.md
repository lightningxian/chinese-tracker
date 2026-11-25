# BAB VI
# IMPLEMENTASI

Bab ini menguraikan hasil implementasi rancangan pada Bab V: halaman utama
aplikasi untuk setiap peran, lalu segmen program dari bagian yang menentukan
kebenaran sistem.

## 6.1 Implementasi Desain

Aplikasi dibangun sesuai arsitektur pada Gambar 5.1, dipasang di Firebase
Hosting pada alamat https://chinese-tracker.web.app, dan dibagikan pula
sebagai berkas APK Android. Lingkungan implementasi dirangkum pada Tabel
6.1. Tangkapan layar diambil dari Firebase Emulator Suite dengan data uji
coba.

Tabel 6.1
Lingkungan Implementasi

| Komponen | Teknologi dan versi |
|---|---|
| Aplikasi | Dart dan Flutter 3.44 (web, Android, iOS); go_router 14, provider 6, fl_chart |
| Backend | Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging, Hosting |
| Logika server | Cloud Functions generasi kedua pada Node.js 22; opencc-js untuk aksara tradisional |
| Pembayaran | Midtrans Snap (sandbox) dengan notifikasi HTTP |

Bagian ini hanya memuat halaman yang paling menentukan. Halaman lainnya
diperlihatkan pada video demonstrasi
⟦ISI: tautan atau kode QR video demonstrasi⟧ dan pada ⟦Lampiran⟧.

### 6.1.1 Halaman Umum

Halaman yang dapat dibuka tanpa masuk adalah halaman depan, halaman masuk,
pendaftaran murid, dan tes penempatan dengan token dari guru. Akun yang
mendaftar sendiri baru aktif setelah disetujui admin.

### 6.1.2 Halaman Admin

Dasbor admin pada Gambar 6.1 memuat hal yang perlu ditindaklanjuti hari
ini, empat angka ringkas, dan grafik murid baru per bulan.

[GAMBAR 6.1: dashboard admin]

Gambar 6.1
Dasbor Admin

Pada halaman persetujuan (Gambar 6.2) admin menetapkan tingkat dan guru
murid baru, lalu menyetujui atau menolaknya dengan alasan.

[GAMBAR 6.2: persetujuan pendaftaran]

Gambar 6.2
Persetujuan Pendaftaran

Jadwal mingguan pada Gambar 6.3 menampilkan kelas per ruang dan per hari;
penyimpanannya menolak bentrok guru dan ruang (Segmen Program 6.2).

[GAMBAR 6.3: jadwal mingguan]

Gambar 6.3
Jadwal Mingguan

Verifikasi kenaikan tingkat pada Gambar 6.4 memuat rekomendasi yang dibuat
sistem ketika murid memenuhi syarat jumlah kode tes, untuk disetujui admin.

[GAMBAR 6.4: verifikasi kenaikan tingkat]

Gambar 6.4
Verifikasi Kenaikan Tingkat

Laporan bulanan pada Gambar 6.5 merangkum murid baru, pendapatan,
kehadiran, dan jam mengajar, dengan ekspor CSV dan PDF.

[GAMBAR 6.5: laporan bulanan]

Gambar 6.5
Laporan Bulanan

Halaman admin lainnya (pengguna, bank soal, kode tes, voucher, daftar harga,
tagihan, dan berita) mengikuti pola yang sama.

### 6.1.3 Halaman Guru

Pada halaman sesi (Gambar 6.6) guru menandai murid hadir, izin, atau alpa,
lalu menutup sesi (Segmen Program 6.3).

[GAMBAR 6.6: halaman sesi dan absensi]

Gambar 6.6
Halaman Sesi dan Absensi

Pengawasan sesi tes pada Gambar 6.7 menampilkan token untuk murid dan
bagian yang sedang dikerjakan setiap murid.

[GAMBAR 6.7: pengawasan sesi tes]

Gambar 6.7
Pengawasan Sesi Tes

Guru juga memiliki jadwal mengajar, paket latihan, laporan progress murid,
dan antrean penilaian jawaban ketik dan tulisan bebas.

### 6.1.4 Halaman Murid

Beranda murid pada Gambar 6.8 menampilkan sisa sesi, pengumuman, dan sesi
kelas yang dapat dipesan (Algoritma 5.2).

[GAMBAR 6.8: beranda murid dan pemesanan sesi]

Gambar 6.8
Beranda Murid dan Pemesanan Sesi

Pemutar latihan pada Gambar 6.9 menampilkan soal satu per satu, termasuk
soal ketik; jawaban dikumpulkan satu kali dan dinilai di server (Segmen
Program 6.5).

[GAMBAR 6.9: pemutar latihan (soal ketik)]

Gambar 6.9
Pemutar Latihan dengan Soal Ketik

Leaderboard pada Gambar 6.10 mengurutkan hasil satu kode tes, yang
dikerjakan murid dengan token dari guru, menurut nilai lalu waktu.

[GAMBAR 6.10: leaderboard kode tes]

Gambar 6.10
Leaderboard Kode Tes

Halaman pembayaran murid pada Gambar 6.11 memuat voucher aktif, tagihan,
dan tombol Beli; sesi dikreditkan begitu Midtrans mengabarkan lunas (Segmen
Program 6.6).

[GAMBAR 6.11: voucher dan pembayaran murid]

Gambar 6.11
Voucher dan Pembayaran Murid

Laporan progress pada Gambar 6.12 memuat tingkat, grafik nilai latihan,
riwayat tes, kehadiran, voucher, dan peringatan, sama dengan yang dilihat
guru.

[GAMBAR 6.12: laporan progress murid]

Gambar 6.12
Laporan Progress Murid

Halaman murid lainnya memuat riwayat kelas dan daftar latihan yang
ditugaskan.

## 6.2 Implementasi Program

Kode disusun seperti pada Tabel 6.2. Logika yang menentukan uang, nilai,
dan tingkat berada di Cloud Functions. Segmen program dikutip dari kode
produksi; baris yang diringkas ditandai `// ...`.

Tabel 6.2
Susunan Kode Sumber

| Folder atau berkas | Isi |
|---|---|
| lib/ | Aplikasi Flutter: pengalihan halaman menurut peran, halaman per fitur, layanan Firebase, dan model data |
| functions/ | index.js (Cloud Functions) dan modul logika murni beserta pengujiannya |
| firestore.rules, storage.rules | Aturan akses beserta pengujiannya di rules-tests/ |

### 6.2.1 Aturan Akses Firestore

Penjaga yang sebenarnya adalah Firestore Security Rules, karena aplikasi
dapat dilewati dengan memanggil Firestore langsung. Segmen Program 6.1
memuat tiga koleksi yang mewakili polanya.

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
14:   // ... (baca: staf, murid itu sendiri, atau orang tuanya)
15:   allow write: if false;
16: }

Ketiga koleksi tidak dapat ditulis dari aplikasi, sehingga hanya fungsi
saveSchedule, finishExercise, dan closeSession yang menulisnya. Aturan ini
diuji dengan 86 pengujian pada emulator.

### 6.2.2 Penjadwalan dan Penutupan Sesi

Pengecekan bentrok dari Algoritma 5.1 adalah dua fungsi murni pada
scheduling.js (Segmen Program 6.2).

Segmen Program 6.2
Fungsi overlaps dan conflicts
01: function overlaps(a, b, gapMinutes = 0) {
02:   const g = Number(gapMinutes) || 0;
03:   return a.startMinutes < b.endMinutes + g && b.startMinutes < a.endMinutes + g;
04: }
05: function conflicts(s, ctx) {
06:   const out = [];
07:   const gap = ctx.gapMinutes === undefined ? DEFAULTS.minGapMinutes : ctx.gapMinutes;
08:   // ... (ketersediaan guru)
09:   const live = (x) => x.active !== false && x.id !== s.id;
10:   for (const o of (ctx.teacherSchedules || []).filter(live)) {
11:     if (o.weekday === s.weekday && periodsOverlap(o, s) && overlaps(o, s, gap)) {
12:       // ... (out.push alasan bentrok guru)
13:     }
14:   }
15:   // ... (ruang diperiksa dengan cara yang sama)
16:   return out;
17: }

Fungsi saveSchedule memanggil conflicts di dalam transaksi yang mengunci
guru dan ruang (schedule_locks), sehingga dua jadwal yang bentrok tidak
dapat tersimpan bersamaan.

Pemotongan voucher yang konsisten berada di dalam fungsi closeSession;
Segmen Program 6.3 memuat inti transaksinya.

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
09:   // ... (daftar hadir dan voucher terkait dibaca)
10:   for (const {ref: aRef, a, termId} of atts) {
11:     // ... (st = hadir, izin, atau alpa; charged: voucher cukup dan sesi terpakai)
12:     tx.set(db.collection(VOUCHER_HISTORY).doc(`${ref.id}_${a.studentId}`), {
13:       // ... (kind, studentId, termId, sessionId, status, sessions, date)
14:     });
15:     tx.update(aRef, {attendanceStatus: st, sessionCredited: charged, closed: true});
16:   }
17:   // ... (tx.update voucher; tx.set rekap guru)
18:   tx.update(ref, {status: "done", isConcluded: true, isOpen: false,
19:     concludedAt: FieldValue.serverTimestamp()});
20:   return {status: "done", credited, excused, failed};
21: });

Semua berada dalam satu transaksi. Buku besar memakai id
sessionId_studentId dan sesi berstatus done langsung dikembalikan, sehingga
pemanggilan kedua tidak memotong voucher lagi.

### 6.2.3 Penilaian Latihan dan Tes

Pencocokan jawaban ketik dari Algoritma 5.4 berada pada typing_matcher.js
(Segmen Program 6.4).

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
0,75 (Rumus 2.1) berarti setengah nilai dan ditandai untuk guru.

Penilaian satu paket dilakukan fungsi finishExercise (Segmen Program 6.5),
yang dipanggil satu kali setelah semua soal dijawab.

Segmen Program 6.5
Fungsi finishExercise
01: exports.finishExercise = onCall(async (request) => {
02:   const {uid, profile} = await requireCaller(request);
03:   // ... (exerciseId dan answers dari request.data)
04:   const exercise = await loadAssignedPackage(exerciseId, uid);
05:   const items = await loadPackageItems(exercise);
06:   let late = false;
07:   // ... (paket berwaktu: late dari jam server)
08:   const scored = play.scoreAttempt(items, answers);
09:   // ... (jawaban terlambat dinilai 0)
10:   const status = result.open > 0 ? "pending_marking" : "final";
11:   // ... (tulis exercise_results; jawaban terbuka ke marking_items)
12:   return {...result, late, status, resultId: resultRef.id};
13: });

Hasil dengan jawaban terbuka berstatus pending_marking sampai dinilai guru.
Tes simulasi HSK dinilai per bagian (Rumus 5.2). Hitungan menuju kenaikan
tingkat pada promotion.js (countsAt dan promotionState) mengikuti Algoritma
5.6.

### 6.2.4 Pembayaran Midtrans

Fungsi createInvoice mengambil harga dari server, lalu meminta token Snap
dengan server key dari Secret Manager. Tanda tangan notifikasi pembayaran
(SHA-512 dari order_id, status_code, gross_amount, dan server key)
diperiksa; yang salah ditolak (MT-02), yang sah memasuki transaksi pada
Segmen Program 6.6.

Segmen Program 6.6
Transaksi Pengkreditan Voucher dan creditDecision
01: function creditDecision(invoice, newStatus, grossAmount) {
02:   const status = (invoice || {}).status || "pending";
03:   // ... (tagihan yang sudah final atau dibuang: "ignore-final")
04:   if (!newStatus) return "no-change";
05:   if (newStatus !== "paid") return "flip";
06:   if (Math.round(Number(grossAmount)) !== Math.round(Number((invoice || {}).amount))) {
07:     return "amount-mismatch";
08:   }
09:   return "credit";
10: }
11: // di dalam midtransNotification (functions/index.js):
12: await db.runTransaction(async (tx) => {
13:   const snap = await tx.get(invoiceRef);
14:   const invoice = snap.data() || {};
15:   const decision = payments.creditDecision(invoice, newStatus, grossAmount);
16:   if (decision === "ignore-final" || decision === "no-change") return;
17:   // ... (amount-mismatch: tidak dikreditkan, dicatat untuk admin)
18:   const termSnap = newStatus === "paid" ? await linkedTermSnap(tx, invoice) : null;
19:   tx.update(invoiceRef, {status: newStatus,
20:     ...(newStatus === "paid" ? {paidAt: FieldValue.serverTimestamp()} : {})});
21:   if (newStatus !== "paid") return;
22:   credited = creditPaidInvoice(tx, invoiceRef, withPriceItem(invoice, pricing), termValidDays, termSnap);
23: });

Status tagihan dan voucher ditulis dalam satu transaksi, sehingga tidak ada
tagihan lunas tanpa voucher; notifikasi yang terkirim dua kali (MT-03)
berhenti pada ignore-final. Lima peringatan laporan progress pada fungsi
warningsOf di progress.js mengikuti Algoritma 5.8.
