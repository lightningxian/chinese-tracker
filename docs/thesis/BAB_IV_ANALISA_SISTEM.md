# BAB IV
# ANALISA SISTEM

Bab ini menganalisis kebutuhan sistem baru berdasarkan fakta yang
dikumpulkan di Easy Study. Fakta dikumpulkan melalui pengamatan langsung,
wawancara dengan admin dan guru, serta penelaahan dokumen yang dipakai pada
sistem lama. Dari fakta tersebut dirumuskan masalah yang harus diselesaikan,
dibandingkan dengan aplikasi sejenis, lalu disusun spesifikasi kebutuhan
sistem yang menjadi dasar rancangan pada Bab V.

## 4.1 Pengumpulan Fakta

Pengumpulan fakta dilakukan dari September sampai November 2026 dengan
tiga cara. Pertama, pengamatan langsung: penulis adalah anggota keluarga
pemilik Easy Study dan ikut dalam kegiatan operasional sehari-hari, sehingga
alur kerja admin dan guru dapat diamati dari dalam. Kedua, wawancara tidak
terstruktur dengan admin (T) dan keempat guru (W, S, M, dan W) tentang
pekerjaan harian mereka dan kesulitan yang dirasakan. Ketiga, penelaahan
dokumen yang dipakai pada sistem lama: formulir pendaftaran, daftar siswa,
rekap absensi, kwitansi, daftar sesi di grup WhatsApp, daftar hadir kertas,
dan aplikasi web Nilai Simulasi HSK.

### 4.1.1 Pengamatan dan Wawancara

Admin T adalah satu-satunya staf administrasi. Pekerjaan utamanya adalah
menjaga voucher (sisa sesi) setiap murid, melayani pertanyaan calon murid dan
murid, memenuhi kebutuhan murid, dan menyiapkan materi cetak; di luar itu ia
mengerjakan tugas lain yang diminta pemilik. Keempat guru mengajar dan
bertanggung jawab atas materi ajar: memastikan setiap materi tercatat,
mendigitalkannya, mempelajarinya, dan memperbaikinya. Pemilik usaha tidak
terlibat dalam operasional harian selain menerima pemberitahuan pembayaran
dari admin. Fakta utama yang diperoleh adalah sebagai berikut.

1. Setiap sore setelah kelas terakhir berakhir pukul 18.00, admin mengirim
   daftar sesi hari berikutnya ke grup WhatsApp siswa; murid menuliskan
   namanya pada sesi yang dipilih. Murid menyepakati hari les saat mendaftar,
   tetapi bebas memilih sesi lain yang lebih cocok dengan kesibukannya.
2. Dalam satu sesi biasanya dua guru mengajar bersama murid dari berbagai
   tingkat dalam satu ruang; guru lainnya siaga. Tidak ada jadwal guru yang
   tertulis. Bila seorang guru berhalangan, admin mencari pengganti dengan
   menghubungi guru lain satu per satu, dan dengan hanya empat guru hal ini
   sering sulit.
3. Calon murid datang melalui WhatsApp atau langsung ke tempat kursus,
   sebagian setelah mengenal Easy Study dari Instagram. Tidak ada kelas
   percobaan gratis. Data diri diisi pada Google Form; tingkat awal mengikuti
   pilihan murid, mulai dari Beginner atau melalui tes singkat yang diberikan
   guru.
4. Pembayaran dilakukan dengan transfer atau tunai. Bukti transfer dikirim ke
   admin dan diteruskan ke pemilik; admin menulis kwitansi fisik dan mencatat
   paket di file Excel voucher aktif. Admin mengingatkan murid yang paketnya
   hampir habis atau mendekati akhir masa berlaku dua bulan.
5. Kehadiran dicatat guru di kertas; keesokan harinya admin mengurangi sesi
   pada file Excel. Guru dan pemilik tidak mengetahui kapan seorang murid
   terakhir datang tanpa bertanya kepada admin.
6. Tes simulasi diberikan ketika guru menilai murid sudah mencapai titik
   tertentu atau sudah lama tidak dites. Soal diambil dari arsip soal HSK
   sekitar empat belas tahun yang dicetak dan distok admin; guru mengawasi
   dan memutar rekaman. Murid dianggap lulus bila mencapai sekitar 60 % pada
   setiap bagian; nilai dimasukkan ke aplikasi web Nilai Simulasi HSK.
7. Kenaikan tingkat diputuskan guru setelah murid lulus dua sampai tiga tes
   simulasi dan menyelesaikan sejumlah latihan, lalu disampaikan secara
   lisan. Tidak ada aturan tertulis dan tidak ada rekap bulanan tentang murid
   baru, pendapatan, atau jam mengajar.
