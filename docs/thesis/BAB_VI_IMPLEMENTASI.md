# BAB VI
# IMPLEMENTASI

Bab ini menguraikan hasil implementasi dari rancangan pada Bab V. Bagian
pertama, implementasi desain, memperlihatkan halaman-halaman aplikasi yang
sudah jadi, satu tangkapan layar dan satu paragraf untuk setiap halaman,
dikelompokkan menurut halaman umum, halaman admin, halaman guru, dan halaman
murid. Bagian kedua, implementasi program, memuat segmen program dari
bagian-bagian yang menentukan kebenaran sistem: inisialisasi aplikasi dan
pengalihan peran, aturan akses Firestore, penjadwalan dan pemesanan sesi,
penutupan sesi dan pemotongan voucher, penilaian latihan dan tes, kenaikan
tingkat, pembayaran Midtrans, laporan progress, dan pemutar latihan.

## 6.1 Implementasi Desain

Aplikasi dibangun dengan Flutter dan Firebase sesuai arsitektur pada Gambar
5.1. Versi web dipasang di Firebase Hosting pada alamat
https://chinese-tracker.web.app, versi Android dibagikan sebagai berkas APK
dari alamat yang sama, dan versi iOS dibangun dari basis kode yang sama
untuk App Store. Lingkungan implementasi dirangkum pada Tabel 6.1.
Tangkapan layar pada bab ini diambil dari aplikasi yang berjalan di Firebase
Emulator Suite dengan data uji coba (satu admin, empat guru, dan tiga puluh
murid), pada lebar layar 1280 piksel, dalam bahasa Indonesia dan tema
terang.

Tabel 6.1
Lingkungan Implementasi

| Komponen | Teknologi dan versi |
|---|---|
| Bahasa dan kerangka kerja aplikasi | Dart dan Flutter 3.44 (stable), satu basis kode untuk web, Android, dan iOS |
| Pustaka utama aplikasi | go_router 14 (navigasi), provider 6 (MVVM), fl_chart (grafik), intl 0.20 (tanggal dan bahasa), file_picker 10 dan pdfrx 2 (berkas dan PDF) |
| Backend | Firebase Authentication, Cloud Firestore, Cloud Storage, Firebase Cloud Messaging, Firebase App Check, Firebase Hosting |
| Logika server | Cloud Functions generasi kedua pada Node.js 22 (firebase-functions 7, firebase-admin 14), 74 fungsi; opencc-js untuk konversi aksara tradisional |
| Pembayaran | Midtrans Snap (sandbox selama pengembangan) dengan notifikasi HTTP ke Cloud Functions |
| Pembaca naskah dan transkrip | PaddleOCR PP-OCRv5 mobile melalui onnxruntime-web; Whisper small melalui transformers.js; keduanya berjalan di peramban admin |
| Pengujian | flutter test (174 pengujian), pengujian logika murni Node.js per modul, pengujian Firestore Security Rules pada emulator, GitHub Actions pada setiap push |
| Alat pengembangan | Visual Studio Code, Git dan GitHub, Firebase CLI dan Emulator Suite |

Antarmuka setiap peran mengikuti desain pada Bab V: halaman masuk dan
pendaftaran memakai warna merek pusat kursus (hijau dan kuning), sedangkan
halaman setelah masuk memakai permukaan putih yang tenang dengan bilah
navigasi di sisi kiri pada layar lebar dan di bawah pada layar ponsel. Semua
teks dibaca dari berkas terjemahan, sehingga pengguna dapat berpindah antara
bahasa Indonesia dan Inggris dari halaman masuk dan dari tab profil.

### 6.1.1 Halaman Umum

Halaman umum adalah halaman yang dapat dibuka tanpa masuk: halaman depan,
halaman masuk, halaman pendaftaran, halaman tunggu persetujuan, dan tes
penempatan untuk calon murid. Halaman depan pada Gambar 6.1 memperkenalkan
pusat kursus, tingkat HSK yang diajarkan, kelas, informasi untuk orang tua,
dan harga, dengan tombol WhatsApp dan tombol masuk serta daftar.

[GAMBAR 6.1: halaman depan]

Gambar 6.1
Halaman Depan

Halaman masuk pada Gambar 6.2 menerima email dan kata sandi, menyimpan akun
yang pernah masuk pada perangkat itu sebagai daftar pilihan, dan menyediakan
sakelar bahasa ID/EN. Akun yang dinonaktifkan admin ditolak di sini dan
langsung dikeluarkan.

[GAMBAR 6.2: halaman masuk]

Gambar 6.2
Halaman Masuk

Halaman pendaftaran pada Gambar 6.3 dipakai calon murid. Selain data diri,
calon murid memilih cara memulai: mulai dari HSK 1, memasukkan kode hasil tes
penempatan, atau memasukkan kode tautan guru bila sudah diberi oleh guru.
Akun yang dibuat berstatus menunggu sampai admin menyetujuinya. Formulir
yang sama dipakai orang tua yang mendaftar sebagai akun pendamping.

[GAMBAR 6.3: halaman pendaftaran murid]

Gambar 6.3
Halaman Pendaftaran Murid

Selama menunggu, murid hanya melihat halaman pada Gambar 6.4 yang
menampilkan pilihannya saat mendaftar dan tautan WhatsApp pusat kursus.
Begitu admin menyetujui, halaman ini membuka aplikasi dengan sendirinya;
bila ditolak, alasannya ditampilkan di tempat yang sama.

[GAMBAR 6.4: halaman tunggu persetujuan]

Gambar 6.4
Halaman Tunggu Persetujuan

Tes penempatan pada Gambar 6.5 dibuka dari halaman depan tanpa akun. Calon
murid mengisi token dari guru, nama, dan nomor WhatsApp, mengerjakan naskah
per bagian dengan batas waktu dari server, dan menerima kode hasil enam karakter yang dipakai
pada formulir pendaftaran. Kunci jawaban tidak pernah dikirim ke peramban,
dan data pengunjung dihapus setelah 180 hari.

[GAMBAR 6.5: tes penempatan untuk calon murid]

Gambar 6.5
Tes Penempatan untuk Calon Murid

### 6.1.2 Halaman Admin

Halaman admin terdiri atas dasbor, pengguna dan persetujuan, latihan, bank
soal, kelas dan jadwal, voucher dan daftar harga, pembayaran, laporan, tes,
dan berita. Dasbor pada Gambar 6.6 dibuka dengan kartu Hari ini yang memuat
hal-hal yang perlu ditindaklanjuti (pendaftaran menunggu, jadwal belum
dikonfirmasi, keterlambatan, sesi belum ditutup, murid perlu perhatian),
empat angka ringkas, grafik murid baru per bulan, berita terbaru, dan daftar
murid yang perlu perhatian dari laporan progress.

[GAMBAR 6.6: dashboard admin]

Gambar 6.6
Dasbor Admin

Halaman pengguna pada Gambar 6.7 memisahkan murid, guru, orang tua, dan
admin dengan chip, menyediakan pencarian, dan membuka profil setiap pengguna.
Admin membuat akun guru dari halaman ini karena guru tidak dapat mendaftar
sendiri.

[GAMBAR 6.7: daftar pengguna]

Gambar 6.7
Daftar Pengguna

Halaman persetujuan pada Gambar 6.8 memuat murid yang mendaftar sendiri.
Untuk setiap murid, admin menetapkan tingkat dan guru, dapat memakai kode
hasil tes penempatan yang diketik murid, lalu menyetujui atau menolak
dengan alasan. Keputusan dijalankan fungsi decideRegistration.

