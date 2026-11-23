# BAB II
# TEORI PENUNJANG

Bab ini menjelaskan teori dan teknologi yang menjadi dasar pembuatan
Aplikasi Multiplatform Sistem Kursus Bahasa Mandarin Easy Study. Teori
yang dibahas meliputi bahasa pemrograman Dart, framework Flutter,
pengembangan multiplatform, platform Firebase beserta layanan yang dipakai,
Firebase Cloud Functions, Firestore Security Rules, transaksi Firestore, basis
data NoSQL, arsitektur MVVM, payment gateway Midtrans, tes HSK,
pencocokan teks dengan jarak Levenshtein dan OpenCC, System Usability
Scale, dan black-box testing.

## 2.1 Dart

Dart adalah bahasa pemrograman sumber terbuka yang dikembangkan oleh
Google dan menjadi bahasa utama dalam pengembangan aplikasi Flutter. Dart
bersifat berorientasi objek dan type-safe dengan dukungan null safety,
sehingga banyak kesalahan dapat ditemukan saat kompilasi, bukan saat
aplikasi dijalankan. Dart mendukung kompilasi Just-in-Time (JIT) yang
memungkinkan fitur hot reload selama pengembangan, serta kompilasi
Ahead-of-Time (AOT) yang menghasilkan kode native untuk Android dan iOS
dan kompilasi ke JavaScript atau WebAssembly untuk platform web [6].

Dart juga menyediakan dukungan pemrograman asinkron melalui Future,
async/await, dan Stream. Future mewakili satu nilai yang akan tersedia di
masa depan, misalnya hasil pemanggilan Cloud Functions, sedangkan Stream
mewakili rangkaian nilai yang datang berulang, misalnya perubahan dokumen
Cloud Firestore. Pada aplikasi ini Stream dipakai untuk menampilkan data
secara langsung ketika data di basis data berubah, seperti status sesi kelas
atau status pembayaran.

## 2.2 Flutter

Flutter adalah framework sumber terbuka yang dikembangkan oleh Google
untuk membangun aplikasi multiplatform (Android, iOS, web, dan desktop)
dari satu basis kode menggunakan bahasa Dart [11]. Flutter menggunakan
pendekatan berbasis widget: seluruh elemen antarmuka pengguna, dari tombol
sampai tata letak halaman, dibangun dari susunan widget yang dapat
dikustomisasi dan dipakai ulang. Flutter memiliki mesin rendering sendiri,
sehingga tampilan aplikasi konsisten di berbagai perangkat dan tidak
bergantung pada komponen bawaan sistem operasi.

Fitur hot reload mempercepat proses pengembangan karena perubahan
kode dapat langsung terlihat tanpa menjalankan ulang aplikasi. Flutter juga
menyediakan integrasi resmi dengan Firebase melalui kumpulan paket
FlutterFire untuk kebutuhan autentikasi, basis data, penyimpanan berkas, dan
notifikasi. Pada aplikasi ini versi web Flutter menjadi versi utama yang
dipakai di Easy Study, sedangkan versi Android dibangun dari basis kode yang
sama.

## 2.3 Pengembangan Multiplatform

Pengembangan multiplatform adalah pendekatan pengembangan perangkat
lunak yang memungkinkan satu aplikasi berjalan di berbagai sistem operasi,
seperti Android, iOS, dan web, dengan satu basis kode. Framework
multiplatform seperti Flutter, React Native, atau Xamarin memungkinkan
pengembang menulis kode sekali dan menjalankannya di berbagai platform,
sehingga biaya pengembangan dan pemeliharaan lebih rendah dan pengalaman
pengguna lebih konsisten antarperangkat. Bagi lembaga kursus kecil seperti
Easy Study, pendekatan ini penting karena murid memakai perangkat yang
beragam: telepon Android, iPhone, dan komputer dengan peramban web.

## 2.4 Firebase

Firebase adalah platform Backend-as-a-Service (BaaS) yang dikembangkan
oleh Google untuk mendukung pengembangan aplikasi mobile dan web tanpa
perlu membangun dan mengelola server sendiri [7]. Firebase dapat
diintegrasikan dengan Flutter melalui paket resmi FlutterFire. Layanan
Firebase yang digunakan pada aplikasi ini adalah sebagai berikut.

### 2.4.1 Cloud Firestore

