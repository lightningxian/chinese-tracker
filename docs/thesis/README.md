# Draf buku Tugas Akhir — cara memakai folder ini

Folder ini berisi draf bab buku Tugas Akhir dalam bahasa Indonesia, ditulis
oleh chat PLAN dari proposal revisi (Oktober 2026) dan dokumentasi repo.
Draf ini **bahan mentah**: pemilik membaca, memperbaiki, dan memindahkannya
ke template kampus (`[TEMPLATE] BUKU TA - TESIS.dotx`, satu file Word per
bab). Format akhir (margin, font, caption, nomor halaman) diatur di Word,
bukan di sini; aturannya ada di `docs/THESIS_BOOK_GUIDE.md` §6.

**Tanda yang dipakai**

- `[ISI: …]` = fakta yang hanya pemilik yang tahu (angka, tanggal, nama,
  foto). Semua harus diganti sebelum bab dianggap selesai.
- `[GAMBAR 3.1 …]` / `[TABEL …]` = tempat gambar atau tabel; captionnya
  sudah ditulis sesuai aturan kampus (Gambar: caption di bawah; Tabel:
  caption di atas; nomor per bab).
- Kutipan `[n]` mengacu pada `DAFTAR_PUSTAKA.md` (urut abjad, sesuai aturan
  kampus). Nomornya berbeda dengan nomor di proposal.
- Blok ```mermaid``` adalah **alat bantu menggambar** untuk pemilik (dibuka
  di draw.io atau mermaid.live), bukan isi buku. Di buku, diagram digambar
  ulang dan dimasukkan sebagai gambar.

**Status**

| Bab | File | Status |
|---|---|---|
| I Pendahuluan | `BAB_I_PENDAHULUAN.md` | Draf lengkap, 8 `[ISI]`; 1.4 menyebut Claude Code (keputusan pemilik 2026-11-24); di Word: `word/BUKU TA Easy Study.docx` dan `word/BAB I PENDAHULUAN.docx` |
| II Teori Penunjang | `BAB_II_TEORI_PENUNJANG.md` | Draf lengkap |
| III Proses Bisnis | `BAB_III_PROSES_BISNIS.md` | Draf lengkap, butuh foto dan angka dari pemilik; sistem lama **tanpa penjadwalan guru** (pemilik 2026-11-24: 3.2.2 dan Gambar 3.2/3.8 dihapus, gambar dinomori ulang); Gambar 3.1–3.3 adalah foto/tangkapan layar pemilik (`word/fig_3_1.png` daftar sesi WhatsApp dengan nama dan nomor diburamkan, `fig_3_2.png` daftar hadir kertas, `fig_3_3.png` halaman nilai HSK dengan data pribadi diburamkan); Gambar 3.4 aplikasi web Nilai Simulasi HSK (tangkapan layar), 3.5 (rich picture), 3.6 (use case), 3.7 dan 3.8 (activity) digambar dari jawaban pemilik 2026-11-24 (`word/fig_3_4.png` sampai `fig_3_8.png`, sumber SVG di scratchpad chat PLAN) |
| IV Analisa Sistem | `BAB_IV_ANALISA_SISTEM.md` | Draf lengkap dari jawaban pemilik 2026-11-24 dan dokumen asli (Google Form, Excel daftar siswa dan rekap absensi, kwitansi); Gambar 4.1–4.4 di `word/` (data pribadi diburamkan) |
| V Desain Sistem | `BAB_V_DESAIN_SISTEM.md` | Draf lengkap dari proposal §IV dan kode: 12 sub-bab, Algoritma 5.1–5.8 (format kampus, numbering template), Rumus 5.1–5.2, Tabel 5.1–5.13, Gambar 5.1–5.9 (arsitektur, use case per peran, 4 activity diagram, peta halaman) di `word/` |
| VI–VIII | belum (kerangka sub-bab ada di buku Word) | VI berikutnya (tangkapan layar + segmen program); VII–VIII setelah uji coba |
| Daftar Pustaka | `DAFTAR_PUSTAKA.md` | 20 sumber proposal, urut abjad |

**File Word (`word/`)**

`word/BUKU TA Easy Study.docx` (2026-11-24) adalah **buku lengkap dalam satu
file** untuk diperiksa: halaman judul, pengesahan, surat pernyataan, abstrak,
abstract, kata pengantar, daftar isi/gambar/tabel/algoritma/segmen/rumus,
Bab I–III dari draf `.md`, kerangka Bab IV–VIII (judul sub-bab + catatan
kuning tentang isinya), daftar pustaka, dan riwayat hidup. Nomor halaman pada
semua daftar adalah field PAGEREF: di Word tekan **Ctrl+A lalu F9** (Word juga
menanyakannya saat file dibuka). Setiap `word/fig_<bab>_<n>.png` yang ada
dipasang sebagai gambar untuk Gambar bab.n (ukuran di `FIG_SIZE_CM`, bawaan
14 × 8 cm); yang belum ada tetap kotak kuning. Dibuat oleh `tools/build_book.py`:

```
python3 -I docs/thesis/tools/build_book.py docs/thesis/local/TEMPLATE.dotx \
  "docs/thesis/word/BUKU TA Easy Study.docx"
```

