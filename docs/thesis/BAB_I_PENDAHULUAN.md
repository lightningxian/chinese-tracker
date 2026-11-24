# BAB I
# PENDAHULUAN

Bab ini memberikan gambaran umum mengenai pembuatan Aplikasi
Multiplatform Sistem Kursus Bahasa Mandarin Easy Study menggunakan Flutter.
Bab ini berisi latar belakang pembuatan aplikasi, tujuan, ruang lingkup yang
mencakup peran pengguna dan batasan sistem, perangkat lunak yang
digunakan, metodologi pengembangan, serta sistematika pembahasan buku
tugas akhir ini.

## 1.1 Latar Belakang

Pembelajaran bahasa Mandarin telah mengalami perubahan yang berarti
seiring dengan perkembangan teknologi digital. Metode tradisional yang
mengandalkan buku teks dan interaksi tatap muka kini dilengkapi, bahkan
sebagian digantikan, oleh pendekatan yang lebih interaktif dan fleksibel.
Aplikasi dan situs web pembelajaran bahasa Mandarin modern menawarkan
latihan interaktif dan tes daring yang dapat diakses kapan saja. Perubahan ini
membuka peluang untuk merancang pengalaman belajar yang lebih menarik,
lebih personal, dan lebih mudah diakses oleh murid dengan gaya belajar yang
beragam.

Peralihan ke metode digital juga menghadirkan tantangan, yaitu kebutuhan
akan infrastruktur, pelatihan, dan penyesuaian cara kerja lembaga. Di sinilah
framework pengembangan aplikasi seperti Flutter dan layanan backend seperti
Firebase berperan penting, karena keduanya memungkinkan sebuah lembaga
kecil membangun aplikasi untuk web, Android, dan iOS dari satu basis kode
tanpa harus mengelola server sendiri.

Easy Study (易华文教中心) adalah lembaga kursus bahasa Mandarin di
Surabaya yang berdiri sejak ⟦1994⟧ dan beralamat di Jl. Manyar Tirtomoyo
VII/11, Surabaya. Easy Study memiliki empat guru bahasa Mandarin yang mengajar
kelas tatap muka dari tingkat HSK 1 sampai HSK 6, yang dikelompokkan
menjadi level Beginner (HSK 1–2), Intermediate (HSK 3–4), dan Advance
(HSK 5–6). Pada saat tugas akhir ini disusun (November 2026), Easy Study
melayani 54 murid aktif dengan [ISI: jumlah] sesi kelas per minggu. Admin
menentukan jadwal setiap kelas beserta guru pengajarnya; murid tidak memilih
guru, tetapi memilih sesi kelas sesuai level dan waktu yang cocok.

Sebelum aplikasi ini dibuat, proses operasional di Easy Study dijalankan
secara manual dan terpisah-pisah. Pendaftaran murid dan konfirmasi kehadiran
dilakukan melalui pesan WhatsApp, jam belajar disepakati lewat chat tanpa
jadwal guru atau jadwal kelas yang tertulis, kehadiran dicatat di kertas, bukti transfer pembayaran dicek satu per satu, sisa
sesi paket kursus dihitung secara manual, soal latihan dikerjakan dan dikoreksi
di atas kertas, dan nilai tes simulasi HSK dicatat di aplikasi web terpisah yang
bernama Nilai Simulasi HSK. Akibatnya, pemakaian guru dan ruang tidak
terpantau, data murid tersebar di beberapa tempat,
pencatatan rawan salah, dan perkembangan belajar setiap murid sulit dipantau,
baik oleh guru maupun pemilik usaha. Jika seorang guru berhalangan, admin
harus mencari guru pengganti secara manual melalui chat. Perbandingan rinci
antara sistem lama dan sistem baru dijelaskan pada Bab III dan Bab IV.

Fokus tugas akhir ini adalah sistem kursus, yaitu proses yang berkaitan
langsung dengan kegiatan belajar mengajar: pendaftaran murid, penjadwalan
guru dan sesi kelas, absensi, voucher kursus dan pembayarannya, latihan dan
tes simulasi HSK daring, kenaikan tingkat HSK, serta laporan progress murid.
Tugas akhir ini bukan sistem manajemen usaha secara keseluruhan, sehingga
penggajian guru, akuntansi, inventaris, dan pemasaran tidak termasuk dalam
ruang lingkup.