8. Menurut pemilik, pemeriksaan pembayaran bukan masalah karena murid cukup
   mengirim pemberitahuan transfer, dan nilai tes yang hilang juga bukan
   masalah karena lembar tes dikembalikan kepada murid. Masalah yang paling
   dirasakan berturut-turut adalah guru pengganti, perkembangan murid yang
   tidak terpantau, tidak adanya rekap bulanan, serta tidak adanya jadwal dan
   kesalahan hitung sisa sesi.

### 4.1.2 Analisis Dokumen

Dokumen yang dipakai pada sistem lama dirangkum pada Tabel 4.1. Setiap
dokumen dikelola oleh pihak yang berbeda dan tidak saling terhubung, sehingga
data murid yang sama tercatat di beberapa tempat dengan bentuk yang berbeda.

Tabel 4.1
Dokumen Sistem Lama yang Dianalisis

| No | Dokumen | Pengelola | Isi | Kelemahan |
|---|---|---|---|---|
| 1 | Formulir Pendaftaran Siswa Baru (Google Form) | Admin | Data diri, paket yang dipilih, tingkat awal, kontak orang tua, tujuan belajar, persetujuan ketentuan (Tabel 3.3) | Jawaban terkumpul di spreadsheet Google Form, lalu disalin tangan ke daftar siswa |
| 2 | Daftar Siswa Easy Study (Excel) | Admin | 1.324 nama murid sejak 1994 dengan tanggal masuk, nama Mandarin, kontak, alamat, tanggal lahir, dan kontak orang tua; lembar Aktif berisi 54 murid aktif dengan paket dan harganya | Satu file yang disunting tangan; tidak ada riwayat perubahan; data lama dan baru bercampur |
| 3 | Rekap Absensi Murid (Excel) | Admin | Lembar paket 16 dan 8 pertemuan: satu baris per murid dengan tanggal setiap pertemuan dan sisa sesi (33 dan 29 paket berjalan pada November 2026) | Diisi sehari setelah kelas dari daftar hadir kertas; sisa sesi dihitung manual |
| 4 | Kwitansi | Admin | Nama murid, paket (misalnya Term 16 pertemuan Rp3.950.000), tanggal | Ditulis tangan per pembayaran; tidak terhubung dengan paket di Excel |
| 5 | Daftar sesi harian (grup WhatsApp) | Admin dan murid | Dua sesi per hari dengan delapan tempat; murid menulis namanya (Gambar 3.1) | Harus dikirim setiap sore; tidak ada batas tempat otomatis; tidak tersimpan |
| 6 | Daftar hadir kertas | Guru | Nama, jam masuk, lama belajar per hari (Gambar 3.2) | Disetor berkala; satu-satunya sumber pengurangan sisa sesi |
| 7 | Aplikasi web Nilai Simulasi HSK | Guru | Nilai per bagian setiap tes simulasi per murid (Gambar 3.4) | Terpisah dari data murid lainnya; diisi tangan |

Gambar 4.1 menunjukkan halaman pertama Google Form pendaftaran, Gambar
4.2 contoh kwitansi, Gambar 4.3 cuplikan lembar Aktif pada daftar siswa, dan
Gambar 4.4 cuplikan lembar paket 16 pertemuan pada rekap absensi. Data
pribadi pada gambar disamarkan.

[GAMBAR 4.1: tangkapan layar halaman pertama Google Form pendaftaran]

Gambar 4.1
Formulir Pendaftaran Siswa Baru pada Google Form

[GAMBAR 4.2: foto kwitansi pembayaran paket, nama murid disamarkan]

Gambar 4.2
Kwitansi Pembayaran Paket Kursus pada Sistem Lama

[GAMBAR 4.3: cuplikan lembar Aktif pada Excel Daftar Siswa, data pribadi disamarkan]

Gambar 4.3
Lembar Murid Aktif pada Daftar Siswa (Excel)

[GAMBAR 4.4: cuplikan lembar paket 16 pertemuan pada Excel Rekap Absensi, nama disamarkan]

Gambar 4.4
Lembar Paket 16 Pertemuan pada Rekap Absensi Murid (Excel)

Daftar siswa juga memberi gambaran perkembangan jumlah murid. Tabel 4.2
menunjukkan jumlah murid baru per tahun sejak 2019 menurut tanggal masuk
pada daftar tersebut. Jumlah murid baru turun selama pandemi dan naik kembali
sejak 2024, sehingga beban pencatatan admin bertambah pada saat tugas akhir
ini dikerjakan.

