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
| I Pendahuluan | `BAB_I_PENDAHULUAN.md` | Draf lengkap, 8 `[ISI]`; 1.4 tanpa alat bantu AI (permintaan pembimbing 2026-11-25); di Word: `word/BUKU TA Easy Study.docx` dan `word/BAB I PENDAHULUAN.docx` |
| II Teori Penunjang | `BAB_II_TEORI_PENUNJANG.md` | Draf lengkap; diperpanjang 2026-11-25 atas masukan pembimbing: Gambar 2.1–2.8 digambar sendiri (`tools/make_bab2_figs.py`), sekitar 2.940 kata, sekitar 15 halaman |
| III Proses Bisnis | `BAB_III_PROSES_BISNIS.md` | Draf lengkap, butuh foto dan angka dari pemilik; sistem lama **tanpa penjadwalan guru** (pemilik 2026-11-24: 3.2.2 dan Gambar 3.2/3.8 dihapus, gambar dinomori ulang); Gambar 3.1–3.3 adalah foto/tangkapan layar pemilik (`word/fig_3_1.png` daftar sesi WhatsApp dengan nama dan nomor diburamkan, `fig_3_2.png` daftar hadir kertas, `fig_3_3.png` halaman nilai HSK dengan data pribadi diburamkan); Gambar 3.4 aplikasi web Nilai Simulasi HSK (tangkapan layar); diagram digambar dari jawaban pemilik 2026-11-24 dan digambar ulang 2026-11-26 dengan aturan setengah halaman: 3.5–3.6 (rich picture), 3.7–3.9 (use case), 3.10–3.13 (activity), dari `tools/make_bab3_figs.py` |
| IV Analisa Sistem | `BAB_IV_ANALISA_SISTEM.md` | Draf lengkap dari jawaban pemilik 2026-11-24 dan dokumen asli (Google Form, Excel daftar siswa dan rekap absensi, kwitansi); Gambar 4.1–4.4 di `word/` (data pribadi diburamkan) |
| V Desain Sistem | `BAB_V_DESAIN_SISTEM.md` | Draf lengkap dari proposal §IV dan kode: 12 sub-bab, Algoritma 5.1–5.8, Rumus 5.1–5.2, Tabel 5.1–5.13; **sejak 2026-11-26 memakai set diagram UML (pilihan pemilik) dengan aturan setengah halaman: Gambar 5.1–5.26** (arsitektur 2, status 2, sequence 3, use case 5, activity 6, struktur koleksi 6, peta halaman 2), masing-masing dengan kalimat pengantar dan penjelasan; teks disesuaikan dengan Build 9 (duduk ulang kode tes, daftar berhalaman, laporan per periode); sekitar 7.600 kata |
| VI Implementasi | `BAB_VI_IMPLEMENTASI.md` | Diringkas dua kali atas masukan pembimbing (hanya bagian penting; batas 120 halaman termasuk halaman depan): Tabel 6.1–6.2, Gambar 6.1–6.12 (12 × 7,28 cm), Segmen Program 6.1–6.6, sekitar 1.720 kata, target 13 halaman (49 pada 2026-11-25, 20 setelah ringkasan pertama); versi lengkap (37 gambar, 17 segmen) di `archive/BAB_VI_LENGKAP_2026-11-25.md` dan `word/bab6_lengkap/` untuk lampiran dan naskah video; dua tanda kuning: tautan video demonstrasi dan huruf lampiran |
| VII–VIII | belum (kerangka sub-bab ada di buku Word) | setelah uji coba (Januari 2027) |
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

Tangkapan layar Bab VI: `node docs/thesis/tools/shots_bab6.mjs` (emulator + `seed_trial.py emulator` +
`scripts/run_emulator_web.sh` dulu; 37 halaman, 1280 × 800, bahasa Indonesia; hasil di `word/bab6_lengkap/`) lalu
`node docs/thesis/tools/clean_shots.mjs` (menghapus pita EMULATOR dan bilah peringatan Auth;
hasil 1280 × 776, dipasang 13 × 7,9 cm; menyalin dua belas gambar yang dipakai buku ke `word/fig_6_<n>.png`
menurut `tools/bab6_book.mjs`). Halaman yang perlu data khusus (sesi hari ini, kelas yang
dipesan, murid dengan hasil tes) dicari skrip itu sendiri di Firestore emulator. Setelah Build 9
(daftar berhalaman, leaderboard dengan waktu, laporan per periode) gambar 6.5 (laporan bulanan) dan 6.10 (leaderboard) diambil ulang.