Melalui tugas akhir ini dirancang dan dikembangkan Aplikasi Multiplatform
Sistem Kursus Bahasa Mandarin Easy Study menggunakan Flutter sebagai
jawaban atas permasalahan tersebut. Aplikasi ini menyediakan platform digital
yang dapat diakses dari web, Android, dan iOS, dengan fitur utama berupa
penjadwalan guru dengan pengecekan bentrok otomatis dan penunjukan guru
pengganti, pemilihan sesi kelas dan absensi digital, voucher kursus (paket sesi)
yang berkurang secara otomatis, latihan dan tes simulasi HSK daring bertipe
Listening, Reading, dan Typing yang dinilai otomatis dan diawasi guru,
kenaikan tingkat HSK berdasarkan kelulusan tes simulasi beserta leaderboard
per kode tes, tes penempatan opsional bagi murid baru, laporan progress murid
untuk keperluan monitoring, serta pembayaran daring melalui Midtrans.

Firebase dimanfaatkan untuk pengolahan data, autentikasi pengguna, dan
notifikasi, sedangkan Firebase Cloud Functions menjalankan logika penting di
sisi server, seperti pengecekan bentrok jadwal, penilaian jawaban, pemotongan
sisa sesi voucher, dan pemrosesan pembayaran. Dengan cara ini kunci jawaban
dan nilai tidak pernah berada di perangkat murid, dan dua proses yang
mengubah data yang sama pada saat bersamaan tidak menghasilkan data yang
tidak konsisten. Aplikasi ini diharapkan tidak hanya mengatasi kendala
aksesibilitas dan transparansi dalam kegiatan belajar mengajar di Easy Study,
tetapi juga menjadi langkah kecil dalam mendukung digitalisasi pengajaran
bahasa Mandarin di Indonesia.

## 1.2 Tujuan

Tujuan dari pembuatan Aplikasi Multiplatform Sistem Kursus Bahasa
Mandarin Easy Study menggunakan Flutter adalah sebagai berikut:

1. Menggantikan proses administrasi manual di Easy Study (pendaftaran,
   penjadwalan, absensi, pembayaran, dan pengelolaan paket sesi) dengan
   satu aplikasi multiplatform (web, Android, dan iOS) yang datanya
   terpusat.
2. Membantu admin menyusun jadwal guru secara terstruktur dengan
   pengecekan bentrok otomatis, serta memantau pelaksanaan setiap sesi
   kelas.
3. Menyediakan latihan dan tes simulasi HSK daring bertipe Listening,
   Reading, dan Typing yang dinilai otomatis di sisi server, beserta aturan
   kenaikan tingkat HSK yang jelas dan terukur.
4. Menyediakan laporan progress murid yang dapat dipantau oleh murid,
   guru, dan pemilik usaha, sehingga murid yang membutuhkan perhatian
   dapat segera ditindaklanjuti.
5. Menyediakan data pendaftaran, kehadiran, pembayaran, dan kemampuan
   murid untuk mendukung pengambilan keputusan bisnis.

## 1.3 Ruang Lingkup

Bagian ini menjelaskan peran pengguna yang ada pada aplikasi dan
batasan-batasan sistem yang diterapkan agar ruang lingkup tugas akhir tidak
terlalu luas.

### 1.3.1 Role

Aplikasi ini memiliki tiga peran pengguna, yaitu admin, guru, dan murid.
Setiap peran masuk melalui halaman login yang sama dan diarahkan ke
halaman utama sesuai perannya. Calon murid dapat mendaftar sendiri melalui
aplikasi; akun baru dapat digunakan setelah disetujui oleh admin.

a. Admin

Admin adalah pengguna yang bertanggung jawab mengelola data dan
memastikan kegiatan belajar mengajar berjalan lancar. Peran admin
mencakup:

- Mengelola user: membuat, mengubah, dan menonaktifkan akun guru dan
  murid, serta menyetujui atau menolak registrasi murid baru.
- Mengelola bank soal dan kode tes: menambah, mengubah, dan menghapus
  soal Listening, Reading, dan Typing, mengimpor soal dari file, serta
  menyusun paket tes simulasi dengan kode tes yang unik.