Untuk pengumpulan, kampus meminta satu file per bab; file per bab dibuat
dengan `tools/build_bab.py` (contoh di bawah) atau dengan memecah buku lengkap
di Word setelah teks final.

`word/BAB I PENDAHULUAN.docx` (2026-11-23) adalah Bab I yang sudah dimasukkan
ke template kampus: style `[STTS] Judul Bab`, `[STTS] Judul Sub Bab` dengan
nomor otomatis (1.1, 1.3.1), daftar bernomor, caption `[STTS] Gambar`, dan
pengaturan halaman dari template. Tanda `[ISI: …]` disorot kuning. Gambar 1.1
(Waterfall) ada di `word/fig_1_1.png`.

File ini dibuat oleh `tools/build_bab.py` (Python 3, tanpa pustaka tambahan)
dari file `.md` dan template kampus. Template tidak disimpan di repo (bukan
milik kita); taruh salinannya di `docs/thesis/local/` (di-ignore git). Contoh:

```
python3 -I docs/thesis/tools/build_bab.py docs/thesis/local/TEMPLATE.dotx \
  docs/thesis/BAB_I_PENDAHULUAN.md "docs/thesis/word/BAB I PENDAHULUAN.docx" \
  docs/thesis/word/fig_1_1.png
```

Setelah teks di Word diubah tangan, jangan jalankan ulang skrip untuk bab itu
(hasilnya menimpa file Word); ubah `.md`-nya dulu bila ingin tetap sinkron.

Sebelum memindahkan ke Word, tanyakan ke pembimbing: (1) daftar bab
(delapan bab seperti buku contoh kampus, atau digabung), (2) gaya kutipan
(`[n]` seperti draf ini, atau footnote seperti kriteria kampus). Tentang
bantuan AI: pemilik memutuskan (2026-11-24) bahwa Claude Code dicantumkan
sebagai perangkat lunak di Bab I §1.4, poin 8; pernyataan keaslian tetap
keputusan pemilik dan pembimbing.

**Algoritma dan segmen program di `.md`:** blok `Algoritma 5.1` (baris judul,
lalu baris `01: …`) dan `Segmen Program 6.1` dirender `build_book.py` dengan
style dan numbering template (`01:`), lalu masuk Daftar Algoritma / Daftar
Segmen Program otomatis. Rencana (usulan chat PLAN 2026-11-24; Bab V sudah
ditulis; aturan
kampus: judul TNR 12 bold rata kiri, isi Courier New 10 dengan numbering
template, tidak boleh langsung di bawah judul sub-bab, tidak boleh memenuhi
satu halaman, selalu diikuti paragraf; kode panjang ke Lampiran E):

| No | Algoritma (Bab V, pseudocode bernomor) | Sumber |
|---|---|---|
| 5.1 | Pengecekan Bentrok Jadwal | `functions/scheduling.js` `conflicts`, `overlaps` |
| 5.2 | Pemesanan Sesi | `bookingRefusal`, `termForBooking` |
| 5.3 | Penutupan Sesi dan Pemotongan Voucher | `closeSession` (`functions/index.js`) |
| 5.4 | Pencocokan Jawaban Typing | `functions/typing_matcher.js` |
| 5.5 | Penilaian Tes Simulasi HSK per Bagian | `finishExercise` |
| 5.6 | Kenaikan Tingkat | `functions/promotion.js` `countsAt`, `promotionState` |
| 5.7 | Rekomendasi Tingkat Tes Penempatan | `functions/placement.js` |
| 5.8 | Peringatan Progress Murid | `functions/progress.js` `warningsOf` |

| No | Segmen Program (Bab VI, ≤ 25 baris + paragraf) | Sumber |
|---|---|---|
| 6.1 | Inisialisasi Firebase | `lib/main.dart` |
| 6.2 | Pengalihan halaman menurut peran dan status akun | `lib/app.dart` |
| 6.3 | Aturan akses `exercise_results` dan `schedules` | `firestore.rules` |
| 6.4 | `conflicts` dan `overlaps` | `functions/scheduling.js` |
| 6.5 | `saveSchedule`: transaksi dan `schedule_locks` | `functions/index.js` |
| 6.6 | `bookSession` dan `bookingRefusal` | `functions/index.js`, `scheduling.js` |
| 6.7 | `closeSession`: satu transaksi, kunci idempoten `voucher_history` | `functions/index.js` |
| 6.8 | Normalisasi dan `matchHanzi` / `matchPinyin` | `functions/typing_matcher.js` |
| 6.9 | `finishExercise`: nilai per bagian, antrean penilaian | `functions/index.js` |
| 6.10 | `countsAt` dan `promotionState` dalam `onTestResultWritten` | `functions/promotion.js` |
| 6.11 | `createInvoice` dan token Snap | `functions/payments.js` |
| 6.12 | Notifikasi pembayaran dan pembuatan term voucher | `functions/payments.js` |
| 6.13 | `warningsOf` | `functions/progress.js` |
| 6.14 | Grafik `StudentProgressReport` (`fl_chart`) | `lib/features/...` |
| 6.15 | Pemutar latihan: kirim jawaban sekali ke `finishExercise` | `lib/features/exercises/` |
