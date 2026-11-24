# BAB III
# PROSES BISNIS

Bab ini menjelaskan proses bisnis yang berjalan di Easy Study sebelum
aplikasi dibuat (sistem lama). Pemahaman atas sistem lama diperlukan untuk
melihat di mana letak masalahnya dan bagian mana yang diubah oleh sistem
baru. Bab ini berisi profil Easy Study, deskripsi proses yang berjalan,
pemodelan proses dalam bentuk rich picture, use case diagram, dan activity
diagram, serta permasalahan yang ditemukan.

## 3.1 Profil Easy Study

Easy Study (易华文教中心) adalah lembaga kursus bahasa Mandarin di
Surabaya yang berdiri sejak ⟦1994⟧ dan beralamat di Jl. Manyar Tirtomoyo
VII/11, Surabaya.
Easy Study mengajarkan bahasa Mandarin secara tatap muka dari tingkat
HSK 1 sampai HSK 6. Keenam tingkat dikelompokkan menjadi tiga level, yaitu
Beginner (HSK 1–2), Intermediate (HSK 3–4), dan Advance (HSK 5–6). Kelas
bersifat semi-privat dengan enam sampai delapan kursi per kelas dan
dilaksanakan di dua ruang, yaitu ruang utama dan ruang kecil.

Pada saat tugas akhir ini disusun, Easy Study dikelola oleh satu admin (T)
yang mengurus voucher murid, layanan pelanggan, kebutuhan murid, dan
penyiapan materi cetak, serta empat guru (W, S, M, dan W) yang mengajar dan
merawat materi ajar, termasuk mendigitalkan dan memperbaikinya. Profil guru
dan level yang diajarkan ditunjukkan pada Tabel 3.1, sedangkan sebaran murid
aktif per level ditunjukkan pada Tabel 3.2. Pada November 2026 tercatat 54
murid aktif dengan 62 paket yang sedang berjalan (33 paket enam belas
pertemuan dan 29 paket delapan pertemuan), sekitar seratus kehadiran murid
per bulan pada Oktober dan November 2026, dan [ISI: jumlah] tes simulasi HSK
per bulan.

Tabel 3.1
Guru Easy Study dan Level yang Diajarkan

| No | Guru | Level yang diajarkan | Hari mengajar |
|---|---|---|---|
| 1 | W | [ISI] | [ISI] |
| 2 | S | [ISI] | [ISI] |
| 3 | M | [ISI] | [ISI] |
| 4 | W | [ISI] | [ISI] |

Tabel 3.2
Sebaran Murid Aktif per Level

| Level | Tingkat | Jumlah murid aktif | Kelas per minggu |
|---|---|---|---|
| Beginner | HSK 1–2 | [ISI] | [ISI] |
| Intermediate | HSK 3–4 | [ISI] | [ISI] |
| Advance | HSK 5–6 | [ISI] | [ISI] |
| Total | | 54 | [ISI] |

Murid membeli paket kursus berupa sejumlah sesi (delapan atau enam
belas sesi) dengan masa berlaku tertentu. Pada sistem lama murid
menyepakati hari les saat mendaftar, tetapi setiap hari bebas memilih sesi
yang cocok; dalam satu sesi biasanya dua guru mengajar bersama murid dari
berbagai tingkat dalam satu ruang, sedangkan guru lainnya siaga dan
mengerjakan tugas lain. Pemilik usaha tidak menangani operasional harian;
admin meneruskan setiap pemberitahuan pembayaran kepadanya. Selain kelas,
Easy Study menyelenggarakan tes simulasi HSK untuk mengukur kesiapan murid
naik tingkat dan mengikuti ujian HSK resmi.

## 3.2 Deskripsi Sistem Saat Ini

Sebelum aplikasi dibuat, hampir seluruh proses di Easy Study dijalankan
secara manual dengan bantuan WhatsApp, spreadsheet, dan kertas. Proses
tersebut diuraikan per kegiatan berikut.

### 3.2.1 Pendaftaran Murid