- Mengelola jadwal kelas dan jadwal guru: melihat ketersediaan guru dan
  menyusun jadwal (level, hari, jam, ruang, guru, kuota, periode) yang
  diperiksa bentroknya secara otomatis sebelum disimpan.
- Mengelola sesi: mengubah sesi pada tanggal tertentu, menunjuk guru
  pengganti, membatalkan sesi, serta memantau sesi yang terlambat dimulai
  atau belum ditutup.
- Mengelola voucher kursus: membuat paket voucher (sejumlah sesi dengan
  masa berlaku) dan memantau penggunaannya.
- Mengelola aturan kenaikan tingkat dan memverifikasi rekomendasi
  kenaikan tingkat serta tingkat awal murid baru.
- Mengelola pembayaran: memantau transaksi Midtrans beserta statusnya
  dan mencatat pembayaran tunai atau transfer.
- Memantau progress seluruh murid dan melihat laporan bulanan (murid
  baru, pendapatan, murid aktif, kehadiran, rekap jam mengajar guru,
  leaderboard).

b. Guru

Guru berperan sebagai pengajar yang mengelola kegiatan kelas dan
menilai perkembangan murid. Peran guru mencakup:

- Mengatur ketersediaan mengajar per minggu dan tanggal tidak tersedia.
- Melihat jadwal mengajar, mengonfirmasi jadwal, atau mengajukan
  permintaan perubahan.
- Memulai sesi (check-in), mengisi absensi murid (hadir, izin, alpa), dan
  menutup sesi.
- Membaca data murid di kelasnya: profil, riwayat belajar, level, dan sisa
  sesi voucher.
- Mengelola soal latihan: menambah soal ke bank soal, menyusun paket
  latihan, dan memberikannya kepada murid.
- Membuka dan mengawasi tes simulasi atau tes penempatan dengan token,
  melihat catatan murid yang keluar dari halaman tes, dan menandai hasil
  yang tidak sah.
- Menilai soal menulis bebas dengan rubrik, meninjau jawaban Typing yang
  ditandai sistem, dan memberi catatan.
- Memantau progress murid di kelasnya dan melihat leaderboard.

c. Murid

Murid adalah pengguna yang mengikuti kursus dan mengerjakan latihan
maupun tes simulasi di aplikasi. Peran murid mencakup:

- Mengakses dan mengubah informasi diri.
- Mengikuti tes penempatan (opsional) untuk menentukan tingkat awal.
- Memilih sesi kelas sesuai levelnya selama kuota tersedia dan voucher
  masih aktif; guru pengajar ditentukan oleh admin.
- Melihat riwayat kehadiran.
- Membeli voucher kursus melalui Midtrans serta melihat sisa sesi, riwayat
  penggunaan, dan tanggal kedaluwarsa.
- Mengerjakan latihan di mana saja dan tes simulasi di Easy Study dengan
  token dari guru.
- Melihat nilai dan pembahasan, leaderboard, serta laporan progress diri
  sendiri.

### 1.3.2 Batasan Sistem

Batasan-batasan berikut diterapkan agar pembuatan aplikasi tetap fokus
pada ruang lingkup utama:

1. Aplikasi dibuat dalam bahasa Indonesia.
2. Aplikasi berfokus pada sistem kursus (kegiatan belajar mengajar dan
   administrasinya), bukan sistem manajemen usaha secara keseluruhan.
   Penggajian guru, akuntansi, inventaris, dan pemasaran tidak termasuk;
   rekap jam mengajar hanya disediakan sebagai data.
3. Aplikasi tidak menyediakan materi pelajaran; materi diberikan guru di
   kelas tatap muka, sedangkan aplikasi menyediakan latihan dan tes
   simulasi.
4. Penilaian hanya digunakan untuk menentukan kenaikan tingkat HSK
   melalui tes simulasi; aplikasi tidak menghasilkan rapor atau nilai akhir
   seperti sekolah formal.
5. Tes simulasi dan tes penempatan hanya dapat dikerjakan di Easy Study
   dengan token dari guru; latihan dapat dikerjakan di mana saja.
6. Guru pengajar setiap kelas ditetapkan oleh admin; murid tidak memilih
   guru.
