#!/usr/bin/env node
// Build 8 (docs/PLAN.md §4, Must 6): the printable trial sheets.
//   node tool/trial_kit/build_sheets.mjs
// Writes docs/trial/task_sheet_{student,teacher,admin}.html and
// docs/trial/sus_questionnaire.html (open in a browser, print to A4/PDF).
// The tasks follow the proposal's 15 screens and the scenario IDs; adjust
// the wording to the proposal's Table 20 when the Word file is here.
import {writeFileSync} from "node:fs";
import {dirname, join} from "node:path";
import {fileURLToPath} from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "docs", "trial");

export const SUS_ITEMS = [
  "Saya berpikir akan menggunakan sistem ini lagi.",
  "Saya merasa sistem ini rumit untuk digunakan.",
  "Saya merasa sistem ini mudah digunakan.",
  "Saya membutuhkan bantuan dari orang lain atau teknisi dalam menggunakan sistem ini.",
  "Saya merasa fitur-fitur sistem ini berjalan dengan semestinya.",
  "Saya merasa ada banyak hal yang tidak konsisten (tidak serasi) pada sistem ini.",
  "Saya merasa orang lain akan memahami cara menggunakan sistem ini dengan cepat.",
  "Saya merasa sistem ini membingungkan.",
  "Saya merasa tidak ada hambatan dalam menggunakan sistem ini.",
  "Saya perlu membiasakan diri terlebih dahulu sebelum menggunakan sistem ini.",
];

const TASKS = {
  student: ["Siswa", [
    ["Daftar akun dan pilih \"Ikut tes penempatan\" dengan target level.", "Akun menunggu persetujuan admin; layar tunggu tampil."],
    ["Masuk setelah disetujui, buka Sesi Kelas dan daftar satu sesi.", "Muncul \"Terdaftar\"; kursi tersisa berkurang satu."],
    ["Coba daftar sesi yang penuh atau bentrok.", "Ditolak dengan alasan yang jelas (mis. \"Kelas penuh\")."],
    ["Kerjakan satu paket latihan sampai selesai.", "Nilai dan pembahasan tampil setelah dikirim."],
    ["Jawab soal mengetik hanzi/pinyin.", "Jawaban dinilai; jawaban setengah benar ditandai untuk guru."],
    ["Buka Voucher Kursus, lalu Beli paket (sandbox).", "Sisa sesi, masa berlaku, riwayat tampil; pembayaran sandbox terbuka."],
    ["Mulai tes simulasi dengan token dari guru.", "Tes terbuka per bagian dengan waktu; token salah ditolak."],
    ["Buka leaderboard kode tes yang sudah dikerjakan.", "Peringkat, nilai L/R/T, total, lulus/tidak; baris sendiri disorot."],
    ["Buka Laporan Progress.", "Grafik latihan, kehadiran, nilai per keterampilan, riwayat tes."],
  ]],
  teacher: ["Guru", [
    ["Buka Jadwal → Minggu, konfirmasi jadwal mingguan.", "Status berubah menjadi Dikonfirmasi."],
    ["Ajukan perubahan jadwal dengan alasan.", "Permintaan terkirim; admin menerima notifikasi."],
    ["Atur ketersediaan dan satu hari libur.", "Tersimpan; admin melihatnya di Ketersediaan."],
    ["Jadwal → Hari ini: tekan Mulai sesi.", "Status Berlangsung; terlambat >15 menit tercatat."],
    ["Tutup sesi: isi hadir/izin/alpa.", "Voucher siswa terpotong sesuai status; menekan lagi tidak memotong dua kali."],
    ["Buka sesi tes dengan kode tes, tampilkan token.", "Token 6 karakter, hitung mundur 15 menit, daftar siswa tampil."],
    ["Pantau siswa yang keluar halaman saat tes.", "Kejadian \"keluar halaman\" tampil di layar pengawasan."],
    ["Nilai jawaban di antrean penilaian.", "Nilai siswa menjadi final; siswa diberi tahu."],
    ["Tulis catatan tindak lanjut di laporan progress siswa.", "Catatan tampil untuk siswa dan orang tua."],
  ]],
  admin: ["Admin", [
    ["Pengguna → Persetujuan: setujui satu pendaftar dengan level dan guru.", "Siswa aktif dan diberi tahu; menolak butuh alasan."],
    ["Buat jadwal yang bentrok dengan guru/ruang lain.", "Ditolak dengan alasan dan saran waktu kosong."],
    ["Buat jadwal yang benar.", "Tersimpan; sesi 14 hari ke depan dibuat otomatis."],
    ["Tetapkan guru pengganti pada satu sesi.", "Hanya guru yang kosong ditawarkan; semua pihak diberi tahu."],
    ["Batalkan satu sesi yang sudah ada pendaftar.", "Pendaftaran kembali ke voucher; siswa diberi tahu."],
    ["Verifikasi rekomendasi kenaikan level.", "Level siswa naik; riwayat level tercatat."],
    ["Buka Dasbor: enam kartu tugas.", "Tiap kartu menunjukkan jumlah dan membuka daftarnya."],
    ["Pembayaran: lihat transaksi sandbox.", "Status lunas/pending/expire sesuai dashboard Midtrans sandbox."],
    ["Laporan → Laporan bulanan: hitung ulang, unduh CSV dan PDF.", "Angka bulan itu tampil; file terunduh."],
    ["Org settings → Cek voucher.", "Semua voucher cocok dengan riwayat."],
  ]],
};