Calon murid atau orang tuanya menghubungi admin melalui WhatsApp atau
datang langsung ke Easy Study, sebagian setelah mengenalnya dari Instagram.
Tidak ada kelas percobaan gratis. Admin menjelaskan kelas, biaya, dan jam
sesi, lalu mengirim tautan Google Form pendaftaran; data diri yang diisi
calon murid terkumpul di spreadsheet Google Form. Isian formulir tersebut
dirangkum pada Tabel 3.3; di dalamnya calon murid juga memilih paket,
tingkat awal, dan menyetujui ketentuan masa berlaku paket.

Tabel 3.3
Isian Formulir Pendaftaran Siswa Baru (Google Form)

| No | Isian | Pilihan atau keterangan |
|---|---|---|
| 1 | Email dan tanggal masuk les | Isian bebas dan tanggal |
| 2 | Durasi pilihan les | 16 pertemuan (24 jam) Rp3.950.000, minimal dua kali seminggu; 8 pertemuan (12 jam) Rp2.450.000, minimal sekali seminggu |
| 3 | Mulai dari level | Basic/HSK 1 sampai HSK 6 |
| 4 | Nama Indonesia dan nama Mandarin | Nama Mandarin dalam pinyin atau hanzi, boleh difoto |
| 5 | Jenis kelamin, alamat, tanggal lahir | Isian bebas dan tanggal |
| 6 | Nomor WhatsApp murid dan orang tua/wali | Beserta nama orang tua/wali |
| 7 | Pendidikan dan nama sekolah/perusahaan | SMP, SMA, mahasiswa, pekerja, lainnya |
| 8 | Tujuan les dan sumber informasi | Studi atau pekerjaan; Google, teman, Instagram/Facebook, seminar, keluarga, lainnya |
| 9 | Pernyataan persetujuan | Masa berlaku paket dua bulan sejak tanggal mulai; sisa pertemuan setelah itu hangus kecuali libur resmi atau kondisi yang disetujui bersama |
 Penentuan tingkat awal
mengikuti keinginan calon murid: admin menanyakan apakah ia ingin mulai dari
Beginner atau mengikuti tes singkat yang diberikan guru; tidak ada tes
penempatan yang terstandar. Setiap murid menyepakati hari les tertentu saat
mendaftar, tetapi murid bebas memilih sesi lain yang lebih cocok dengan
kesibukannya. Caranya, setelah kelas terakhir hari itu berakhir pukul 18.00,
admin mengirim daftar sesi untuk hari berikutnya ke grup WhatsApp siswa
(misalnya Sesi 1 pukul 15.00–16.30 dan Sesi 2 pukul 16.30–18.00,
masing-masing delapan tempat), lalu murid menuliskan namanya pada sesi yang
dipilih, seperti pada Gambar 3.1. Orang tua murid yang masih kecil ikut
berada di grup tersebut. Tidak ada jadwal guru atau jadwal kelas yang tertulis selain
daftar harian tersebut. Jika seorang guru berhalangan, admin menghubungi guru
lain satu per satu melalui chat untuk mencari pengganti, lalu memberi tahu
murid yang terdaftar.

[GAMBAR 3.1: tangkapan layar daftar sesi harian di grup WhatsApp siswa, nama
dan nomor disamarkan]

Gambar 3.1
Daftar Sesi Harian di Grup WhatsApp Siswa pada Sistem Lama

### 3.2.2 Pembayaran dan Paket Sesi

Murid membayar paket enam belas pertemuan (Rp3.950.000) atau delapan
pertemuan (Rp2.450.000) melalui transfer bank atau tunai; masa berlaku paket
dua bulan sejak tanggal mulai, dan sisa pertemuan setelah itu hangus kecuali
ada libur resmi atau kesepakatan tertentu. Untuk transfer, murid mengirim bukti transfer melalui WhatsApp
kepada admin, dan admin meneruskannya kepada pemilik usaha. Admin kemudian
menulis kwitansi fisik untuk murid dan mencatat paket baru pada file Excel
voucher aktif. Sisa sesi setiap murid dihitung secara manual dari daftar
hadir kertas: sehari setelah kelas, admin mengurangi satu sesi dari paket
setiap murid yang hadir. Masa berlaku paket juga dipantau secara manual;
admin mengingatkan murid lewat chat bila paketnya hampir habis atau
mendekati akhir masa berlaku, dan paket yang sudah lewat masa berlakunya
kadang baru diketahui belakangan.

