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
| I Pendahuluan | `BAB_I_PENDAHULUAN.md` | Draf lengkap, 9 `[ISI]`; sudah di Word: `word/BAB I PENDAHULUAN.docx` |
| II Teori Penunjang | `BAB_II_TEORI_PENUNJANG.md` | Draf lengkap |
| III Proses Bisnis | `BAB_III_PROSES_BISNIS.md` | Draf lengkap, butuh foto dan angka dari pemilik |
| IV–VIII | belum | IV–VI setelah pemilik setuju struktur; VII–VIII setelah uji coba |
| Daftar Pustaka | `DAFTAR_PUSTAKA.md` | 20 sumber proposal, urut abjad |

**File Word (`word/`)**

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

Sebelum memindahkan ke Word, tanyakan dua hal ke pembimbing: (1) daftar
bab (delapan bab seperti buku contoh kampus, atau digabung), (2) aturan
kampus tentang bantuan AI dalam penulisan. Draf ini disusun dengan bantuan
Claude; keputusan tentang pernyataan keaslian ada pada pemilik dan
pembimbing.