Gambar Bab II: `python3 -I docs/thesis/tools/make_bab2_figs.py` (SVG digambar skrip, PNG lewat Chrome headless).

**Aturan gambar (pemilik dan pembimbing, 2026-11-26):** sebuah diagram paling besar setengah halaman, sehingga satu
halaman memuat dua diagram beserta penjelasannya. Diagram digambar 14 cm lebar dan paling tinggi 7,7 cm (kanvas
1000 × 550 px); yang tidak muat dipecah menjadi dua. Alat bersama: `tools/figkit.py` (menolak kanvas yang lebih tinggi).
Gambar Bab III: `python3 -I docs/thesis/tools/make_bab3_figs.py`. Gambar Bab V: `python3 -I docs/thesis/tools/make_bab5_figs.py`
(menjalankan bagian a dan b, lalu menyalin ke `word/fig_5_N.png` menurut tabel `BOOK` di dalamnya; nomor mengikuti urutan
di `BAB_V_DESAIN_SISTEM.md`). Tinggi setiap gambar di buku ada di `FIG_SIZE_CM` pada `build_book.py`. Foto 3.1, 3.2, dan 4.1
ditahan pada tinggi 9,5 cm.

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
bantuan AI: pembimbing meminta (2026-11-25) agar buku tidak menyebut alat
bantu AI sama sekali; Bab I §1.4 dan Tabel 6.1 sudah disesuaikan, dan bab
berikutnya mengikuti aturan yang sama.

**Masukan pembimbing 2026-11-25** (rinci di `docs/PLAN.md` §7): Bab II
diperpanjang dengan gambar; Bab V memakai banyak diagram; Bab VI hanya bagian
penting (boleh video demonstrasi); tebal buku 100 sampai 120 halaman; lima
tujuan pada Bab I §1.2 dijawab lima butir kesimpulan pada Bab VIII §8.1 dengan
urutan yang sama.

**Riwayat Hidup:** tanggal lahir dan alamat tidak masuk git (repositori
publik). Data ada di `local/riwayat.json` (kunci `ttl`, `alamat`, `sekolah`
sebagai daftar `[tahun, nama]`, `kerja_tahun`, `kerja`) dan hanya dipakai bila
berkas keluaran ditulis ke `local/`:
`python3 -I docs/thesis/tools/build_book.py "docs/thesis/local/[TEMPLATE] BUKU TA - TESIS.dotx" "docs/thesis/local/BUKU TA Easy Study.docx"`.
Buku di `word/` tetap memakai tanda `[ISI]` pada bagian itu.

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

| No | Segmen Program (Bab VI, enam sejak 2026-11-26; nomor versi lengkap dalam kurung) | Sumber |
|---|---|---|
| 6.1 (6.3) | Aturan Akses exercise_results, schedules, dan voucher_history | `firestore.rules` |
| 6.2 (6.4) | Fungsi overlaps dan conflicts | `functions/scheduling.js` |
| 6.3 (6.7) | Transaksi closeSession dan Kunci Idempoten voucher_history | `functions/index.js` |
| 6.4 (6.8) | Normalisasi dan Pencocokan Hanzi | `functions/typing_matcher.js` |
| 6.5 (6.9) | Fungsi finishExercise | `functions/index.js` |
| 6.6 (6.14) | Transaksi Pengkreditan Voucher dan creditDecision | `functions/payments.js`, `index.js` |

Sebelas segmen lainnya (inisialisasi, pengalihan peran, saveSchedule, bookingRefusal, countsAt dan promotionState, createInvoice, token Snap, tanda tangan Midtrans, warningsOf, grafik fl_chart, pemutar latihan) ada di `archive/BAB_VI_LENGKAP_2026-11-25.md`.