### 3.2.3 Kehadiran

Guru mencatat kehadiran murid pada daftar hadir kertas di setiap
pertemuan, seperti pada Gambar 3.2: nama murid, jam masuk, dan lama belajar
(1,5 jam untuk satu sesi atau 3 jam untuk dua sesi berturut-turut), satu
blok per hari. Daftar hadir tersebut dikumpulkan ke
admin secara berkala untuk diperiksa dan dipakai sebagai dasar pengurangan
sisa sesi. Murid yang izin sebelum kelas dimulai tidak dipotong sesinya,
sedangkan murid yang tidak hadir tanpa kabar (alpa) tetap dipotong satu
sesi. Karena pencatatan dan pengurangan dilakukan terpisah dan manual,
selisih antara sisa sesi menurut admin dan menurut murid kadang terjadi.

[GAMBAR 3.2: foto daftar hadir kertas]

Gambar 3.2
Daftar Hadir Kertas pada Sistem Lama

### 3.2.4 Latihan dan Tes Simulasi HSK

Soal latihan dibagikan dalam bentuk kertas atau fotokopi dan dikoreksi
manual oleh guru. Tes simulasi HSK diberikan ketika guru menilai seorang
murid sudah mencapai titik tertentu atau sudah lama tidak dites, dengan
sedikit keacakan agar kemampuan murid yang sebenarnya terlihat. Soalnya
diambil dari arsip soal HSK tahun-tahun sebelumnya (sekitar empat belas tahun)
yang dicetak dan distok oleh admin; setiap paket soal dikenali dengan kode
tes, misalnya H3216917Z untuk HSK 3. Murid mengerjakannya di atas kertas di
Easy Study, guru mengawasi dan memutar rekaman bagian mendengarkan. Setelah
dikoreksi, guru menghitung nilai per bagian (mendengarkan, membaca, dan
menulis) mengikuti format hasil HSK resmi seperti pada Gambar 3.3, dan murid
dianggap lulus bila mencapai sekitar 60 % pada setiap bagian. Nilai per
bagian dimasukkan satu per satu ke aplikasi web Nilai Simulasi HSK (Gambar
3.4), aplikasi web sederhana yang hanya menyimpan nilai per murid dan
terpisah dari data murid lainnya (pendaftaran, kehadiran, dan paket). Kenaikan tingkat diputuskan guru setelah murid lulus
sekitar dua sampai tiga tes simulasi dan menyelesaikan sejumlah latihan;
murid hanya diberi tahu secara lisan bahwa ia naik ke tingkat berikutnya.

[GAMBAR 3.3: tangkapan layar halaman hasil HSK resmi, data pribadi
disamarkan]

Gambar 3.3
Format Hasil HSK Resmi yang Diikuti oleh Penilaian Tes Simulasi

[GAMBAR 3.4: tangkapan layar halaman awal aplikasi web Nilai Simulasi HSK]

Gambar 3.4
Aplikasi Web Nilai Simulasi HSK pada Sistem Lama

### 3.2.5 Pemantauan Perkembangan Murid

Perkembangan belajar murid tidak terdokumentasi secara terpusat. Catatan
tentang kemampuan murid ada pada masing-masing guru, nilai simulasi ada di
aplikasi web terpisah, kehadiran ada di kertas, dan sisa paket ada di
spreadsheet. Pemilik usaha harus bertanya kepada setiap guru untuk
mengetahui kemampuan seorang murid, dan orang tua murid hanya menerima
kabar jika bertanya. Rekap bulanan tentang murid baru, pendapatan, dan jam
mengajar guru dibuat secara manual pada akhir bulan.

## 3.3 Pemodelan Sistem Saat Ini

Proses pada sistem lama dimodelkan dalam tiga bentuk, yaitu rich picture
untuk menggambarkan seluruh pihak dan aliran informasi secara utuh, use case
diagram untuk menggambarkan kegiatan setiap pihak, dan activity diagram
untuk menggambarkan urutan langkah pada proses-proses utama.