Tabel 4.2
Murid Baru per Tahun menurut Daftar Siswa

| Tahun | Murid baru |
|---|---|
| 2019 | 107 |
| 2020 | 40 |
| 2021 | 33 |
| 2022 | 40 |
| 2023 | 28 |
| 2024 | 60 |
| 2025 | 85 |
| 2026 (sampai 25 November) | 42 |

Paket kursus yang dijual pada 2026 dirangkum pada Tabel 4.3. Kedua paket
berlaku dua bulan sejak tanggal mulai; sisa pertemuan setelah masa berlaku
hangus kecuali ada libur resmi atau kesepakatan tertentu. Ketentuan ini
disetujui murid pada formulir pendaftaran dan menjadi aturan voucher pada
sistem baru.

Tabel 4.3
Paket Kursus Easy Study pada 2026

| Paket | Lama belajar | Harga | Ketentuan kehadiran | Masa berlaku |
|---|---|---|---|---|
| 16 pertemuan | 24 jam (1,5 jam per pertemuan) | Rp3.950.000 | Minimal dua kali seminggu | 2 bulan |
| 8 pertemuan | 12 jam (1,5 jam per pertemuan) | Rp2.450.000 | Minimal sekali seminggu | 2 bulan |

## 4.2 Identifikasi Masalah

Permasalahan sistem lama telah dirangkum pada Tabel 3.4 menurut urutan
yang paling dirasakan pemilik. Tabel 4.4 memetakan setiap masalah ke
kebutuhan sistem dan ke fitur sistem baru yang menjawabnya pada Bab V.
Dua contoh nyata yang disebut pemilik menggambarkan masalah tersebut: guru
dan pemilik tidak tahu kapan seorang murid terakhir datang tanpa memeriksa
catatan admin, dan admin kadang lupa mengirim daftar sesi untuk esok hari
sehingga murid tidak tahu kelas dibuka atau tidak.

Tabel 4.4
Pemetaan Masalah ke Kebutuhan Sistem

| No | Masalah | Kebutuhan sistem | Fitur sistem baru |
|---|---|---|---|
| 1 | Guru pengganti sulit dicari | Ketersediaan guru, level yang diajar, dan jadwal tercatat di satu tempat; penunjukan pengganti dicek bentroknya | Jadwal guru dan guru pengganti dengan pengecekan bentrok (Bab V) |
| 2 | Perkembangan murid tidak terpantau | Riwayat kehadiran, latihan, dan tes setiap murid terkumpul dan dapat dibaca guru, pemilik, dan orang tua | Laporan progress dengan peringatan otomatis; akun orang tua |
| 3 | Tidak ada rekap bulanan | Murid baru, pendapatan, murid aktif, dan jam mengajar dihitung otomatis | Laporan bulanan dan dashboard admin |
| 4 | Tidak ada jadwal guru dan kelas | Sesi kelas dibuat otomatis dari jadwal; murid memesan tempat sendiri | Jadwal mingguan, pembuatan sesi, pemesanan sesi dengan kuota |
| 5 | Selisih sisa sesi paket | Sisa sesi berkurang otomatis saat sesi ditutup; masa berlaku dipantau sistem | Voucher dengan buku besar pemakaian dan kedaluwarsa otomatis |
| 6 | Data murid tersebar | Satu basis data untuk pendaftaran, paket, kehadiran, latihan, dan nilai | Basis data terpusat (Cloud Firestore) dengan peran pengguna |
| 7 | Kenaikan tingkat tidak terstandar | Aturan lulus dan syarat naik tingkat tertulis dan dihitung sistem | Sistem level, rekomendasi kenaikan, persetujuan admin |
| 8 | Koreksi latihan dan tes manual | Latihan dan tes dikerjakan dan dinilai di aplikasi | Bank soal, paket latihan, tes simulasi dengan penilaian di server |
| 9 | Pencatatan pembayaran manual | Pembayaran tercatat sebagai invoice yang langsung membentuk paket | Invoice, pembayaran tunai/transfer yang dicatat admin, dan Midtrans |

## 4.3 Perbandingan dengan Aplikasi Sejenis