[GAMBAR 6.8: persetujuan pendaftaran]

Gambar 6.8
Persetujuan Pendaftaran

Profil murid pada Gambar 6.9 adalah kartu identitas dengan tab Ringkasan,
Kelas, Riwayat, dan Belajar. Admin melihat periode kelas berbayar, sisa sesi,
kunjungan yang sudah ditutup, dan pembayaran, serta membuka laporan progress
dan laporan PDF murid dari halaman ini.

[GAMBAR 6.9: profil murid di sisi admin]

Gambar 6.9
Profil Murid di Sisi Admin

Halaman latihan pada Gambar 6.10 memuat paket latihan yang disusun dari bank
soal. Admin melihat paket setiap guru, membuat paket baru, menugaskannya ke
murid, dan menghapus paket format lama yang tidak dapat dimainkan lagi.

[GAMBAR 6.10: daftar paket latihan]

Gambar 6.10
Daftar Paket Latihan

Bank soal pada Gambar 6.11 menyimpan lembar soal dan soal tunggal dengan
tipe soal, keterampilan, dan tingkat HSK. Dari sini admin memindai naskah
HSK dari PDF dengan pembaca naskah bawaan, menyunting lembar hasil
pembacaan, mengunggah rekaman menyimak, menulis transkripnya, dan mengisi
kunci jawaban bagian menyimak.

[GAMBAR 6.11: bank soal]

Gambar 6.11
Bank Soal

Daftar kode tes pada Gambar 6.12 memuat setiap kode dengan tingkat HSK,
tahun terbit naskah, lembar soal yang dipakai, dan lama pengerjaan. Sakelar
menyalakan atau mematikan kode, dan tombol hapus menghapus kode yang belum
pernah dipakai atau menyembunyikan kode yang sudah dipakai agar hasilnya
tetap ada. Halaman Tes yang memuat daftar ini juga membuka sesi tes, hasil
tes, antrean penilaian, verifikasi kenaikan tingkat, dan format tes.

[GAMBAR 6.12: daftar kode tes]

Gambar 6.12
Daftar Kode Tes

Jadwal mingguan pada Gambar 6.13 menampilkan kelas per ruang dan per hari
dalam seminggu. Jadwal baru disimpan melalui fungsi saveSchedule yang
menolak bentrok guru, ruang, dan jeda minimum, lalu membuat sesi empat belas
hari ke depan. Tab lain pada halaman ini memuat daftar jadwal, hari libur,
ketersediaan guru, tindak lanjut sesi, rekap guru, dan aturan jadwal.

[GAMBAR 6.13: jadwal mingguan]

Gambar 6.13
Jadwal Mingguan

Halaman kelas pada Gambar 6.14 menampilkan kalender bulanan dengan penanda
sesi dan, di bawahnya, sesi pada hari yang dipilih, baik yang dihasilkan
dari jadwal maupun sesi lepas yang dibuat guru, dengan status, jumlah
pemesan, ruang, dan guru. Dari sini admin menutup pusat kursus pada satu
hari atau membuat kelas baru pada hari itu, dan setiap kartu membuka
halaman kelas dengan daftar hadir dan tombol tutup.

[GAMBAR 6.14: daftar sesi kelas]

Gambar 6.14
Daftar Sesi Kelas

Halaman voucher pada Gambar 6.15 memuat periode kelas berbayar setiap murid
beserta sisa sesi, sesi yang dipesan, batas waktu, dan status. Voucher yang
belum dibayar ditandai, dan admin dapat memeriksa kecocokan buku besar
voucher dari pengaturan organisasi.

[GAMBAR 6.15: daftar voucher]

Gambar 6.15
Daftar Voucher

Daftar harga pada Gambar 6.16 menyimpan paket yang dapat dibeli: nama, nama
Tionghoa, harga, jumlah sesi, masa berlaku, dan apakah paket itu ditawarkan.
Harga pada tagihan selalu diambil dari daftar ini di server, bukan dari
aplikasi.

[GAMBAR 6.16: daftar harga]

Gambar 6.16
Daftar Harga

Halaman pembayaran pada Gambar 6.17 memuat tagihan dengan status menunggu,
lunas, kedaluwarsa, gagal, atau dibatalkan. Admin mencatat pembayaran tunai
dan transfer di sini (markInvoicePaid), sedangkan pembayaran Midtrans
tercatat sendiri melalui notifikasi. Tagihan dapat dibatalkan dengan alasan
dan dipulihkan kembali.

[GAMBAR 6.17: daftar tagihan dan pembayaran]

Gambar 6.17
Daftar Tagihan dan Pembayaran

Verifikasi kenaikan tingkat pada Gambar 6.18 memuat aturan jumlah kode
yang disyaratkan (tiga kode berbeda pada tingkat murid, dapat diubah),
checklist per tingkat yang menggantikan hitungan kode bila diisi, tombol
untuk menaikkan murid yang sudah mampu secara langsung, dan di bawahnya
rekomendasi yang ditulis fungsi ketika seorang murid memenuhi syarat itu.
Admin menyetujui, sehingga tingkat murid naik dan riwayatnya tercatat, atau
menolak dengan alasan.

[GAMBAR 6.18: verifikasi kenaikan tingkat]

Gambar 6.18
Verifikasi Kenaikan Tingkat

Laporan pada Gambar 6.19 menampilkan rekap bulanan yang ditulis fungsi
terjadwal monthlyReport dan dapat dihitung ulang oleh admin: murid baru,
pendapatan dari tagihan lunas, murid aktif, kehadiran, jam mengajar, dan
jumlah murid per tingkat HSK, dengan ekspor CSV dan PDF. Di bawahnya
tersedia laporan PDF enam bulan per topik: absensi per murid, murid baru dan
retensi, kemajuan per tingkat, tugas terlambat, keterisian kelas, dan rekap
guru.

[GAMBAR 6.19: laporan bulanan]

Gambar 6.19
Laporan Bulanan

Halaman berita pada Gambar 6.20 dipakai admin untuk menulis pengumuman yang
muncul di beranda murid, orang tua, dan guru. Formulirnya meminta judul dan
isi pesan, siapa yang melihat (semua, murid dan orang tua, atau guru),
tanggal akhir yang boleh kosong, dan pilihan membunyikan lonceng notifikasi
melalui trigger onAnnouncementCreated. Penutupan hari libur dari halaman
jadwal juga menghasilkan satu pengumuman di sini.

[GAMBAR 6.20: pengumuman]

Gambar 6.20
Pengumuman

### 6.1.3 Halaman Guru

Halaman guru terdiri atas dasbor, murid, latihan, kelas dan jadwal
mengajar, nilai, tes, dan profil. Dasbor pada Gambar 6.21 menampilkan kelas
hari ini, murid yang perlu perhatian dari laporan progress, antrean
penilaian yang menunggu, dan pengumuman.

[GAMBAR 6.21: dashboard guru]

Gambar 6.21
Dasbor Guru

Jadwal mengajar pada Gambar 6.22 adalah satu layar dengan tab Hari ini,
Minggu ini, dan Kalender. Pada hari mengajar, guru melihat setiap sesi
beserta pemesannya; sesi dimulai sendiri pada jam mulainya, dan check-in
guru hanya mencatat kedatangan dan keterlambatan bila sakelar kesiapan guru
dinyalakan admin.

[GAMBAR 6.22: jadwal mengajar guru]

Gambar 6.22
Jadwal Mengajar Guru

