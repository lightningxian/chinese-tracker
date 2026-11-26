// The script of the demonstration video (make_demo_video.mjs films it).
//
// A scene is a title card ({card}) or a walk as one account ({name, role, as,
// start, steps}). A step is one action with an optional caption and a wait:
//   {caption: "…"}                 text in the strip under the picture, until the next caption
//   {click: "Label"}               an element by its label (or {text, exact, role, nth}), or [x, y]
//   {hover: "Label"}               the pointer goes there without a click
//   {type: "text"}                 typed into the focused field, a character at a time
//   {key: "Enter"}  {scroll: 800}  a key; the mouse wheel (pixels, negative = up)
//   {go: "/route"}                 opens a route of the app
//   {do: async ({app, emu, shared}) => …}   anything else (emu calls the local emulators)
//   wait: ms                       pause after the action (default 1.2 s, 2.6 s with a caption)
//   hidden: true                   not filmed (loading)      optional: true   skipped when it fails
// Labels are the Indonesian texts on screen. Points are in the 1440 x 738 window.
// `shared` carries values between scenes (the test token, ids).
import {ensureRunningClass, D} from "../emu_prep.mjs";

const TEST_CODE = "H3ESSAY";       // the seed's short paper: one listening, one reading, two writing questions
const card = (ms, lines) => ({card: {ms, lines}});
const part = (n, title, sub) => card(3200, [
  {text: `Bagian ${n}`, size: 40, color: "grey"},
  {text: title, size: 76, bold: true, color: "green"},
  {text: sub, size: 36},
]);