Sistem baru dibandingkan dengan dua aplikasi yang mewakili dua sisi
kebutuhan Easy Study, yaitu Teach 'n Go dan HelloChinese. Teach 'n Go adalah
perangkat lunak manajemen untuk lembaga pendidikan swasta, termasuk sekolah
bahasa, yang menyediakan penjadwalan dengan pencegahan bentrok, absensi,
penagihan dan pembayaran daring, portal murid, serta aplikasi mobile [20].
HelloChinese adalah aplikasi belajar bahasa Mandarin mandiri dengan pelajaran
berbasis tingkat HSK, latihan mendengarkan dan membaca, pengenalan suara
untuk latihan pelafalan, dan pelacak kemajuan belajar, tetapi tanpa
pengelolaan kelas, absensi, maupun peran guru dan admin [12]. Perbandingan
fiturnya ditunjukkan pada Tabel 4.5.

Tabel 4.5
Perbandingan Fitur dengan Aplikasi Sejenis

| No | Fitur | Sistem baru | Teach 'n Go | HelloChinese |
|---|---|---|---|---|
| 1 | Login dan notifikasi | V | V | V |
| 2 | Peran admin, guru, dan murid | V | V | X |
| 3 | Penjadwalan kelas dan guru dengan pengecekan bentrok | V | V | X |
| 4 | Absensi kelas | V | V | X |
| 5 | Paket sesi (voucher) dengan masa berlaku | V | X | X |
| 6 | Pembayaran kursus daring | V | V | X |
| 7 | Pembayaran lokal (Virtual Account, e-wallet, QRIS) | V | X | X |
| 8 | Soal latihan Listening dan Reading | V | X | V |
| 9 | Soal Typing hanzi | V | X | X |
| 10 | Tes simulasi HSK dengan kode tes dan pengawasan | V | X | X |
| 11 | Penilaian otomatis | V | X | V |
| 12 | Laporan progress murid | V | V | V |
| 13 | Pemantauan progress oleh guru dan admin | V | V | X |
| 14 | Latihan berbicara dengan pengenalan suara | X | X | V |
| 15 | Materi pelajaran untuk belajar mandiri | X | X | V |

Teach 'n Go unggul dalam pengelolaan operasional lembaga tetapi tidak
menyediakan latihan dan ujian bahasa Mandarin, sedangkan HelloChinese unggul
dalam materi belajar mandiri tetapi tidak dapat dipakai untuk mengelola kursus
tatap muka. Sistem baru menggabungkan kedua sisi tersebut dalam satu aplikasi
dan menambahkan hal yang belum dimiliki keduanya: paket sesi dengan masa
berlaku, pembayaran lokal Indonesia, soal Typing hanzi, serta kenaikan tingkat
berdasarkan tes simulasi HSK beserta leaderboard per kode tes. Kekurangannya
dibandingkan HelloChinese adalah tidak adanya materi belajar mandiri dan
latihan berbicara, karena materi dan latihan berbicara diberikan guru di kelas
tatap muka.

Sistem baru juga dibandingkan dengan tugas akhir "Aplikasi Multiplatform
Pembelajaran Bahasa Mandarin Menggunakan Framework Flutter" karya Angelita
Jesslyn [13], mahasiswa ISTTS, yang sama-sama memakai Flutter untuk
pembelajaran bahasa Mandarin (Tabel 4.6). Perbedaan utamanya adalah bahwa
karya Jesslyn berfokus pada pembelajaran dan pengajaran daring dengan
materi, sedangkan sistem baru berfokus pada pengelolaan kursus tatap muka:
pendaftaran, voucher, sesi kelas, dan kenaikan tingkat.

Tabel 4.6
Perbandingan dengan Tugas Akhir Angelita Jesslyn

| No | Fitur | Sistem baru | Tugas akhir Jesslyn |
|---|---|---|---|
| 1 | Login dan notifikasi | V | V |
| 2 | Registrasi mandiri | V | X |
| 3 | Voucher kursus dan sesi kelas | V | X |
| 4 | Soal latihan Listening, Reading, dan Typing | V | V |
| 5 | Soal ujian Listening, Reading, dan Typing | V | V |
| 6 | Materi pengajaran | X | V |
| 7 | Pengajaran daring | X | V |
| 8 | Nilai, profil, dan peringkat | V | V |

Dari pengamatan aplikasi belajar mandiri, pemilik menyampaikan satu
keinginan tambahan: saat murid mengulang bagian mendengarkan, transkrip
rekaman ditampilkan mengikuti suara seperti lirik karaoke agar murid melihat
kata yang sedang didengar. Sistem baru menyimpan transkrip setiap rekaman
dan menampilkannya bersama ulasan jawaban; penyorotan kata yang mengikuti
suara dicatat sebagai saran pengembangan pada Bab VIII.

## 4.4 Spesifikasi Kebutuhan Sistem