### 3.3.1 Rich Picture

Rich picture sistem lama ditunjukkan pada Gambar 3.5. Terdapat lima
pihak yang terlibat, yaitu calon murid, murid, admin, guru, dan pemilik usaha,
serta empat alat bantu, yaitu WhatsApp, spreadsheet, daftar hadir kertas, dan
aplikasi web Nilai Simulasi HSK. Hampir semua aliran informasi melewati
admin: pendaftaran, pertanyaan jam belajar, bukti transfer, konfirmasi kehadiran,
dan permintaan guru pengganti datang kepada admin melalui WhatsApp, lalu
admin mencatatnya di spreadsheet. Guru menerima kabar murid baru beserta
jam belajarnya dari admin, mencatat kehadiran di kertas, mengoreksi latihan dan tes di kertas, lalu
menyetorkan daftar hadir dan nilai kepada admin. Pemilik usaha memperoleh
gambaran keadaan kursus dengan bertanya kepada admin dan guru.

[GAMBAR 3.5: rich picture sistem lama]

Gambar 3.5
Rich Picture Sistem Saat Ini

### 3.3.2 Use Case Diagram Sistem Saat Ini

Use case diagram sistem lama ditunjukkan pada Gambar 3.6. Aktor calon
murid menghubungi admin melalui WhatsApp atau datang langsung, mengisi
Google Form data diri, dan memilih mulai dari Beginner atau mengikuti tes
singkat. Aktor murid (beserta orang tuanya) membayar paket, mengirim bukti
transfer, menuliskan nama pada daftar sesi harian, mengikuti sesi, mengerjakan
latihan dan tes simulasi di kertas, dan menanyakan sisa sesi. Aktor admin
mengirim tautan Google Form, meneruskan bukti transfer kepada pemilik usaha,
menulis kwitansi dan mencatat paket di Excel voucher, mengirim daftar sesi
harian, mengurangi sesi dari daftar hadir kertas, mengingatkan paket yang
hampir habis, mencetak dan menstok soal HSK lama, mencari guru pengganti,
dan membuat rekap bulanan. Aktor guru memberi tes singkat, mengajar sesi
bertingkat campuran, mencatat kehadiran di kertas, mengawasi tes dan memutar
rekaman, mengoreksi, serta memutuskan kapan murid dites dan naik tingkat.
Aktor pemilik usaha menerima pemberitahuan pembayaran, menanyakan
perkembangan murid, dan membaca rekap bulanan. Semua use case tersebut
dilakukan tanpa sistem yang terhubung.

[GAMBAR 3.6: use case diagram sistem lama]

Gambar 3.6
Use Case Diagram Sistem Saat Ini

### 3.3.3 Activity Diagram Sistem Saat Ini

Dua proses utama sistem lama digambarkan dalam activity diagram, yaitu
pendaftaran dan pembayaran serta tes simulasi dan kenaikan tingkat.

Gambar 3.7 menggambarkan pendaftaran dan pembayaran. Calon murid
menghubungi admin melalui WhatsApp atau datang langsung; admin menjelaskan
kelas, biaya, dan jam sesi, lalu mengirim tautan Google Form yang diisi calon
murid. Admin menanyakan apakah calon murid ingin mulai dari Beginner atau
mengikuti tes singkat; bila memilih tes, guru memberi tes singkat lisan dan
menentukan tingkat awal. Admin menyebutkan paket delapan atau enam belas
sesi beserta harganya, lalu calon murid membayar dengan transfer atau tunai.
Bukti transfer dikirim kepada admin dan diteruskan kepada pemilik usaha.
Admin menulis kwitansi fisik, mencatat paket di Excel voucher aktif, dan
memasukkan murid ke grup WhatsApp siswa.

[GAMBAR 3.7: activity diagram pendaftaran dan pembayaran pada sistem lama]

Gambar 3.7
Activity Diagram Pendaftaran dan Pembayaran pada Sistem Saat Ini