Cloud Firestore adalah basis data NoSQL berbasis dokumen yang
menyimpan data dalam koleksi (collection) dan dokumen (document). Setiap
dokumen berisi pasangan field dan nilai, dan dapat memiliki subkoleksi.
Firestore menyinkronkan data secara langsung (real-time) ke semua aplikasi
yang mendengarkan dokumen atau kueri yang sama, mendukung mode luring,
dan diskalakan secara otomatis. Firestore juga menyediakan transaksi dan
batched writes untuk mengubah beberapa dokumen secara atomik (lihat 2.7),
serta Security Rules untuk mengatur hak akses setiap permintaan (lihat 2.6).

### 2.4.2 Firebase Authentication

Firebase Authentication menangani pendaftaran, login, dan pengelolaan
akun pengguna. Pada aplikasi ini dipakai metode email dan kata sandi.
Setiap pengguna yang masuk memperoleh ID token yang dikirim secara
otomatis pada setiap permintaan ke Firestore dan Cloud Functions, sehingga
server selalu mengetahui siapa yang meminta dan dapat memeriksa perannya.

### 2.4.3 Cloud Storage

Cloud Storage for Firebase menyimpan berkas, misalnya audio soal
Listening, gambar pada soal, dan foto profil. Berkas disimpan di dalam
bucket dengan aturan akses tersendiri, dan aplikasi mengaksesnya melalui
URL yang diberikan Firebase.

### 2.4.4 Firebase Cloud Messaging

Firebase Cloud Messaging (FCM) mengirimkan notifikasi kepada pengguna
di Android, iOS, dan web. Pada aplikasi ini FCM dipakai untuk pengingat
sesi, pemberitahuan jadwal baru atau guru pengganti, hasil pembayaran,
rekomendasi kenaikan tingkat, dan peringatan progress murid. Notifikasi
dikirim oleh Cloud Functions, bukan oleh aplikasi di perangkat pengguna.

### 2.4.5 Firebase Hosting

Firebase Hosting menyajikan berkas statis aplikasi web (HTML, JavaScript,
dan aset) melalui jaringan pengiriman konten global dengan sertifikat HTTPS.
Versi web aplikasi ini diterapkan pada Firebase Hosting sehingga dapat
diakses dari peramban di komputer maupun telepon.

## 2.5 Firebase Cloud Functions

Cloud Functions for Firebase adalah layanan serverless yang menjalankan
kode backend (JavaScript atau TypeScript pada lingkungan Node.js) secara
otomatis sebagai respons terhadap suatu kejadian, tanpa perlu mengelola
server sendiri [8]. Jenis pemicu yang dipakai pada aplikasi ini ditunjukkan
pada Tabel 2.1.

Tabel 2.1
Jenis Pemicu Cloud Functions yang Digunakan

| Jenis pemicu | Cara berjalan | Contoh pada aplikasi |
|---|---|---|
| Callable function | Dipanggil langsung dari aplikasi Flutter; secara otomatis membawa identitas pengguna yang memanggil | Menyimpan jadwal, memesan sesi, menutup sesi, mengumpulkan jawaban tes |
| HTTP request | Dipanggil melalui alamat HTTP oleh layanan pihak ketiga | Webhook notifikasi pembayaran dari Midtrans |
| Trigger Cloud Firestore | Berjalan ketika sebuah dokumen dibuat, diubah, atau dihapus | Memperbarui leaderboard dan ringkasan progress saat nilai tersimpan |
| Scheduled function | Berjalan pada waktu tertentu secara berkala, mirip cron job | Membuat sesi dua minggu ke depan, mengirim pengingat, menonaktifkan voucher kedaluwarsa, laporan bulanan |

Kode pada Cloud Functions berjalan di server dengan hak akses penuh
melalui Firebase Admin SDK, sehingga cocok untuk logika yang tidak boleh
dijalankan atau dimanipulasi di perangkat pengguna. Pada aplikasi ini logika
tersebut meliputi pengecekan bentrok jadwal di dalam transaksi basis data,
pemotongan sisa sesi voucher, penilaian jawaban dengan kunci jawaban yang
dirahasiakan dari murid, serta pembuatan transaksi pembayaran dengan server
key Midtrans. Daftar lengkap fungsi yang digunakan dijelaskan pada Bab V.

## 2.6 Firestore Security Rules