const style = `<style>
  @page { size: A4; margin: 18mm; }
  body { font-family: "Times New Roman", serif; font-size: 12pt; color: #000; }
  h1 { font-size: 16pt; margin: 0 0 4pt; } p.meta { margin: 0 0 10pt; }
  table { width: 100%; border-collapse: collapse; }
  th, td { border: 1px solid #000; padding: 5pt 6pt; vertical-align: top; }
  th { background: #eee; } td.c { text-align: center; width: 9%; }
  .line { display: inline-block; min-width: 55mm; border-bottom: 1px solid #000; }
  @media screen { body { max-width: 190mm; margin: 12mm auto; } }
</style>`;
const page = (title, body) => `<!doctype html><html lang="id"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>${title}</title>${style}</head>
<body>${body}</body></html>\n`;
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  for (const [key, [role, tasks]] of Object.entries(TASKS)) {
    const rows = tasks.map(([t, e], i) => `<tr><td class="c">${i + 1}</td><td>${esc(t)}</td>` +
      `<td>${esc(e)}</td><td class="c"></td><td class="c"></td></tr>`).join("\n");
    writeFileSync(join(OUT, `task_sheet_${key}.html`), page(`Lembar tugas ${role}`,
      `<h1>Lembar Tugas Uji Coba — ${role}</h1>
<p class="meta">Easy Study · Kode responden <span class="line"></span> · Tanggal <span class="line"></span></p>
<table><tr><th>No</th><th>Tugas</th><th>Hasil yang diharapkan</th><th>Berhasil</th><th>Gagal</th></tr>
${rows}</table>
<p>Catatan:</p><p class="line" style="min-width:100%">&nbsp;</p>`));
  }
  const items = SUS_ITEMS.map((q, i) => `<tr><td class="c">${i + 1}</td><td>${esc(q)}</td>` +
    [1, 2, 3, 4, 5].map(() => "<td class=\"c\">☐</td>").join("") + "</tr>").join("\n");
  writeFileSync(join(OUT, "sus_questionnaire.html"), page("Kuesioner SUS",
    `<h1>Kuesioner System Usability Scale (SUS)</h1>
<p class="meta">Easy Study · Kode responden <span class="line"></span> · Peran: siswa / guru / admin</p>
<p>Beri tanda pada satu kotak untuk setiap pernyataan: 1 = sangat tidak setuju, 5 = sangat setuju.</p>
<table><tr><th>No</th><th>Pernyataan</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th></tr>
${items}</table>`));
  console.log("sheets: task_sheet_student/teacher/admin.html, sus_questionnaire.html");
}