7. Sistem mendukung perangkat Android, iOS, dan peramban web.
8. Kelas dilaksanakan secara tatap muka di Easy Study Surabaya; aplikasi
   tidak menyediakan kelas daring atau konferensi video.
9. Soal hanya dapat dibuat dan dikelola oleh admin dan guru.
10. Tipe soal terdiri atas tiga macam, yaitu Listening, Reading, dan Typing,
    dengan bentuk soal yang dijelaskan pada Bab V. Soal menulis bebas (T5)
    dinilai oleh guru.
11. Aplikasi tidak menyediakan latihan dan tes kemampuan berbicara
    (HSKK).
12. Level kursus mengacu pada HSK enam tingkat (HSK 1–6) yang
    dikelompokkan menjadi Beginner, Intermediate, dan Advance.
13. Pembayaran dilakukan secara daring melalui payment gateway Midtrans;
    pengujian pembayaran menggunakan mode sandbox.

## 1.4 Software yang Digunakan

Pembuatan aplikasi ini menggunakan perangkat lunak berikut:

1. Flutter SDK versi 3.44 beserta bahasa pemrograman Dart, untuk membangun
   aplikasi web, Android, dan iOS dari satu basis kode [11].
2. Visual Studio Code sebagai editor kode, dan Android Studio beserta
   Android SDK dan JDK 21 untuk membangun dan menguji versi Android.
3. Firebase Console dan Firebase CLI untuk mengelola proyek Firebase
   (Authentication, Cloud Firestore, Cloud Storage, Cloud Messaging, Cloud
   Functions, Hosting), serta Firebase Emulator Suite untuk menjalankan
   seluruh layanan tersebut di komputer lokal selama pengembangan dan
   pengujian [7].
4. Node.js versi 22, sebagai lingkungan eksekusi Cloud Functions dan
   skrip pengujian otomatis [8].
5. Git dan GitHub untuk kendali versi, dengan GitHub Actions yang
   menjalankan pemeriksaan kode dan pengujian otomatis pada setiap
   perubahan.
6. Midtrans Sandbox untuk menguji alur pembayaran tanpa uang sungguhan
   [15].
7. Peramban Google Chrome, Microsoft Edge, dan Safari untuk menguji versi
   web, serta Microsoft Word dan draw.io untuk menyusun buku dan
   diagram.
8. Claude Code dari Anthropic sebagai asisten pemrograman berbasis AI,
   yang membantu menulis dan memeriksa kode, skrip pengujian otomatis,
   dan dokumentasi teknis. Seluruh rancangan, keputusan, dan pemeriksaan
   hasil tetap dilakukan oleh penulis.

## 1.5 Metodologi

Metodologi yang digunakan dalam penyelesaian tugas akhir ini adalah
Waterfall. Metodologi Waterfall merupakan pendekatan pengembangan sistem
yang mengikuti serangkaian tahapan secara linier dan berurutan; setiap tahapan
diselesaikan sebelum melangkah ke tahapan berikutnya [18]. Tahapan tersebut
ditunjukkan pada Gambar 1.1.

[GAMBAR 1.1: diagram tangga enam tahap Waterfall: Analisis Kebutuhan →
Desain Sistem → Implementasi → Pengujian → Penerapan → Pemeliharaan]

Gambar 1.1
Metodologi Waterfall

Penerapan setiap tahapan pada tugas akhir ini adalah sebagai berikut:

1. Analisis Kebutuhan. Kebutuhan sistem dikumpulkan dengan mengamati
   proses operasional Easy Study, mewawancarai admin dan guru, menelaah
   dokumen yang dipakai saat ini (daftar murid di spreadsheet, daftar hadir,
   catatan nilai simulasi), dan membandingkan aplikasi sejenis. Hasilnya dituangkan
   dalam proposal tugas akhir yang disidangkan pada 7 Oktober 2026 dan
   diperbaiki sesuai masukan penguji. Tahapan ini dibahas pada Bab III dan
   Bab IV.
2. Desain Sistem. Berdasarkan hasil analisis dirancang arsitektur aplikasi,
   struktur data Cloud Firestore, aturan akses, daftar Cloud Functions, alur
   proses dalam bentuk use case dan activity diagram, serta rancangan
   antarmuka. Tahapan ini dibahas pada Bab V.