Firestore Security Rules adalah aturan akses yang dijalankan oleh server
Firestore untuk setiap permintaan baca dan tulis yang datang dari aplikasi
klien [9]. Aturan ditulis dalam bahasa khusus yang dapat memeriksa identitas
pengguna (misalnya UID dan peran yang tersimpan pada dokumen
penggunanya), isi dokumen yang diminta, dan isi data yang akan ditulis.
Permintaan yang tidak memenuhi aturan ditolak oleh server, sehingga aplikasi
yang dimodifikasi atau skrip yang memakai SDK secara langsung tetap tidak
dapat membaca atau menulis data yang bukan haknya.

Cloud Functions menggunakan Admin SDK sehingga tidak dibatasi oleh
aturan ini. Pola yang dipakai pada aplikasi ini adalah: data yang menentukan
hasil belajar atau uang (nilai, riwayat voucher, pembayaran, sesi kelas) hanya
dapat ditulis oleh Cloud Functions, sedangkan aplikasi klien hanya dapat
membacanya sesuai perannya. Dengan demikian murid tidak dapat mengubah
nilainya sendiri atau membaca kunci jawaban walaupun ia mencoba mengakses
basis data secara langsung. Aturan ini diuji dengan pengujian otomatis pada
Firebase Emulator Suite.

## 2.7 Transaksi Firestore dan Idempotensi

Transaksi Firestore adalah sekumpulan operasi baca dan tulis yang
dijalankan sebagai satu kesatuan [10]. Transaksi membaca dokumen-dokumen
yang dibutuhkan terlebih dahulu, lalu menulis semua perubahan sekaligus.
Jika salah satu dokumen yang dibaca diubah oleh proses lain sebelum
transaksi selesai, Firestore membatalkan dan mengulang transaksi dari awal
dengan data terbaru. Jika transaksi gagal, tidak ada satu pun perubahan yang
tersimpan (all-or-nothing). Sifat ini dibutuhkan ketika dua proses dapat
mengubah data yang sama pada saat bersamaan, misalnya guru menutup sesi
pada saat murid yang sama sedang memesan sesi lain.

Idempotensi adalah sifat suatu operasi yang memberikan hasil yang sama
walaupun dijalankan lebih dari satu kali. Pada aplikasi ini idempotensi
dicapai dengan memakai ID dokumen yang disusun dari data lain, misalnya ID
riwayat voucher yang disusun dari ID sesi dan ID murid, sehingga catatan
yang sama tidak dapat dibuat dua kali, dan dengan memeriksa status dokumen
di awal transaksi, misalnya sesi yang sudah berstatus selesai tidak ditutup
lagi. Dengan cara ini pemanggilan ulang karena koneksi terputus atau
notifikasi pembayaran yang dikirim dua kali tidak memotong voucher atau
membuat voucher untuk kedua kalinya.

## 2.8 Basis Data NoSQL

Firebase menggunakan model NoSQL untuk basis datanya, yang berbeda
dari sistem basis data relasional tradisional [2]. Ciri-ciri yang relevan dengan
aplikasi ini adalah:

- Schema-less. Basis data NoSQL tidak memiliki skema tetap, sehingga
  struktur dokumen dapat berkembang tanpa migrasi tabel; konsistensi
  struktur dijaga oleh aplikasi dan oleh Security Rules.
- Model data hierarkis. Data disimpan sebagai dokumen berbentuk JSON
  yang dapat memiliki subkoleksi, sehingga data yang selalu dibaca bersama
  dapat disimpan berdekatan.
- Skalabilitas. Basis data NoSQL dirancang untuk menangani data besar
  dengan penskalaan horizontal secara otomatis.

Konsekuensi dari model ini adalah tidak adanya join seperti pada SQL.
Oleh karena itu beberapa data pada aplikasi ini sengaja disalin (denormalisasi),
misalnya nama guru disimpan pada dokumen sesi, dan beberapa ringkasan
dihitung di server lalu disimpan dalam satu dokumen, misalnya ringkasan
progress per murid, agar aplikasi cukup membaca satu dokumen untuk
menampilkan satu halaman.

## 2.9 Arsitektur MVVM

Model-View-ViewModel (MVVM) adalah pola arsitektur perangkat lunak
yang memisahkan logika presentasi dari antarmuka pengguna, sehingga
aplikasi lebih modular, mudah dikelola, dan dapat diuji. Pada aplikasi ini
MVVM diterapkan dengan paket Provider [19], yaitu solusi pengelolaan state
yang dicontohkan dalam dokumentasi resmi Flutter. Konsep-konsep yang
mendasarinya adalah sebagai berikut.