Halaman sesi pada Gambar 6.23 adalah tempat guru menjalankan kelas: daftar
pemesan dan murid yang ditambahkan, status kehadiran hadir, izin, atau alpa,
perbandingan dengan papan absensi kertas, dan tombol tutup sesi. Penutupan
memanggil fungsi closeSession yang memotong voucher dalam satu transaksi
(Segmen Program 6.7).

[GAMBAR 6.23: halaman sesi dan absensi]

Gambar 6.23
Halaman Sesi dan Absensi

Halaman latihan guru pada Gambar 6.24 memuat paket milik guru itu sendiri.
Guru menyusun paket dari lembar bank soal dan soal tunggal, termasuk soal
yang diketik atau ditempelnya sendiri, menerbitkannya, dan menugaskannya ke
murid-muridnya; pemindaian naskah tetap menjadi tugas admin.

[GAMBAR 6.24: paket latihan guru]

Gambar 6.24
Paket Latihan Guru

Halaman tes di sisi guru pada Gambar 6.25 memuat sesi tes yang sedang
terbuka dan tombol menuju buka sesi, hasil tes, dan penilaian. Guru membuka
sesi dengan kode tes, memilih apakah sesi itu sesi penempatan, dan
membagikan token kepada murid di ruangan.

[GAMBAR 6.25: tes di sisi guru]

Gambar 6.25
Tes di Sisi Guru

Pengawasan sesi tes pada Gambar 6.26 menampilkan token yang harus diketik
murid, daftar murid yang sudah bergabung beserta bagian yang sedang
dikerjakan, dan tombol untuk memutar rekaman menyimak serta menutup sesi.
Sesi yang lupa ditutup ditutup fungsi terjadwal setiap jam.

[GAMBAR 6.26: pengawasan sesi tes]

Gambar 6.26
Pengawasan Sesi Tes

Antrean penilaian pada Gambar 6.27 memuat jawaban yang menunggu guru:
jawaban ketik yang hanya meleset satu aksara atau satu nada (setengah nilai,
ditandai) dan tulisan bebas yang bernilai sepuluh poin. Guru memberi poin
dengan rubrik, dan hasil murid yang masih menunggu berubah menjadi final
melalui fungsi markAnswer.

[GAMBAR 6.27: antrean penilaian]

Gambar 6.27
Antrean Penilaian

Laporan progress murid di sisi guru pada Gambar 6.28 memakai widget yang
sama dengan tab Progress murid: tingkat dan hitungan kode menuju kenaikan,
nilai latihan per minggu, keterampilan, riwayat tes, kehadiran, voucher, dan
peringatan. Guru menulis catatan tindak lanjut untuk murid bimbingannya di
bawah laporan.

[GAMBAR 6.28: laporan progress murid di sisi guru]

Gambar 6.28
Laporan Progress Murid di Sisi Guru

### 6.1.4 Halaman Murid

Halaman murid terdiri atas beranda, riwayat, pelajaran, kemajuan, tes,
pembayaran, dan profil. Beranda pada Gambar 6.29 menampilkan sisa sesi,
latihan yang sudah dikerjakan, nilai rata-rata, pintasan ke kalender, nilai,
materi, dan riwayat, pengumuman, serta daftar sesi kelas empat belas hari ke
depan dengan jumlah kursi dan tombol Daftar. Pemesanan dijalankan fungsi
bookSession dengan urutan pemeriksaan pada Algoritma 5.2; kelas yang penuh
menawarkan daftar tunggu, dan murid yang terlambat masih dapat mendaftar
sampai kelas berakhir.

[GAMBAR 6.29: beranda murid dan pemesanan sesi]

Gambar 6.29
Beranda Murid dan Pemesanan Sesi

Halaman riwayat pada Gambar 6.30 memperlihatkan voucher murid dengan sesi
yang sudah terpakai dari jumlah paketnya dan kelas yang dipotong dari voucher
itu, lalu semua kelas yang pernah dan akan diikuti, dikelompokkan per bulan
dengan status kehadirannya.

[GAMBAR 6.30: riwayat kelas dan voucher murid]

Gambar 6.30
Riwayat Kelas dan Voucher Murid

Halaman kelas pada Gambar 6.31 menampilkan satu sesi yang dipesan murid:
tanggal, jam, guru, jumlah murid yang bergabung dan sisa tempat, daftar
teman sekelas, dan tombol keluar dari kelas yang berlaku sampai kelas
dimulai. Sesi dari voucher dikembalikan ketika pemesanan dibatalkan.

[GAMBAR 6.31: halaman kelas yang dipesan]

Gambar 6.31
Halaman Kelas yang Dipesan

Daftar latihan pada Gambar 6.32 hanya memuat paket yang ditugaskan kepada
murid itu, dengan tipe latihan, batas waktu bila ada, dan nilai terakhir.
Paket ujian satu kali ditandai dan menampilkan layar mulai sebelum
jam server dihidupkan.

[GAMBAR 6.32: daftar latihan murid]

Gambar 6.32
Daftar Latihan Murid

Pemutar latihan pada Gambar 6.33 menampilkan soal satu per satu, termasuk
soal ketik hanzi dan pinyin dengan tombol nada, soal urutan kata yang
dijawab dengan mengetuk kata, dan soal menyimak dengan rekaman. Murid
menjawab semua soal lalu menekan Kumpulkan satu kali; jawaban dinilai di
server dan ulasan beserta pembahasan dikirim kembali (Segmen Program 6.17).

[GAMBAR 6.33: pemutar latihan (soal ketik)]

Gambar 6.33
Pemutar Latihan dengan Soal Ketik

Halaman tes pada Gambar 6.34 meminta token dari guru pengawas. Setelah
token diterima, murid mengerjakan naskah per bagian dengan jam dari server,
dan hasil ditampilkan sebagai kartu nilai bergaya HSK dengan nilai menyimak,
membaca, dan menulis dari 100 serta keterangan lulus pada 60 persen.

[GAMBAR 6.34: tes memasukkan token]

Gambar 6.34
Halaman Tes dan Masukan Token

Leaderboard pada Gambar 6.35 memuat peringkat murid pada satu kode tes,
diurutkan menurut nilai total lalu waktu pengerjaan, dan terbuka bagi
seorang murid setelah ia sendiri mengerjakan kode itu. Murid melihat teman
sekelasnya dengan nama Tionghoa saja; hasil sesi penempatan tidak masuk
papan.

[GAMBAR 6.35: leaderboard kode tes]

Gambar 6.35
Leaderboard Kode Tes

Halaman pembayaran murid pada Gambar 6.36 memuat voucher aktif dengan sisa
sesi dan batas waktu, riwayat buku besar voucher, tagihan, dan tombol Beli
yang membuka lembar pembelian dari daftar harga dengan syarat yang harus
dicentang. Pembayaran berlangsung di halaman Midtrans Snap; sesi dikreditkan
begitu notifikasi lunas diterima server.

[GAMBAR 6.36: voucher dan pembayaran murid]

Gambar 6.36
Voucher dan Pembayaran Murid

Laporan progress murid pada Gambar 6.37 adalah tampilan yang sama dengan
yang dilihat guru dan orang tua: ringkasan tingkat, grafik nilai latihan
per minggu (Segmen Program 6.16), keterampilan, riwayat tes, kehadiran,
voucher, peringatan, dan catatan guru terakhir. Tombol cetak menghasilkan
laporan PDF dari ringkasan yang sama.

[GAMBAR 6.37: laporan progress murid]

Gambar 6.37
Laporan Progress Murid

## 6.2 Implementasi Program