Gambar 3.8 menggambarkan tes simulasi dan kenaikan tingkat. Guru
menilai bahwa seorang murid perlu dites, karena sudah lama tidak dites atau
sudah mencapai titik tertentu. Admin mengambil soal HSK lama yang sudah
dicetak dari stok arsip; guru mengawasi tes dan memutar rekaman bagian
mendengarkan, sementara murid mengerjakannya di kertas. Guru mengoreksi dan
menghitung nilai per bagian. Bila nilai belum mencapai sekitar 60 % pada
setiap bagian, murid melanjutkan latihan dan dites ulang kemudian. Bila lulus,
guru mencatat nilai dan menghitung tes yang sudah lulus; setelah dua sampai
tiga tes lulus dan latihan dianggap cukup, guru menyatakan murid naik tingkat
dan memberitahukannya secara lisan.

[GAMBAR 3.8: activity diagram tes simulasi dan kenaikan tingkat pada sistem lama]

Gambar 3.8
Activity Diagram Tes Simulasi dan Kenaikan Tingkat pada Sistem Saat Ini

## 3.4 Permasalahan pada Sistem Saat Ini

Berdasarkan uraian dan pemodelan di atas, permasalahan utama sistem lama
dirangkum pada Tabel 3.4 beserta penyebab dan akibatnya, diurutkan dari yang
paling dirasakan oleh pemilik usaha. Permasalahan
tersebut menjadi dasar analisis kebutuhan pada Bab IV dan dijawab oleh
rancangan sistem baru pada Bab V.

Tabel 3.4
Permasalahan pada Sistem Saat Ini

| No | Masalah | Penyebab | Akibat |
|---|---|---|---|
| 1 | Guru pengganti sulit dicari | Hanya ada empat guru; ketersediaan dan level yang diajar tidak tercatat di satu tempat | Admin menghubungi guru satu per satu lewat chat; murid terlambat diberi tahu |
| 2 | Perkembangan murid tidak terpantau | Catatan ada pada masing-masing guru; kapan murid terakhir datang hanya diketahui admin | Guru dan pemilik tidak tahu sejauh mana dan sampai kapan murid belajar; murid yang tertinggal terlambat ditangani |
| 3 | Tidak ada rekap bulanan | Murid baru, pendapatan, dan jam mengajar tersebar di Excel, kwitansi, dan daftar hadir | Pemilik tidak punya gambaran usaha tanpa menanyai admin |
| 4 | Tidak ada jadwal guru dan kelas | Daftar sesi dikirim manual setiap sore; pemakaian guru dan ruang tidak tercatat | Admin kadang lupa mengirim daftar sesi; murid tidak tahu kelas esok dibuka atau tidak |
| 5 | Selisih sisa sesi paket | Sisa sesi dikurangi sehari kemudian dari daftar hadir kertas ke Excel | Perselisihan sisa sesi antara admin dan murid; masa berlaku dua bulan tidak terpantau |
| 6 | Data murid tersebar | Google Form, Excel daftar siswa, Excel term, kertas, dan aplikasi web nilai | Data sulit dicari dan tidak sinkron antarsumber |
| 7 | Kenaikan tingkat tidak terstandar | Keputusan guru setelah dua sampai tiga tes tanpa aturan tertulis | Syarat naik tingkat berbeda antarguru; murid tidak tahu syaratnya |
| 8 | Koreksi latihan dan tes manual | Latihan dan tes di kertas, dikoreksi guru, nilai diketik ulang ke aplikasi web terpisah | Umpan balik lambat; pekerjaan ganda bagi guru |
| 9 | Pencatatan pembayaran manual | Bukti transfer diteruskan lewat chat, kwitansi tulis tangan, paket dicatat di Excel | Pekerjaan berulang admin; menurut pemilik bukan masalah besar |

Kesembilan masalah tersebut bermuara pada tiga hal: data yang tersebar,
pekerjaan berulang yang dilakukan manual oleh admin, dan tidak adanya
gambaran perkembangan murid yang dapat dipantau. Sistem baru yang
dirancang pada bab berikutnya memindahkan seluruh proses tersebut ke dalam
satu aplikasi dengan basis data terpusat dan logika penting yang dijalankan di
server.