- Separation of Concerns (SoC). Tanggung jawab dipisahkan ke dalam
  bagian yang berbeda: Model menangani data dan logika bisnis, View
  menampilkan antarmuka, dan ViewModel menjadi perantara yang
  mengelola logika presentasi dan menyinkronkan data antara keduanya.
  Pada aplikasi ini hanya lapisan Repository/Service yang berkomunikasi
  dengan Firebase.
- Observable Pattern. ViewModel diturunkan dari ChangeNotifier. Setiap
  kali datanya berubah, ViewModel memanggil notifyListeners() sehingga
  widget yang mendengarkannya dibangun ulang secara otomatis.
- Data Binding. Flutter tidak memiliki data binding dua arah; hubungan
  antara ViewModel dan View dibuat melalui Provider dengan widget
  Consumer atau fungsi context.watch(), sedangkan masukan pengguna
  diteruskan ke ViewModel melalui pemanggilan fungsi.
- Dependency Injection (DI). Repository dan layanan eksternal didaftarkan
  di bagian atas pohon widget dengan MultiProvider dan disuntikkan ke
  ViewModel, bukan dibuat di dalamnya, sehingga setiap bagian dapat diuji
  secara terpisah.
- Reactive Programming. Cloud Firestore menyediakan data dalam bentuk
  Stream melalui fungsi snapshots(); ViewModel mendengarkan Stream
  tersebut, memperbarui datanya, lalu memberi tahu View. Pendekatan ini
  dipakai pada fitur yang membutuhkan data langsung, seperti jadwal kelas,
  absensi, status pembayaran, dan laporan progress.

## 2.10 Midtrans

Midtrans adalah layanan payment gateway di Indonesia yang memungkinkan
aplikasi menerima pembayaran daring melalui berbagai metode, seperti
transfer bank melalui Virtual Account, e-wallet (GoPay dan ShopeePay),
QRIS, dan kartu kredit [15]. Midtrans menyediakan Snap, yaitu halaman
pembayaran siap pakai yang dapat ditampilkan di dalam aplikasi, sehingga
pengembang tidak perlu membangun antarmuka pembayaran sendiri.

Untuk menjaga keamanan, pembuatan transaksi dilakukan di sisi server
menggunakan server key, dan setelah transaksi selesai Midtrans mengirimkan
HTTP notification (webhook) ke server untuk memperbarui status pembayaran
secara otomatis. Setiap notifikasi membawa signature key, yaitu hasil hash
SHA-512 dari order ID, kode status, jumlah, dan server key, sehingga server
dapat memastikan notifikasi benar-benar berasal dari Midtrans. Midtrans juga
menyediakan mode sandbox untuk menguji proses pembayaran tanpa uang
sungguhan; seluruh pengujian pada tugas akhir ini memakai mode tersebut.

## 2.11 HSK (Hanyu Shuiping Kaoshi)

HSK adalah tes standar internasional kemampuan bahasa Mandarin bagi
penutur asing yang diselenggarakan oleh Chinese Testing International [5].
Tes ini memiliki enam tingkatan; setiap tingkat menguji kemampuan
mendengarkan dan membaca, dan mulai HSK 3 juga menulis, dengan kosakata
dan tata bahasa yang berbeda untuk setiap tingkatan. Kesetaraan HSK dengan
CEFR (Common European Framework of Reference for Languages)
memungkinkan tingkat kemampuan dipahami dalam konteks global. HSKK
(Hanyu Shuiping Kouyu Kaoshi) merupakan tes terpisah untuk kemampuan
berbicara dan tidak termasuk dalam ruang lingkup aplikasi ini.

Struktur skor HSK enam tingkat ditunjukkan pada Tabel 2.2. HSK 1 dan
HSK 2 terdiri atas bagian mendengarkan dan membaca dengan skor maksimal
200 dan batas lulus 120, sedangkan HSK 3 sampai HSK 6 terdiri atas bagian
mendengarkan, membaca, dan menulis dengan skor maksimal 300 dan batas
lulus 180. Dengan kata lain, batas lulus HSK berada pada 60% dari skor
maksimal. Struktur ini menjadi acuan sistem level, format tes simulasi, dan
aturan kenaikan tingkat pada aplikasi, yang dijelaskan pada Bab V.

Tabel 2.2
Struktur Skor HSK Enam Tingkat

| Tingkat | Bagian | Skor maksimal | Batas lulus |
|---|---|---|---|
| HSK 1, HSK 2 | Mendengarkan, Membaca | 200 | 120 |
| HSK 3 – HSK 6 | Mendengarkan, Membaca, Menulis | 300 | 180 |