Kode aplikasi disusun seperti pada Tabel 6.2. Logika yang menentukan uang,
nilai, dan tingkat berada di Cloud Functions; modul logika murni (misalnya
scheduling.js, typing_matcher.js, promotion.js, payments.js, progress.js)
tidak menyentuh Firebase sehingga dapat diuji dengan node tanpa emulator,
sedangkan index.js membaca dan menulis dokumen. Segmen program pada bagian
ini dikutip dari kode yang berjalan di produksi per 24 November 2026; baris
yang tidak menentukan alur diringkas dengan tanda `// ...`.

Tabel 6.2
Susunan Kode Sumber

| Folder atau berkas | Isi |
|---|---|
| lib/main.dart, lib/app.dart | Inisialisasi Firebase, penyedia layanan (Provider), tema, bahasa |
| lib/core/router/app_router.dart | Rute go_router dan pengalihan menurut peran dan status akun |
| lib/features/ | Halaman per fitur: landing, auth, admin, teacher, student, parent, exercises, question_bank, tests, progress, announcements |
| lib/services/ | Lapisan yang berbicara dengan Firebase: AuthService, FirestoreService, ExercisePlayService, PaymentService, WorksheetImportService, dan lainnya |
| lib/models/ | Model data: AppUser, Exercise, QuestionBankItem, ClassSession, ClassTerm, Invoice, dan lainnya |
| lib/l10n/ | Berkas terjemahan app_en.arb dan app_id.arb (sekitar 1.380 kunci) |
| functions/index.js | 74 Cloud Functions: callable, trigger Firestore, terjadwal, dan HTTP |
| functions/*.js lainnya | Modul logika murni dan pengujiannya (test_*.js) |
| firestore.rules, storage.rules | Aturan akses Firestore dan Cloud Storage beserta pengujiannya di rules-tests/ |
| web/paper_ocr_paddle.js, web/transcribe_whisper.js | Pembaca naskah dan penulis transkrip di peramban |
| scripts/, tool/ | Skrip deploy, seed emulator, pengukuran pembaca naskah, perangkat uji coba |

### 6.2.1 Inisialisasi Aplikasi dan Pengalihan Peran

Segmen Program 6.1 adalah fungsi main aplikasi. Strategi alamat web tanpa
tanda pagar dipasang lebih dulu agar tautan dalam dan refresh halaman
bekerja di Hosting, kemudian Firebase diinisialisasi dengan konfigurasi
proyek, App Check diaktifkan bila kunci situs tersedia, dan pada build
emulator aplikasi dihubungkan ke emulator lokal sebelum widget pertama
ditampilkan.

Segmen Program 6.1
Inisialisasi Aplikasi dan Firebase
01: Future<void> main() async {
02:   await runZonedGuarded(() async {
03:     usePathUrlStrategy();
04:     LaunchParams.capture(Uri.base);
05:     WidgetsFlutterBinding.ensureInitialized();
06:     // ... (FlutterError.onError dan PlatformDispatcher.onError)
07:     await pdfrxFlutterInitialize();
08:     await initializeDateFormatting('id');
09:     await Firebase.initializeApp(
10:       options: DefaultFirebaseOptions.currentPlatform,
11:     );
12:     await _activateAppCheck();
13:     if (BuildFlags.useEmulators) {
14:       await _connectToEmulators();
15:       // ... (berhenti bila Auth tidak terhubung ke emulator)
16:     }
17:     runApp(const ChineseTrackerApp());
18:   }, (error, stack) {
19:     if (kDebugMode) {
20:       debugPrint('Zone error: $error\n$stack');
21:     }
22:   });
23: }

Seluruh pemanggilan Firebase dibungkus runZonedGuarded sehingga kesalahan
asinkron tidak menghentikan aplikasi. Setelah main, widget ChineseTrackerApp
membuat satu instance setiap layanan (AuthService, FirestoreService,
PaymentService, dan lainnya) dan menyediakannya ke seluruh pohon widget
melalui Provider, sesuai pola MVVM pada Bab V.

Pengalihan halaman ditangani fungsi redirect pada go_router (Segmen Program
6.2). Fungsi ini dijalankan pada setiap perubahan rute dan setiap kali
AuthService memberi tahu perubahan keadaan masuk, sehingga satu tempat
menentukan halaman mana yang boleh dibuka oleh siapa.

Segmen Program 6.2
Pengalihan Halaman Menurut Peran dan Status Akun
01: redirect: (context, state) {
02:   final location = state.matchedLocation;
03:   // ... (menunggu profil dimuat pada /splash)
04:   final signedIn = auth.firebaseUser != null;
05:   final hasProfile = auth.appUser != null;
06:   final onPublic = location == '/' || location == '/login' ||
07:       location == '/register' || location == '/splash';
08:   final onComplete = location == '/complete-profile';
09:   if (location == '/privacy') return null;
10:   final onWaiting = location == '/waiting';
11:   if (!signedIn && !onPublic) return '/';
12:   if (signedIn && hasProfile) {
13:     final user = auth.appUser!;
14:     if (user.awaitsApproval) return onWaiting ? null : '/waiting';
15:     String homeFor(dynamic u) {
16:       if (u.isAdmin) return '/admin';
17:       if (u.isTeacher) return '/teacher';
18:       if (u.isParent) return '/parent';
19:       return '/student';
20:     }
21:     final home = homeFor(user);
22:     final inOtherSection = (location.startsWith('/admin') ||
23:             location.startsWith('/teacher') ||
24:             location.startsWith('/student') ||
25:             location.startsWith('/parent')) && !location.startsWith(home);
26:     if (inOtherSection) return home;
27:     if (onPublic || onComplete || onWaiting) return home;
28:   }
29:   return null;
30: },

Pengguna yang belum masuk hanya dapat membuka halaman umum; pengguna yang
sudah masuk tetapi berstatus menunggu persetujuan hanya dapat membuka
/waiting; dan setiap peran dikunci pada bagiannya sendiri, sehingga seorang
murid yang mengetik alamat /admin dikembalikan ke /student. Rute tes
penempatan dan kebijakan privasi dikecualikan karena harus dapat dibuka
siapa saja.

### 6.2.2 Aturan Akses Firestore

Pengalihan pada aplikasi hanya kenyamanan; penjaga yang sebenarnya adalah
Firestore Security Rules, karena aplikasi dapat dilewati oleh siapa pun yang
memanggil Firestore langsung. Segmen Program 6.3 memperlihatkan fungsi
isAdmin, yang membaca dokumen pengguna pemanggil dan menolak akun yang
dinonaktifkan, serta tiga koleksi yang mewakili pola aturan sistem.

Segmen Program 6.3
Aturan Akses exercise_results, schedules, dan voucher_history
01: function isAdmin() {
02:   return isSignedIn() &&
03:     hasUserProfile() &&
04:     isActive() &&
05:     userDoc().data.get('role', '') == 'admin';
06: }
07: match /schedules/{scheduleId} {
08:   allow read: if isApprovedUser();
09:   allow write: if false;
10: }
11: match /exercise_results/{resultId} {
12:   allow read: if isApprovedUser() && (
13:     resource == null ||
14:     resource.data.studentId == request.auth.uid ||
15:     isStaff() ||
16:     isParentOf(resource.data.get('studentId', ''))
17:   );
18: }
19: match /voucher_history/{entryId} {
20:   allow read: if isApprovedUser() && (
21:     isStaff() ||
22:     resource.data.get('studentId', '') == request.auth.uid ||
23:     isParentOf(resource.data.get('studentId', ''))
24:   );
25:   allow write: if false;
26: }

Koleksi schedules dan voucher_history sama sekali tidak dapat ditulis dari
aplikasi (allow write: if false), sehingga satu-satunya jalan menulis jadwal
adalah fungsi saveSchedule yang menjalankan pengecekan bentrok, dan
satu-satunya jalan menambah buku besar voucher adalah fungsi closeSession.
Koleksi exercise_results tidak memiliki aturan tulis sama sekali, sehingga
nilai hanya dapat ditulis oleh fungsi finishExercise dengan Admin SDK; murid
hanya membaca hasilnya sendiri, staf membaca semua, dan orang tua membaca
hasil anaknya. Aturan-aturan ini diuji dengan 86 pengujian pada emulator
(rules-tests), yang dijalankan pula oleh GitHub Actions pada setiap push.

### 6.2.3 Penjadwalan dan Pemesanan Sesi

Pengecekan bentrok dari Algoritma 5.1 diimplementasikan sebagai dua fungsi
murni pada scheduling.js (Segmen Program 6.4). Fungsi overlaps memeriksa dua
rentang waktu pada hari yang sama dengan jeda minimum, dan conflicts
mengumpulkan setiap alasan bentrok beserta nama kelas yang bentrok agar
admin tahu apa yang harus diubah.

Segmen Program 6.4
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
18:   for (const o of (ctx.roomSchedules || []).filter(live)) {
19:     if (o.weekday === s.weekday && periodsOverlap(o, s) && overlaps(o, s, gap)) {
20:       out.push({code: "room", text: `${s.room} is taken by ${o.className} on ${day} ` +
21:         `${clock(o.startMinutes)}–${clock(o.endMinutes)}${gapNote(o)}.`});
22:     }
23:   }
24:   // ... (sesi lepas guru dan ruang diperiksa dengan cara yang sama)
25:   return out;
26: }

Jadwal yang sedang disunting dikecualikan dari daftar lawannya (x.id !==
s.id), dan jadwal yang periodenya tidak beririsan tidak dianggap bentrok,
sehingga dua kelas pada jam yang sama boleh ada bila periodenya berurutan.
Karena kedua fungsi tidak menyentuh basis data, kasus-kasusnya diuji dengan
node functions/test_scheduling.js.

Segmen Program 6.5 memperlihatkan bagaimana fungsi conflicts dipakai di
dalam fungsi saveSchedule. Pengecekan dan penyimpanan terjadi dalam satu
transaksi Firestore yang membaca dokumen kunci per guru dan per ruang pada
koleksi schedule_locks; karena transaksi Firestore gagal bila dokumen yang
dibacanya berubah, dua admin yang menyimpan jadwal untuk guru yang sama pada
saat yang sama tidak dapat sama-sama lolos.

Segmen Program 6.5
Fungsi saveSchedule dengan Transaksi dan schedule_locks
01: exports.saveSchedule = onCall(async (request) => {
02:   const {uid, profile} = await requireAdmin(request);
03:   const settings = await schedulingSettings();
04:   const s = scheduleFromInput(request.data || {}, settings);
05:   const ref = s.id ? db.collection(SCHEDULES).doc(s.id) : db.collection(SCHEDULES).doc();
06:   const out = await db.runTransaction(async (tx) => {
07:     const lockRefs = [...(sched.teachersOf(s).length ? sched.teachersOf(s) : ["none"]),
08:       `room_${s.room.replace(/\//g, "_") || "none"}`]
09:         .map((k) => db.collection(SCHEDULE_LOCKS).doc(k));
10:     const locks = [];
11:     for (const r of lockRefs) locks.push(await tx.get(r));
12:     const {teacher, ctx, helpers} = await scheduleContext({...s, id: ref.id}, settings,
13:         (q) => tx.get(q));
14:     const result = checkResult({...s, id: ref.id}, teacher, ctx, settings, helpers);
15:     if (!result.ok) return result;
16:     lockRefs.forEach((r, k) => tx.set(r, {
17:       version: (Number((locks[k].data() || {}).version) || 0) + 1,
18:       updatedAt: FieldValue.serverTimestamp()}));
19:     // ... (tx.set(ref, ...) menyimpan jadwal beserta nama guru dan statusnya)
20:     return {...result, scheduleId: ref.id};
21:   });
22:   if (!out.ok) {
23:     throw new HttpsError("failed-precondition", out.reasons.map((r) => r.text).join(" "),
24:         {reason: "conflict", reasons: out.reasons, suggestions: out.suggestions});
25:   }
26:   // ... (catatan audit; generateSessionsNow membuat sesi 14 hari ke depan)
27:   return {ok: true, scheduleId: out.scheduleId, warnings: out.warnings, ...generated, cancelled};
28: });

Bila ada bentrok, fungsi melempar kesalahan failed-precondition dengan
daftar alasan dan usulan jam kosong (suggestFreeSlots), yang ditampilkan
aplikasi di dalam formulir jadwal. Bila lolos, versi setiap kunci dinaikkan,
jadwal disimpan, catatan audit ditulis, dan sesi empat belas hari ke depan
dibuat dengan id tetap scheduleId_yyyyMMdd sehingga pemanggilan ulang tidak
menggandakan sesi.

Pemesanan sesi oleh murid (Algoritma 5.2) berpusat pada fungsi murni
bookingRefusal (Segmen Program 6.6), yang mengembalikan alasan penolakan
atau null bila pemesanan boleh dilakukan. Fungsi bookSession memanggilnya di
dalam transaksi bookSessionTx setelah memastikan pemanggil adalah murid itu
sendiri atau orang tua yang tertaut.

Segmen Program 6.6
Fungsi bookingRefusal
01: function bookingRefusal(session, term, booked, nowMs, opts = {}) {
02:   const st = session.status || "scheduled";
03:   if (st === "needs_teacher") return "needs_teacher";
04:   if ((st !== "scheduled" && st !== "ongoing") || session.isConcluded === true) return "closed";
05:   if (startMs(session.sessionDate, session.endMinutes) <= nowMs) return "too_late";
06:   if (session.level && opts.studentLevel && session.level !== opts.studentLevel) return "level";
07:   if ((Number(session.bookedCount) || 0) >= (Number(session.capacity) || 0)) return "full";
08:   if (!term) return "no_sessions";
09:   const today = jakartaDate(nowMs);
10:   if (term.status === "expired" || (term.deadlineDate && term.deadlineDate < session.sessionDate) ||
11:       (term.deadlineDate && term.deadlineDate < today)) {
12:     return "expired";
13:   }
14:   if ((Number(term.sessionsRemaining) || 0) - (Number(term.sessionsBooked) || 0) <= 0) {
15:     return "no_sessions";
16:   }
17:   for (const b of booked || []) {
18:     if (b.sessionDate === session.sessionDate && overlaps(b, session, 0)) return "overlap";
19:   }
20:   return null;
21: }

Urutan pemeriksaannya mengikuti Algoritma 5.2: keadaan sesi, batas waktu
pemesanan (sampai kelas berakhir, sesuai permintaan pemilik), tingkat,
kursi, voucher aktif dan batas waktunya, sisa sesi yang dapat dipesan dari
Rumus 5.1, dan bentrok dengan pemesanan murid itu pada hari yang sama. Bila
lolos, transaksi menaikkan bookedCount sesi, menaikkan sessionsBooked
voucher, dan menulis dokumen attendance dengan id sessionId_studentId.

### 6.2.4 Penutupan Sesi dan Voucher

Pemotongan voucher yang konsisten adalah syarat dari pembimbing kedua, dan
diimplementasikan di dalam fungsi closeSession. Segmen Program 6.7 memuat
inti transaksinya: status kehadiran setiap murid ditentukan, pengaruhnya
pada voucher dihitung (closeEffect: hadir dan alpa memakai satu sesi, izin
tidak), buku besar ditulis dengan id tetap, dan sesi ditandai selesai.

Segmen Program 6.7
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
14:     const entry = terms[termId];
15:     const usable = Boolean(entry) && (eff.used === 0 ||
16:       (Number(entry.t.sessionsRemaining) || 0) + eff.remaining >= 0);
17:     // ... (sessionsBooked, sessionsUsed, sessionsRemaining voucher dihitung ulang)
18:     const charged = usable && eff.used > 0;
19:     tx.set(db.collection(VOUCHER_HISTORY).doc(`${ref.id}_${a.studentId}`), {
20:       kind: "session", studentId: a.studentId, termId: usable ? termId : "",
21:       sessionId: ref.id, sessionDate: s.sessionDate || "", status: st,
22:       sessions: charged ? eff.delta : 0, date: FieldValue.serverTimestamp(),
23:     });
24:     tx.update(aRef, {attendanceStatus: st, sessionCredited: charged, closed: true});
25:   }
26:   // ... (tx.update setiap voucher; status "depleted" bila sisa 0)
27:   tx.update(ref, {status: "done", isConcluded: true, isOpen: false,
28:     concludedAt: FieldValue.serverTimestamp()});
29:   // ... (tx.set rekap guru bulan itu: held, hours, students)
30:   return {status: "done", credited, excused, failed};
31: });

Tiga hal menjamin konsistensinya. Pertama, seluruh pembacaan dan penulisan
berada dalam satu transaksi, sehingga penutupan yang berbarengan dengan
pemesanan atau pembatalan pada voucher yang sama akan diulang Firestore
sampai salah satunya melihat data yang mutakhir. Kedua, dokumen buku besar
memakai id sessionId_studentId dan sesi yang sudah berstatus done langsung
dikembalikan tanpa perubahan, sehingga pemanggilan kedua (tombol ditekan
dua kali, koneksi putus) tidak memotong voucher dua kali. Ketiga, voucher
yang tidak cukup sisanya tidak dipotong melainkan dilaporkan pada failed,
agar admin menindaklanjutinya dari dasbor. Tombol Voucher check pada
pengaturan organisasi (reconcileVouchers) menghitung ulang setiap voucher
dari buku besarnya untuk memastikan keduanya tetap cocok.

### 6.2.5 Penilaian Latihan dan Tes

Pencocokan jawaban ketik dari Algoritma 5.4 berada pada modul
typing_matcher.js (Segmen Program 6.8). Jawaban dan kunci dinormalkan dengan
cara yang sama: karakter lebar penuh menjadi lebar setengah, tanda baca
Tionghoa menjadi ASCII, spasi dan tanda baca akhir dibuang, lalu aksara
tradisional diubah ke sederhana dengan opencc-js. Jarak Levenshtein antara
jawaban dan setiap kunci menentukan nilainya.

Segmen Program 6.8
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

Jarak nol terhadap salah satu kunci berarti nilai penuh; jarak satu dengan
kemiripan S = 1 − d/n paling sedikit 0,75 (Rumus 2.1) berarti setengah
nilai dan ditandai untuk dilihat guru; selain itu nol. Fungsi matchPinyin
bekerja serupa pada suku kata: huruf yang sama dengan nada yang salah
menghasilkan setengah nilai, dan kunci yang ditulis tanpa nada dibandingkan
pada hurufnya saja. Soal dengan beberapa rumpang memanggil matchHanzi untuk
setiap rumpang dan mendapat bagian rumpang yang benar. Keduanya diuji dengan
node functions/test_typing_matcher.js dan diukur dengan 200 jawaban uji pada
Bab VII.

Penilaian satu paket latihan dilakukan fungsi finishExercise (Segmen
Program 6.9), yang dipanggil aplikasi satu kali setelah murid menjawab
semua soal. Fungsi memuat paket yang memang ditugaskan kepada murid itu
beserta kunci jawabannya dari bank soal, menilai seluruh jawaban dengan
play.scoreAttempt, dan menulis hasilnya; untuk paket ujian satu kali,
dokumen exercise_attempts ditutup di dalam transaksi agar pengumpulan kedua
ditolak dan keterlambatan dihitung dari jam server.

Segmen Program 6.9
Fungsi finishExercise
01: exports.finishExercise = onCall(async (request) => {
02:   const {uid, profile} = await requireCaller(request);
03:   const data = request.data || {};
04:   const exerciseId = String(data.exerciseId || "").trim();
05:   const exercise = await loadAssignedPackage(exerciseId, uid);
06:   const items = await loadPackageItems(exercise);
07:   const answers = data.answers && typeof data.answers === "object" ? data.answers : {};
08:   const category = play.packageCategory(items);
09:   const oneAttempt = play.isOneAttempt(category);
10:   const limitSeconds = timeLimitSeconds(exercise);
11:   let late = false;
12:   if (oneAttempt) {
13:     const attemptRef = db.collection(EXERCISE_ATTEMPTS).doc(`${exerciseId}_${uid}`);
14:     await db.runTransaction(async (tx) => {
15:       const snap = await tx.get(attemptRef);
16:       // ... (ditolak bila belum dimulai atau sudah pernah dikumpulkan)
17:       late = isLate(snap.data() || {}, limitSeconds);
18:       tx.update(attemptRef, {finishedAt: FieldValue.serverTimestamp(), ...(late ? {late: true} : {})});
19:     });
20:   }
21:   const scored = play.scoreAttempt(items, answers);
22:   // ... (jawaban yang terlambat dinilai 0; ulasan tetap dikembalikan)
23:   const status = result.open > 0 ? "pending_marking" : "final";
24:   // ... (hasil ditulis ke exercise_results; jawaban terbuka ke marking_items)
25:   return {...result, late, status, resultId: resultRef.id};
26: });

Hasil yang masih memiliki jawaban terbuka (tulisan bebas, atau jawaban
ketik yang ditandai) berstatus pending_marking tanpa lulus atau gagal
sampai guru menilainya melalui markAnswer. Jawaban yang dikembalikan ke
aplikasi memuat ulasan per soal beserta kunci dan pembahasan, sehingga kunci
hanya meninggalkan server setelah jawaban diterima. Tes simulasi HSK memakai
jalur terpisah (submitTestPart) dengan nilai per bagian dari Rumus 5.2 dan
Algoritma 5.5.

### 6.2.6 Kenaikan Tingkat

Hitungan menuju kenaikan tingkat (Algoritma 5.6) diimplementasikan pada
promotion.js (Segmen Program 6.10). Fungsi countsAt menyaring hasil yang
dihitung: final, sah, lulus, kode HSK pada tingkat murid saat ini, bukan
sesi penempatan, dan kodenya memang dihitung untuk kenaikan. Fungsi
promotionState menghitung kode yang berbeda yang sudah dilulusi.

Segmen Program 6.10
Fungsi countsAt dan promotionState
01: function countsAt(result, code, levelKey) {
02:   const c = code || {};
03:   if (!result || !isFinal(result) || !isValid(result) || result.passed !== true) return false;
04:   if (isPlacement(result, c)) return false;
05:   if (c.countsForPromotion === false) return false;
06:   const family = String(result.family || c.family || "hsk").toLowerCase();
07:   if (family !== "hsk") return false;
08:   const key = levelKeyOf(result.levelKey || c.levelKey || result.level || c.level);
09:   return key !== "" && key === String(levelKey);
10: }
11: function promotionState(rows, levelKey, minCodes = DEFAULT_MIN_CODES) {
12:   const min = Number(minCodes) >= 1 ? Math.floor(Number(minCodes)) : DEFAULT_MIN_CODES;
13:   const codes = [];
14:   for (const {result, code} of rows || []) {
15:     if (!countsAt(result, code, levelKey)) continue;
16:     const id = String(result.codeId || "");
17:     if (id && !codes.includes(id)) codes.push(id);
18:   }
19:   codes.sort();
20:   const next = nextLevelKey(levelKey);
21:   return {levelKey: String(levelKey || ""), next, codes, count: codes.length,
22:     minCodes: min, reached: next !== null && levelKey !== "" && codes.length >= min};
23: }

Kedua fungsi dipanggil trigger onTestResultWritten setiap kali dokumen
test_results ditulis. Trigger itu memperbarui entri leaderboard kode
tersebut, menulis promotion_progress murid, dan bila reached bernilai benar
membuat dokumen level_promotions/{uid}_{levelKey} berstatus waiting untuk
admin. Mengulang kode yang sama tidak menambah hitungan karena kode
dihimpun sebagai himpunan; tingkat yang memiliki checklist (level_paths)
memakai pathProgress sebagai ganti hitungan ini. Keputusan admin
(decidePromotion) menaikkan users.level, menulis level_history, dan mengatur
ulang hitungan pada tingkat baru.

### 6.2.7 Pembayaran Midtrans

Pembelian voucher dimulai dari fungsi createInvoice (Segmen Program 6.11).
Fungsi menentukan siapa yang boleh membeli untuk murid tersebut (murid itu
sendiri, orang tua yang tertaut, atau staf), mewajibkan persetujuan syarat
pada pembelian mandiri, dan mengambil harga dari daftar harga di server
tanpa memercayai jumlah yang dikirim aplikasi.

Segmen Program 6.11
Fungsi createInvoice: Pemeriksaan Pembeli dan Harga dari Server
01: exports.createInvoice = onCall({secrets: [MIDTRANS_SERVER_KEY]}, async (request) => {
02:   const auth = request.auth;
03:   if (!auth) throw new HttpsError("unauthenticated", "Sign in to create invoices.");
04:   const {profile: caller} = await requireCaller(request);
05:   const callerRole = (caller && caller.role) || "";
06:   const data = request.data || {};
07:   const studentId = String(data.studentId || "").trim() ||
08:     (callerRole === "student" ? auth.uid : "");
09:   const buyer = payments.buyerRole(caller, auth.uid, studentId);
10:   if (!buyer) {
11:     throw new HttpsError("permission-denied",
12:         "You can only buy for yourself or your own child.", {reason: "not-yours"});
13:   }
14:   const selfPurchase = buyer !== "staff";
15:   if (selfPurchase && data.acceptedTerms !== true) {
16:     throw new HttpsError("failed-precondition", "Tick the terms first.", {reason: "terms"});
17:   }
18:   const pricing = await loadPricing();
19:   const priceItem = findPriceItem(pricing, {priceItemId: data.priceItemId, item: data.item,
20:     packageSize: data.packageSize});
21:   if (!priceItem) throw new HttpsError("failed-precondition", "That item is not on the Price list.");
22:   const amount = priceItem.price;
23:   // ... (satu pembelian terbuka per murid dipakai ulang; tagihan ditulis berstatus pending)

Setelah tagihan tersimpan dengan status pending, fungsi meminta token Snap
ke Midtrans (Segmen Program 6.12). Server key dibaca dari Secret Manager
pada saat fungsi berjalan dan hanya dipakai pada header Authorization
permintaan ini, sehingga tidak pernah ada di aplikasi maupun di repositori.

Segmen Program 6.12
Permintaan Token Midtrans Snap
01:   const orderId = `ES-INV-${Date.now()}-${crypto.randomBytes(3).toString("hex")}`;
02:   // ... (invoiceRef.set({...}) dengan midtransOrderId: orderId)
03:   const serverKey = MIDTRANS_SERVER_KEY.value();
04:   const authHeader = "Basic " + Buffer.from(`${serverKey}:`).toString("base64");
05:   const res = await fetch(snapUrl, {
06:     method: "POST",
07:     headers: {"Accept": "application/json", "Content-Type": "application/json",
08:       "Authorization": authHeader},
09:     body: JSON.stringify({
10:       transaction_details: {order_id: orderId, gross_amount: amount},
11:       item_details: [{id: priceItem.id, price: amount, quantity: 1,
12:         name: priceItem.name.slice(0, 50)}],
13:       customer_details: {first_name: studentName, email: student.email || undefined},
14:     }),
15:   });
16:   const body = await res.json();
17:   // ... (snapToken dan redirectUrl dari body disimpan pada tagihan dan dikembalikan)

Aplikasi membuka redirectUrl pada halaman Snap. Setelah murid membayar,
Midtrans mengirim notifikasi HTTP ke fungsi midtransNotification. Segmen
Program 6.13 memperlihatkan pemeriksaan tanda tangan notifikasi: SHA-512
dari order_id, status_code, gross_amount, dan server key, dibandingkan
dengan waktu tetap, dan pemetaan status transaksi Midtrans ke status
tagihan.

Segmen Program 6.13
Pemeriksaan Tanda Tangan dan Status Notifikasi Midtrans
01: function signatureFor(orderId, statusCode, grossAmount, serverKey) {
02:   return crypto.createHash("sha512")
03:       .update(`${orderId}${statusCode}${grossAmount}${serverKey}`)
04:       .digest("hex");
05: }
06: function signatureOk(given, orderId, statusCode, grossAmount, serverKey) {
07:   const expected = Buffer.from(signatureFor(orderId, statusCode, grossAmount, serverKey), "utf8");
08:   const g = Buffer.from(String(given || ""), "utf8");
09:   return expected.length === g.length && crypto.timingSafeEqual(expected, g);
10: }
11: function invoiceStatusFor(transactionStatus, fraudStatus) {
12:   if (transactionStatus === "settlement" ||
13:       (transactionStatus === "capture" && fraudStatus !== "challenge")) {
14:     return "paid";
15:   }
16:   if (transactionStatus === "expire") return "expired";
17:   if (["deny", "cancel", "failure"].includes(transactionStatus)) return "failed";
18:   return null;
19: }
20: // di dalam midtransNotification (functions/index.js):
21: const serverKey = MIDTRANS_SERVER_KEY.value();
22: if (!payments.signatureOk(signatureKey, orderId, statusCode, grossAmount, serverKey)) {
23:   logger.warn("midtransNotification: bad signature", {orderId});
24:   res.status(403).send("Invalid signature");
25:   return;
26: }

Notifikasi dengan tanda tangan yang salah ditolak dengan kode 403 sebelum
basis data disentuh (MT-02 pada Bab VII). Notifikasi yang sah memasuki
transaksi pada Segmen Program 6.14: fungsi creditDecision memutuskan apakah
tagihan dikreditkan, hanya diubah statusnya, diabaikan karena sudah final,
atau dibiarkan menunggu karena jumlahnya tidak cocok.

Segmen Program 6.14
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
18:   if (decision === "amount-mismatch") {
19:     amountMismatch = true;
20:     return;
21:   }
22:   const termSnap = newStatus === "paid" ? await linkedTermSnap(tx, invoice) : null;
23:   tx.update(invoiceRef, {status: newStatus,
24:     ...(newStatus === "paid" ? {paidAt: FieldValue.serverTimestamp()} : {})});
25:   if (newStatus !== "paid") return;
26:   credited = creditPaidInvoice(tx, invoiceRef, withPriceItem(invoice, pricing), termValidDays, termSnap);
27: });

Perubahan status tagihan dan pembuatan periode voucher (creditPaidInvoice:
jumlah sesi, masa berlaku dari daftar harga, entri voucher_history jenis
pembelian) terjadi dalam satu transaksi, sehingga tidak ada tagihan lunas
tanpa voucher dan tidak ada voucher ganda bila Midtrans mengirim notifikasi
yang sama dua kali (MT-03): notifikasi kedua menemukan tagihan sudah final
dan berhenti pada ignore-final. Notifikasi untuk jumlah yang berbeda dari
tagihan tidak dikreditkan melainkan dicatat untuk admin.

### 6.2.8 Laporan Progress

Lima peringatan laporan progress dari Algoritma 5.8 diimplementasikan pada
fungsi warningsOf di progress.js (Segmen Program 6.15). Fungsi menerima
ringkasan yang sudah dihitung (kehadiran 30 hari, latihan 14 hari dan 14
hari sebelumnya, voucher, riwayat tes) dan daftar peringatan sebelumnya,
sehingga tanggal mulai sebuah peringatan tidak bergeser setiap kali ringkasan
dihitung ulang.

Segmen Program 6.15
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
19:   const lastActive = p.lastPracticeMs !== null && p.lastPracticeMs !== undefined ?
20:     p.lastPracticeMs : summary.activeSinceMs;
21:   if (Number.isFinite(lastActive) && nowMs - lastActive >= 14 * DAY_MS) {
22:     add(3, `No practice for ${Math.floor((nowMs - lastActive) / DAY_MS)} days`);
23:   }
24:   const v = summary.voucher;
25:   if (v && (v.sessionsRemaining <= 2 || (v.daysLeft !== null && v.daysLeft <= 7))) {
26:     add(4, `${v.sessionsRemaining} sessions left` +
27:       (v.daysLeft !== null ? `, ${v.daysLeft} days to the deadline` : ""));
28:   }
29:   const counted = ((summary.tests || {}).history || []).filter(isCountedTest);
30:   if (counted.length >= 2 && !counted[0].passed && !counted[1].passed) {
31:     add(5, `Failed ${counted[1].code} and ${counted[0].code} in a row`);
32:   }
33:   return out;
34: }

Ringkasan ditulis fungsi refreshProgressSummary ke progress_summary/{uid}
setiap kali hasil latihan, kehadiran, voucher, catatan guru, atau hasil tes
murid berubah, dan oleh pekerjaan harian pukul 07.00 yang juga mengirim
notifikasi peringatan paling banyak sekali dalam tujuh hari per murid per
peringatan. Aplikasi hanya membaca dokumen ringkasan ini, sehingga laporan
di tab murid, halaman guru, halaman admin, dan tampilan orang tua selalu
sama.

Grafik nilai latihan per minggu pada laporan dibuat dengan fl_chart
(Segmen Program 6.16). Titik-titiknya adalah rata-rata nilai setiap minggu
dari practiceChartPoints, sumbu tegak tetap 0 sampai 100 dengan garis bantu
setiap 25, dan sumbu datar memberi label tanggal Senin setiap dua minggu.

Segmen Program 6.16
Grafik Nilai Latihan per Minggu dengan fl_chart
01: // _PracticeChart.build (lib/features/progress/student_progress_report_screen.dart)
02: Widget build(BuildContext context) {
03:   final points = practiceChartPoints(weeks);
04:   if (points.isEmpty) return _Empty(context.l10n.progressPracticeEmpty);
05:   return SizedBox(
06:     height: 200,
07:     child: LineChart(
08:       LineChartData(
09:         minX: 0, maxX: (weeks.length - 1).toDouble(), minY: 0, maxY: 100,
10:         gridData: FlGridData(drawVerticalLine: false, horizontalInterval: 25,
11:           getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1)),
12:         // ... (label sumbu: nilai setiap 25; tanggal Senin tiap dua minggu; tooltip)
13:         lineBarsData: [
14:           LineChartBarData(
15:             spots: [for (final p in points) FlSpot(p.x, p.y)],
16:             color: AppColors.teal,
17:             barWidth: 3,
18:             isCurved: false,
19:             dotData: const FlDotData(show: true),
20:             belowBarData: BarAreaData(show: true, color: AppColors.teal.withValues(alpha: 0.12)),
21:           ),
22:         ],
23:       ),
24:     ),
25:   );
26: }

Warna grafik dibaca dari AppColors, yang berganti palet pada tema gelap,
dan teks sumbu dibaca dari berkas terjemahan. Widget ini dipakai oleh
StudentProgressReport, satu widget yang sama untuk tab Progress murid, tab
pertama orang tua, dan halaman progress murid pada sisi guru dan admin,
serta oleh laporan PDF yang dicetak dari ringkasan yang sama.

### 6.2.9 Pemutar Latihan di Flutter

Di sisi aplikasi, pemutar latihan tidak pernah memegang kunci jawaban.
Soal diambil dari startExercise, jawaban murid disimpan sementara di
memori, dan satu panggilan finishExercise mengirim semuanya sekaligus ketika
murid menekan Kumpulkan (Segmen Program 6.17), sesuai keputusan pemilik
bahwa tidak ada pemanggilan fungsi per jawaban.

Segmen Program 6.17
Pengiriman Jawaban Sekali ke finishExercise
01: @override
02: Future<PlayResult> finish({required int durationSeconds}) async {
03:   final result = await _functions.httpsCallable('finishExercise').call({
04:     'exerciseId': exercise.id,
05:     'answers': {
06:       for (final entry in _answers.entries) entry.key: entry.value.toJson(),
07:     },
08:     'durationSeconds': durationSeconds,
09:   });
10:   final m = Map<String, dynamic>.from(result.data as Map);
11:   final review = <String, AnswerCheck>{};
12:   for (final item in m['review'] as List? ?? const []) {
13:     final entry = Map<String, dynamic>.from(item as Map);
14:     final id = entry['questionId'] as String? ?? '';
15:     if (id.isNotEmpty) review[id] = AnswerCheck.fromServer(entry);
16:   }
17:   // ... (bySkill, nilai, status, dan resultId dibaca dari jawaban fungsi)
18:   return PlayResult(
19:     score: (m['score'] as num?)?.toInt() ?? 0,
20:     // ...
21:   );
22: }
23: // di exercise_screen.dart, sekali ketika murid menekan Kumpulkan:
24: await _session!.finish(durationSeconds: _clock.elapsed.inSeconds);

Setiap jawaban dikirim sebagai salah satu dari tiga bentuk (index untuk
pilihan, order untuk urutan kata, text untuk ketikan) sesuai kelas
PlayAnswer, dan ulasan yang kembali (AnswerCheck) memuat kunci, pembahasan,
dan tanda apakah jawaban menunggu penilaian guru. Halaman hasil
menampilkan ulasan itu beserta nilai per keterampilan; untuk paket ujian
satu kali, jam dari server (remainingSeconds) menghitung mundur dan
mengumpulkan jawaban sendiri ketika habis. Paket latihan format lama yang
menyimpan kunci di dalam dokumen tidak dapat dimainkan lagi
(LegacyExerciseException), sehingga kunci tidak pernah terbaca oleh
aplikasi.