export const SCENES = [
  card(7000, [
    {text: "Aplikasi Multiplatform Sistem Kursus Bahasa Mandarin", size: 58, bold: true},
    {text: "Easy Study menggunakan Flutter", size: 58, bold: true},
    {text: " ", size: 30},
    {text: "Video Demonstrasi Aplikasi", size: 50, bold: true, color: "green"},
    {text: " ", size: 24},
    {text: "WILSIN · 221310660", size: 36},
    {text: "Program Studi S1 Informatika · Institut Sains dan Teknologi Terpadu Surabaya", size: 32, color: "grey"},
    {text: " ", size: 24},
    {text: "Seluruh data pada video ini adalah data uji coba.", size: 28, color: "grey"},
  ]),

  // ------------------------------------------------------------------ Admin
  part(1, "Admin", "Persetujuan, pengguna, jadwal, tagihan, laporan, dan jejak audit"),
  {name: "admin", role: "Admin", as: `admin${D}`, start: "/?tab=0", steps: [
    {caption: "Dasbor admin merangkum hal yang perlu ditindaklanjuti hari ini.", wait: 4500},
    {click: "Pendaftaran menunggu", caption: "Murid yang mendaftar sendiri menunggu persetujuan admin.", wait: 3500},
    {click: {text: "Guru", exact: true, role: "button"}, wait: 1500},
    {click: {text: "Test Teacher", role: "menuitem"}, caption: "Admin memilih guru dan level awal murid baru.", wait: 2600},
    {click: {text: "Setujui", exact: true, nth: 0}, caption: "Setelah disetujui, akun murid aktif dan murid diberi tahu.", wait: 4500},

    {click: [84, 235], caption: "Daftar pengguna dibaca per halaman, 25 baris setiap halaman.", wait: 3800},
    {scroll: 2400, wait: 1800},
    {click: "Halaman berikutnya", wait: 3200, optional: true},
    {scroll: -3000, wait: 1200},
    {click: [600, 112], wait: 600},
    {type: "budi", caption: "Pencarian menjangkau semua akun, bukan hanya halaman yang tampil.", wait: 4200},

    {go: "/admin/timetable", caption: "Jadwal mingguan disusun per ruang dan per hari.", wait: 4200},
    {click: "Jadwal baru", wait: 1800},
    {click: [720, 145], wait: 500},
    {type: "Kelas Percobaan", wait: 700},
    {click: {text: "Guru", exact: true, role: "button"}, wait: 1300},
    {click: {text: "Test Teacher", role: "menuitem"}, caption: "Admin mencoba menambah jadwal pada jam yang sudah terisi.", wait: 3000},
    {caption: "Sistem menemukan bentrok guru dan ruang; jadwal tidak dapat disimpan.", wait: 5500},
    {click: {text: "Batal", exact: true}, wait: 1500},
    {click: {text: "Buang", exact: true}, wait: 1800},

    {click: [84, 485], caption: "Tagihan dibaca per halaman dalam rentang tanggal yang dipilih.", wait: 4000},
    {click: "7 hari terakhir", wait: 2800},
    {click: "Bulan ini", wait: 2800},
    {scroll: 2400, wait: 1800},
    {click: "Halaman berikutnya", caption: "Halaman berikutnya baru dibaca dari server saat diminta.", wait: 4000, optional: true},

    {click: [84, 535], caption: "Laporan admin dipilih per periode bulan.", wait: 3500},
    {click: "3 bulan terakhir", wait: 2800},
    {click: {text: "Hitung ulang", nth: 0}, wait: 2600, optional: true},
    {click: {text: "Hitung ulang", nth: 1}, wait: 2600, optional: true},
    {click: {text: "Hitung ulang", nth: 2}, caption: "Angka dijumlahkan per bulan; ekspor PDF dan CSV mengikuti periode.", wait: 5000, optional: true},

    {go: "/admin/audit-logs", caption: "Jejak audit mencatat setiap tindakan penting dan dibaca per halaman.", wait: 4000},
    {scroll: 3400, wait: 1500},
    {click: "Halaman berikutnya", wait: 3200, optional: true},

    {go: "/admin/tests/promotion", caption: "Aturan kenaikan tingkat dan rekomendasi yang menunggu keputusan admin.", wait: 5000},
  ]},

  // ------------------------------------------------------------------ Guru
  part(2, "Guru", "Jadwal mengajar, absensi, penutupan sesi, dan sesi tes"),
  {name: "guru", role: "Guru", as: `teacher${D}`, start: "/",
    before: async ({shared}) => Object.assign(shared, await ensureRunningClass()),
    steps: [
      {caption: "Dasbor guru.", wait: 3000},
      {go: "/teacher/schedule", caption: "Jadwal hari ini: satu kelas sedang berlangsung dengan empat murid.", wait: 4500},
      {click: "Absen guru", caption: "Guru mencatat kedatangannya.", wait: 3200, optional: true},
      {click: {text: "Tutup sesi", exact: true, role: "button"}, caption: "Saat menutup sesi, guru mengisi absensi: hadir, izin, atau alpa.", wait: 3500},
      {click: {text: "Izin", exact: true, nth: 1}, wait: 1300},
      {click: {text: "Alpa", exact: true, nth: 2}, wait: 1300},
      {click: {text: "Tanda tangan di papan", nth: 0}, dx: -150, caption: "Absensi dibandingkan dengan papan tanda tangan; perbedaannya ditandai.", wait: 4000},
      {click: {text: "Tutup kelas", exact: true, role: "button"}, caption: "Hadir dan alpa memotong satu sesi voucher dalam satu transaksi.", wait: 5500},
      {caption: "Sesi berstatus selesai; menutup ulang tidak memotong voucher dua kali.", wait: 4000},

      {click: [66, 435], caption: "Tes simulasi dibuka guru di kelas.", wait: 3500},
      {click: "Buka sesi", wait: 1800},
      {click: {text: "Kode tes", role: "button"}, wait: 1500},
      {click: {text: TEST_CODE}, wait: 1500},
      {click: {text: "Buka", exact: true}, caption: "Sistem menerbitkan token enam karakter yang berlaku lima belas menit.", wait: 6000},
      {do: async ({shared, emu}) => {
        const open = (await emu.query("test_sessions")).filter((x) => x.codeId === TEST_CODE && x.status === "open")
            .sort((a, b) => String(a.createdAt).localeCompare(String(b.createdAt)));
        if (!open.length) throw new Error("no open test session");
        shared.token = open[open.length - 1].token;
      }, wait: 300},
    ]},

  // ------------------------------------------------------------------ Murid
  part(3, "Murid", "Pemesanan sesi, latihan, tes simulasi, leaderboard, voucher, dan progress"),
  {name: "murid", role: "Murid", as: `student1${D}`, start: "/?tab=0",
    before: async ({shared, emu}) => {
      // When this scene is filmed alone there is no token from the Guru scene yet.
      if (!shared.token) {
        const r = await emu.call(`teacher${D}`, "openTestSession", {codeId: TEST_CODE});
        shared.token = (await emu.query("test_sessions")).find((x) => x.id === r.sessionId).token;
      }
    },
    steps: [
      {caption: "Beranda murid: sisa sesi voucher dan sesi kelas empat belas hari ke depan.", wait: 5000},
      {click: {text: "Daftar", exact: true, nth: 0}, caption: "Murid memesan sesi; satu sesi voucher dicadangkan untuk pesanan itu.", wait: 4500},

      {go: "/student/exercise/pkg_typing", hidden: true, wait: 4000},
      {caption: "Latihan soal ketik yang ditugaskan guru.", wait: 3000},
      {click: [720, 393], wait: 500},
      {type: "我很喜欢和茶", caption: "Jawaban diketik dengan hanzi; di sini satu karakter sengaja keliru.", wait: 3200},
      {click: "Soal berikutnya", wait: 1800},
      {click: [720, 393], wait: 500},
      {type: "ni3 hao3", caption: "Pinyin boleh diketik dengan angka nada.", wait: 3000},
      {click: "Soal berikutnya", wait: 1800},
      {click: "把书", wait: 800},
      {click: "放在", wait: 800},
      {click: "桌子上", caption: "Soal menyusun kalimat dijawab dengan mengetuk kata secara berurutan.", wait: 3000},
      {click: "Kirim jawaban", wait: 3500},
      {caption: "Nilai dihitung di server; jawaban yang hampir benar bernilai setengah dan ditinjau guru.", wait: 6000},
      {scroll: 900, wait: 3000},

      {go: "/student", hidden: true, wait: 3000},
      {click: {text: "Tes", exact: true, role: "button"}, caption: "Tes simulasi hanya dapat dimulai dengan token dari guru.", wait: 3500},
      {click: [790, 187], wait: 500},
      {type: (shared) => shared.token, wait: 1500},
      {click: {text: "Masuk", exact: true}, wait: 3500},
      {click: "Mulai tes", caption: "Setiap bagian mempunyai batas waktu yang dihitung jam server.", wait: 4000, optional: true},
      {click: "图书馆", wait: 1800},
      {click: "Bagian berikutnya", wait: 1800},
      {click: {text: "Bagian berikutnya", exact: true, nth: 0}, caption: "Bagian yang sudah dikirim tidak dapat dibuka kembali.", wait: 3500},
      {click: "很", wait: 1800},
      {click: "Bagian berikutnya", wait: 1800},
      {click: {text: "Bagian berikutnya", exact: true, nth: 0}, wait: 3500},
      {click: [720, 366], wait: 500},
      {type: "刚", caption: "Bagian menulis: jawaban hanzi diketik.", wait: 2500},
      {click: "Soal berikutnya", wait: 2000},
      {click: [720, 380], wait: 500},
      {type: "周末我和朋友去公园散步，天气很好，我们都很高兴。", caption: "Soal menulis bebas dinilai oleh guru, bukan oleh sistem.", wait: 3000},
      {click: "Selesaikan tes", wait: 2000},
      {click: {text: "Selesaikan tes", exact: true, nth: 0}, wait: 4500, optional: true},
      {caption: "Kartu hasil: nilai per bagian; hasil akhir menunggu penilaian guru.", wait: 6500},

      {go: "/student/test-leaderboard/H3BOARD", hidden: true, wait: 4500},
      {caption: "Leaderboard kode tes memuat waktu selesai; murid lain tampil dengan nama Mandarin.", wait: 5500},
      {hover: "Bagikan hasil saya", caption: "Murid hanya dapat membagikan kartu hasilnya sendiri.", wait: 3500, optional: true},

      {go: "/student", hidden: true, wait: 3000},
      {click: {text: "Pembayaran", exact: true, role: "button"}, caption: "Voucher aktif dan riwayat tagihan murid.", wait: 4500},
      {click: "Beli voucher", caption: "Paket sesi dibeli dari daftar harga; pembayaran daring melalui Midtrans.", wait: 5500},
      {click: {text: "Tutup", exact: true, role: "button"}, wait: 1500, optional: true},

      {click: {text: "Kemajuan", exact: true, role: "button"}, caption: "Laporan progress: nilai latihan, kehadiran, voucher, dan peringatan.", wait: 5000},
      {scroll: 700, wait: 4000},
      {scroll: 900, wait: 4000},
    ]},

  // ------------------------------------------------------------------ Guru menilai
  part(4, "Guru", "Meninjau jawaban ketik dan menilai tulisan bebas"),
  {name: "guru2", role: "Guru", as: `teacher${D}`, start: "/", steps: [
    {go: "/teacher/tests/marking", hidden: true, wait: 4500},
    {caption: "Antrean penilaian: jawaban murid yang menunggu keputusan guru.", wait: 4500},
    {click: "beda satu karakter", caption: "Jawaban ketik yang beda satu karakter diperiksa guru.", wait: 4000},
    {click: "Tetap setengah", caption: "Guru memutuskan: nilai penuh, tetap setengah, atau nol.", wait: 4500},
    {click: "menulis bebas", caption: "Tulisan bebas dinilai dengan rubrik tata bahasa, kosakata, dan isi.", wait: 4000},
    {click: {text: "0", exact: true, role: "textbox", nth: 0}, dx: 540, wait: 1300},
    {click: {text: "0", exact: true, role: "textbox", nth: 0}, dx: 540, wait: 1300},
    {click: {text: "0", exact: true, role: "textbox", nth: 0}, dx: 470, wait: 2500},
    {click: "Simpan nilai", caption: "Setelah dinilai, hasil tes menjadi final dan murid diberi tahu.", wait: 6000},
  ]},

  card(6000, [
    {text: "Demonstrasi selesai", size: 64, bold: true, color: "green"},
    {text: " ", size: 24},
    {text: "Aplikasi berjalan pada Firebase Emulator Suite dengan data uji coba.", size: 32},
    {text: "Easy Study · 易华文教中心", size: 32, color: "grey"},
  ]),
];