## 2.12 Pencocokan Teks: Jarak Levenshtein dan OpenCC

Jawaban soal Typing dapat ditulis dengan benar dalam beberapa cara,
misalnya pinyin dengan tanda nada atau dengan angka nada, tanda baca lebar
penuh atau lebar setengah, dan hanzi sederhana atau hanzi tradisional. Oleh
karena itu jawaban tidak dicocokkan secara mentah, tetapi dinormalisasi
terlebih dahulu dan diberi toleransi untuk kesalahan kecil. Dua alat yang
dipakai adalah sebagai berikut.

OpenCC (Open Chinese Convert) adalah pustaka sumber terbuka untuk
mengubah teks antara hanzi tradisional dan hanzi sederhana, termasuk
perbedaan kosakata regional [4]. Pada aplikasi ini OpenCC dipakai untuk
mengubah jawaban murid yang ditulis dengan hanzi tradisional menjadi hanzi
sederhana sebelum dibandingkan dengan kunci, sehingga 謝謝 dinilai sama
dengan 谢谢.

Jarak Levenshtein adalah jumlah minimum operasi penyisipan,
penghapusan, atau penggantian satu satuan yang dibutuhkan untuk mengubah
satu rangkaian menjadi rangkaian lain [14]. Satuan yang dipakai pada aplikasi
ini adalah karakter untuk hanzi dan suku kata untuk pinyin. Kemiripan dua
rangkaian dihitung dengan Rumus 2.1, dengan d adalah jarak Levenshtein
terhadap kunci terdekat dan n adalah panjang terpanjang antara jawaban dan
kunci.

S = 1 − d / n                                                       (2.1)

Nilai S berada pada rentang 0 sampai 1; S = 1 berarti sama persis. Pada
aplikasi ini jawaban dengan d = 1 dan S ≥ 0,75 pada soal tertentu, misalnya
satu karakter homofon yang salah ketik, mendapat nilai sebagian dan ditandai
untuk ditinjau guru. Aturan lengkap pencocokan dijelaskan pada Bab V.

## 2.13 System Usability Scale (SUS)

System Usability Scale (SUS) adalah kuesioner standar untuk mengukur
tingkat kemudahan penggunaan (usability) suatu sistem [3]. SUS terdiri atas
10 pernyataan yang dijawab dengan skala Likert 1 (sangat tidak setuju) sampai
5 (sangat setuju). Pernyataan bernomor ganjil bersifat positif, sedangkan
pernyataan bernomor genap bersifat negatif. Skor SUS satu responden
dihitung dengan Rumus 2.2.

Skor SUS = [ Σ(skor ganjil − 1) + Σ(5 − skor genap) ] × 2,5             (2.2)

Skor SUS berada pada rentang 0–100, lalu dihitung rata-ratanya dari
seluruh responden. Berdasarkan penelitian Bangor dkk. [1], skor di atas 70
tergolong dapat diterima (acceptable), skor 50–70 tergolong marginal, dan
skor di bawah 50 tergolong tidak dapat diterima, seperti pada Tabel 2.3. SUS
mengukur kepuasan dan kemudahan dari sisi pengguna, bukan ketepatan
proses, sehingga pada tugas akhir ini SUS dilengkapi dengan validasi
fungsional (lihat Bab VII).

Tabel 2.3
Interpretasi Skor SUS

| Rata-rata skor SUS | Interpretasi |
|---|---|
| Di atas 70 | Dapat diterima (acceptable) |
| 50 – 70 | Marginal |
| Di bawah 50 | Tidak dapat diterima (not acceptable) |

## 2.14 Black-box Testing

Black-box testing adalah metode pengujian perangkat lunak yang
memeriksa fungsi sistem berdasarkan masukan dan keluaran yang diharapkan,
tanpa melihat struktur kode program di dalamnya [16]. Setiap fitur diuji
menggunakan skenario uji yang mencakup kondisi normal dan kondisi yang
seharusnya ditolak oleh sistem, misalnya menyimpan jadwal yang bentrok atau
memesan sesi ketika sisa voucher nol, sehingga dapat dipastikan bahwa setiap
fitur berjalan sesuai kebutuhan. Hasil black-box testing didokumentasikan
dalam tabel yang berisi fitur, skenario, hasil yang diharapkan, dan hasil
sebenarnya.