3. Implementasi. Aplikasi dibangun dengan Flutter dan Firebase secara
   bertahap per modul: autentikasi dan peran, bank soal dan latihan, tes
   simulasi dengan token dan penilaian di server, leaderboard dan kenaikan
   tingkat, persetujuan registrasi dan tes penempatan, laporan progress,
   voucher dan pembayaran, jadwal dan pemesanan sesi, pelaksanaan sesi,
   serta dashboard dan laporan bulanan. Implementasi (penulisan kode) dilakukan
   pada ⟦Agustus 2026⟧ sampai November 2026 dan dibahas pada Bab VI.
4. Pengujian. Setiap modul diuji dengan pengujian otomatis (unit test
   Flutter, pengujian logika Cloud Functions, pengujian Firestore Security
   Rules, dan pengujian alur ujung-ke-ujung pada Firebase Emulator Suite),
   kemudian aplikasi diuji dengan black-box testing, validasi fungsional,
   user-based testing, dan kuesioner System Usability Scale bersama 35
   responden di Easy Study. Tahapan ini dibahas pada Bab VII.
5. Penerapan. Aplikasi web diterapkan pada Firebase Hosting dan dipakai di
   Easy Study; versi Android disediakan sebagai berkas APK, sedangkan
   pengguna iOS memakai versi web yang ditambahkan ke layar utama.
6. Pemeliharaan. Masukan dari uji coba dan pemakaian sehari-hari dicatat
   dan diperbaiki pada versi berikutnya.

## 1.6 Sistematika Pembahasan

Buku tugas akhir ini disusun dalam delapan bab dengan sistematika sebagai
berikut:

- BAB I : PENDAHULUAN
  Bab ini berisi latar belakang pembuatan aplikasi, tujuan, ruang lingkup
  yang menjelaskan peran pengguna dan batasan sistem, perangkat lunak
  yang digunakan, metodologi, serta sistematika pembahasan.
- BAB II : TEORI PENUNJANG
  Bab ini menjelaskan teori dan teknologi yang menjadi dasar pembuatan
  aplikasi, yaitu Dart, Flutter, pengembangan multiplatform, Firebase,
  Cloud Functions, Firestore Security Rules, transaksi Firestore, basis data
  NoSQL, arsitektur MVVM, Midtrans, HSK, pencocokan teks, System
  Usability Scale, dan black-box testing.
- BAB III : PROSES BISNIS
  Bab ini menjelaskan profil Easy Study dan proses bisnis yang berjalan
  sebelum aplikasi dibuat, pemodelannya dalam bentuk rich picture, use
  case diagram, dan activity diagram, serta permasalahan yang ditemukan.
- BAB IV : ANALISA SISTEM
  Bab ini berisi pengumpulan fakta melalui wawancara dan analisis
  dokumen, identifikasi masalah, perbandingan dengan aplikasi sejenis, dan
  spesifikasi kebutuhan sistem.
- BAB V : DESAIN SISTEM
  Bab ini berisi rancangan sistem baru: deskripsi sistem, perbedaan jadwal
  dan sesi, penjadwalan guru dan pengecekannya, konsistensi data voucher,
  tipe soal dan algoritma penilaian, sistem level dan kenaikan tingkat,
  laporan progress, use case dan activity diagram, arsitektur sistem, desain
  basis data, aturan akses, daftar Cloud Functions, dan desain antarmuka.
- BAB VI : IMPLEMENTASI
  Bab ini berisi implementasi antarmuka setiap halaman per peran dan
  implementasi program pada bagian-bagian penting, seperti penutupan
  sesi dalam satu transaksi, pencocokan jawaban Typing, pengecekan
  bentrok jadwal, perhitungan kenaikan tingkat, dan penanganan
  notifikasi Midtrans.
- BAB VII : UJI COBA
  Bab ini berisi uji coba kompatibilitas, black-box testing per peran,
  validasi fungsional dengan skenario yang telah ditetapkan, user-based
  testing, dan hasil kuesioner System Usability Scale beserta analisisnya.
- BAB VIII : PENUTUP
  Bab ini berisi kesimpulan yang menjawab tujuan pada Bab I dan saran
  untuk pengembangan aplikasi selanjutnya.