Kebutuhan sistem disusun dari masalah pada Tabel 4.4, keinginan pemilik,
dan daftar peran pada proposal tugas akhir. Keinginan pemilik yang paling
utama adalah: murid dapat melihat sendiri sisa sesinya serta latihan yang
sudah dan belum dikerjakan; admin tidak lagi menghitung sisa sesi; guru
terbantu oleh pemeriksaan otomatis; dan orang tua dapat melihat perkembangan
anaknya. Kebutuhan fungsional dikelompokkan per peran, diikuti kebutuhan
non-fungsional.

### 4.4.1 Kebutuhan Admin

- Menyetujui atau menolak pendaftaran murid baru, menetapkan tingkat awal
  dan guru, serta mengelola akun guru, murid, dan orang tua.
- Mengelola bank soal, lembar kerja, paket latihan, dan kode tes simulasi,
  termasuk membaca naskah soal HSK lama dari PDF.
- Menyusun jadwal mingguan kelas dan guru dengan pengecekan bentrok guru dan
  ruang, menunjuk guru pengganti dan guru pendamping, serta membuat sesi
  kelas secara otomatis untuk dua minggu ke depan.
- Mengelola paket voucher dan daftar harga, mencatat pembayaran tunai atau
  transfer, memantau pembayaran daring, dan melihat voucher yang hampir
  habis atau kedaluwarsa.
- Mengatur aturan kenaikan tingkat dan menyetujui atau menolak rekomendasi
  kenaikan.
- Melihat laporan progress seluruh murid, laporan bulanan (murid baru,
  pendapatan, murid aktif, jam mengajar), dan mengirim pengumuman.

### 4.4.2 Kebutuhan Guru

- Melihat jadwal mengajar dan sesi hari ini; sesi dimulai otomatis pada jam
  mulai dan ditutup guru setelah absensi diperiksa.
- Mengisi absensi (hadir, izin, alpa) yang langsung mengurangi sisa sesi
  murid saat sesi ditutup.
- Melihat data murid di kelasnya: level, sisa sesi, kehadiran terakhir, dan
  riwayat latihan.
- Menulis soal dan lembar kerja sendiri, menyusun paket latihan, dan
  menugaskannya kepada murid.
- Membuka dan mengawasi tes simulasi, menilai jawaban tulis bebas, dan
  meninjau jawaban Typing yang ditandai sistem.
- Melihat laporan progress dan peringatan murid, menulis catatan tindak
  lanjut, dan melihat leaderboard dengan nama lengkap murid.

### 4.4.3 Kebutuhan Murid dan Orang Tua

- Mendaftar sendiri dengan pilihan tes penempatan, lalu menunggu persetujuan
  admin.
- Melihat sisa sesi, masa berlaku voucher, dan riwayat pemakaiannya, serta
  membeli paket baru dengan pembayaran daring.
- Memesan tempat pada sesi kelas yang kuotanya tersedia, membatalkan
  pesanan, dan masuk daftar tunggu bila penuh.
- Mengerjakan latihan yang ditugaskan dan melihat mana yang sudah dan belum
  dikerjakan beserta nilainya.
- Mengikuti tes simulasi dengan kode tes, melihat nilai per bagian,
  leaderboard, dan syarat kenaikan tingkat.
- Orang tua menautkan akunnya dengan kode anak untuk melihat progress,
  kehadiran, dan tagihan anaknya serta membayar.

### 4.4.4 Kebutuhan Non-Fungsional

- Multiplatform: murid memakai telepon Android maupun iPhone, guru memakai
  telepon di kelas (ke depan tablet), dan admin bekerja di PC, sehingga
  aplikasi harus berjalan di web, Android, dan iOS dari satu basis kode.
- Privasi: murid melihat murid lain hanya dengan nama Mandarin, data pribadi
  hanya dibaca staf, dan besaran honor guru tidak ditampilkan karena
  pembayaran honor masih manual.
- Keamanan: kunci jawaban tidak pernah dikirim ke perangkat murid; penilaian,
  pemotongan sesi, dan pengecekan bentrok dijalankan di server dengan aturan
  akses per peran.
- Konsistensi data: pemotongan sesi dan pencatatan pemakaian voucher terjadi
  dalam satu transaksi dan tidak terulang bila operasi yang sama dijalankan
  dua kali.
- Bahasa antarmuka: Indonesia dan Inggris dapat dipilih setiap pengguna;
  pemilik menginginkan antarmuka Mandarin agar murid terbiasa membaca hanzi,
  yang dicatat sebagai pengembangan berikutnya.
- Biaya operasional: memakai layanan Firebase dengan paket berbayar sesuai
  pemakaian dan Midtrans dengan biaya per transaksi, tanpa server sendiri.
