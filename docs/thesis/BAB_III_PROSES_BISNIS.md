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
Surabaya yang berdiri sejak [ISI: tahun] dan beralamat di [ISI: alamat].
Easy Study mengajarkan bahasa Mandarin secara tatap muka dari tingkat
HSK 1 sampai HSK 6. Keenam tingkat dikelompokkan menjadi tiga level, yaitu
Beginner (HSK 1–2), Intermediate (HSK 3–4), dan Advance (HSK 5–6). Kelas
bersifat semi-privat dengan enam sampai delapan kursi per kelas dan
dilaksanakan di dua ruang, yaitu ruang utama dan ruang kecil.

Pada saat tugas akhir ini disusun, Easy Study dikelola oleh satu admin dan
empat guru. Profil guru dan level yang diajarkan ditunjukkan pada Tabel 3.1,
sedangkan sebaran murid aktif per level ditunjukkan pada Tabel 3.2. Dalam
satu bulan Easy Study rata-rata menerima [ISI: jumlah] pembayaran paket
kursus dan menyelenggarakan [ISI: jumlah] tes simulasi HSK.

Tabel 3.1
Guru Easy Study dan Level yang Diajarkan

| No | Guru | Level yang diajarkan | Hari mengajar |
|---|---|---|---|
| 1 | [ISI: inisial guru 1] | [ISI] | [ISI] |
| 2 | [ISI: inisial guru 2] | [ISI] | [ISI] |
| 3 | [ISI: inisial guru 3] | [ISI] | [ISI] |
| 4 | [ISI: inisial guru 4] | [ISI] | [ISI] |

Tabel 3.2
Sebaran Murid Aktif per Level

| Level | Tingkat | Jumlah murid aktif | Kelas per minggu |
|---|---|---|---|
| Beginner | HSK 1–2 | [ISI] | [ISI] |
| Intermediate | HSK 3–4 | [ISI] | [ISI] |
| Advance | HSK 5–6 | [ISI] | [ISI] |
| Total | | [ISI] | [ISI] |

Murid membeli paket kursus berupa sejumlah sesi (delapan atau enam
belas sesi) dengan masa berlaku tertentu, lalu mengikuti kelas pada hari dan
jam yang sudah ditentukan untuk levelnya. Guru pengajar setiap kelas
ditentukan oleh admin; murid tidak memilih guru. Selain kelas, Easy Study
menyelenggarakan tes simulasi HSK secara berkala untuk mengukur kesiapan
murid naik tingkat dan mengikuti ujian HSK resmi.

## 3.2 Deskripsi Sistem Saat Ini

Sebelum aplikasi dibuat, hampir seluruh proses di Easy Study dijalankan
secara manual dengan bantuan WhatsApp, spreadsheet, dan kertas. Proses
tersebut diuraikan per kegiatan berikut.

### 3.2.1 Pendaftaran Murid

Calon murid atau orang tuanya menghubungi admin melalui WhatsApp
untuk menanyakan kelas, biaya, dan jadwal. Admin menjawab satu per satu,
meminta data diri (nama, nama Mandarin, tanggal lahir, nomor telepon, dan
pengalaman belajar), lalu mencatatnya di spreadsheet daftar murid. Penentuan
tingkat awal dilakukan berdasarkan pengakuan calon murid atau tes singkat
yang diberikan guru secara lisan; tidak ada tes penempatan yang terstandar.
Contoh percakapan pendaftaran ditunjukkan pada Gambar 3.1.

[GAMBAR 3.1: tangkapan layar chat WhatsApp pendaftaran, nama dan nomor
disamarkan]

Gambar 3.1
Pendaftaran Murid melalui WhatsApp pada Sistem Lama

### 3.2.2 Penjadwalan Guru dan Kelas

Admin menanyakan ketersediaan setiap guru melalui chat, lalu menyusun
jadwal kelas dan jadwal guru di spreadsheet, seperti pada Gambar 3.2. Jadwal
tersebut dibagikan ke guru dan murid melalui grup WhatsApp. Karena tidak
ada pengecekan otomatis, bentrok jadwal, yaitu satu guru atau satu ruang
terpakai dua kali pada jam yang sama, sering baru diketahui menjelang kelas
dimulai. Jika seorang guru berhalangan, admin mencari guru pengganti dengan
menghubungi guru lain satu per satu melalui chat, lalu memberi tahu murid
yang terdaftar. Murid mengonfirmasi kehadirannya pada kelas berikutnya juga
melalui chat.

[GAMBAR 3.2: tangkapan layar spreadsheet jadwal guru, nama disamarkan]

Gambar 3.2
Spreadsheet Jadwal Guru pada Sistem Lama

### 3.2.3 Pembayaran dan Paket Sesi

Murid membayar paket kursus melalui transfer bank, lalu mengirim foto
bukti transfer melalui WhatsApp. Admin mencocokkan bukti tersebut dengan
mutasi rekening satu per satu dan mencatat pembayaran di spreadsheet. Sisa
sesi setiap murid dihitung secara manual dari daftar hadir: setiap kali murid
hadir, admin mengurangi satu sesi dari paketnya. Masa berlaku paket juga
dipantau secara manual, sehingga paket yang sudah lewat masa berlakunya
kadang baru diketahui belakangan.

### 3.2.4 Kehadiran

Guru mencatat kehadiran murid pada daftar hadir kertas di setiap
pertemuan, seperti pada Gambar 3.3. Daftar hadir tersebut dikumpulkan ke
admin secara berkala untuk diperiksa dan dipakai sebagai dasar pengurangan
sisa sesi. Murid yang izin sebelum kelas dimulai tidak dipotong sesinya,
sedangkan murid yang tidak hadir tanpa kabar (alpa) tetap dipotong satu
sesi. Karena pencatatan dan pengurangan dilakukan terpisah dan manual,
selisih antara sisa sesi menurut admin dan menurut murid kadang terjadi.

[GAMBAR 3.3: foto daftar hadir kertas, nama disamarkan]

Gambar 3.3
Daftar Hadir Kertas pada Sistem Lama

### 3.2.5 Latihan dan Tes Simulasi HSK

Soal latihan dibagikan dalam bentuk kertas atau fotokopi dan dikoreksi
manual oleh guru. Tes simulasi HSK dikerjakan di atas kertas di Easy Study
dengan pengawasan guru. Setelah dikoreksi, nilai per bagian (mendengarkan,
membaca, dan menulis) dimasukkan satu per satu ke aplikasi web Nilai
Simulasi HSK, seperti pada Gambar 3.4. Aplikasi web tersebut hanya
menyimpan nilai dan terpisah dari data murid lainnya (pendaftaran, kehadiran,
dan paket). Setiap paket tes simulasi diberi kode tes, misalnya H3216917Z
untuk tes HSK 3, dan setiap kode berisi soal yang berbeda. Kenaikan tingkat
diputuskan dengan memeriksa riwayat nilai simulasi secara manual.

[GAMBAR 3.4: tangkapan layar aplikasi web Nilai Simulasi HSK]

Gambar 3.4
Aplikasi Web Nilai Simulasi HSK pada Sistem Lama

### 3.2.6 Pemantauan Perkembangan Murid

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
admin: pendaftaran, pertanyaan jadwal, bukti transfer, konfirmasi kehadiran,
dan permintaan guru pengganti datang kepada admin melalui WhatsApp, lalu
admin mencatatnya di spreadsheet. Guru menerima jadwal dari admin,
mencatat kehadiran di kertas, mengoreksi latihan dan tes di kertas, lalu
menyetorkan daftar hadir dan nilai kepada admin. Pemilik usaha memperoleh
gambaran keadaan kursus dengan bertanya kepada admin dan guru.

[GAMBAR 3.5: rich picture sistem lama]

Gambar 3.5
Rich Picture Sistem Saat Ini

```mermaid
%% Alat bantu menggambar Gambar 3.5 (bukan isi buku)
flowchart LR
  CM[Calon murid] -- "tanya & daftar (WhatsApp)" --> A[Admin]
  M[Murid] -- "bukti transfer, konfirmasi hadir, izin (WhatsApp)" --> A
  A -- "catat murid, jadwal, pembayaran, sisa sesi" --> S[(Spreadsheet)]
  A -- "tanya ketersediaan, bagikan jadwal (WhatsApp)" --> G[Guru]
  G -- "daftar hadir kertas" --> K[/Daftar hadir/]
  K -- "disetor berkala" --> A
  G -- "koreksi latihan & tes di kertas" --> M
  G -- "input nilai per bagian" --> W[(Web Nilai Simulasi HSK)]
  P[Pemilik usaha] -- "bertanya" --> A
  P -- "bertanya" --> G
  A -. "bentrok baru ketahuan menjelang kelas" .- G
```

### 3.3.2 Use Case Diagram Sistem Saat Ini

Use case diagram sistem lama ditunjukkan pada Gambar 3.6. Aktor calon
murid mendaftar melalui WhatsApp. Aktor murid mengonfirmasi kehadiran,
mengirim bukti transfer, mengerjakan latihan dan tes di kertas, dan
menanyakan sisa sesi. Aktor guru memberi tahu ketersediaan, mencatat
kehadiran, mengoreksi latihan dan tes, dan memasukkan nilai simulasi ke
aplikasi web. Aktor admin mencatat pendaftaran, menyusun jadwal, mencari
guru pengganti, mencocokkan pembayaran, menghitung sisa sesi, dan
membuat rekap bulanan. Aktor pemilik usaha membaca rekap dan menanyakan
perkembangan murid. Semua use case tersebut dilakukan tanpa sistem yang
terhubung.

[GAMBAR 3.6: use case diagram sistem lama]

Gambar 3.6
Use Case Diagram Sistem Saat Ini

```mermaid
%% Alat bantu menggambar Gambar 3.6 (bukan isi buku)
flowchart LR
  subgraph Sistem lama (manual)
    U1([Mendaftar lewat WhatsApp])
    U2([Konfirmasi hadir / izin])
    U3([Kirim bukti transfer])
    U4([Kerjakan latihan & tes di kertas])
    U5([Tanya sisa sesi])
    U6([Beri tahu ketersediaan])
    U7([Catat kehadiran di kertas])
    U8([Koreksi latihan & tes])
    U9([Input nilai simulasi ke web])
    U10([Catat pendaftaran di spreadsheet])
    U11([Susun jadwal di spreadsheet])
    U12([Cari guru pengganti])
    U13([Cocokkan bukti transfer])
    U14([Hitung sisa sesi manual])
    U15([Buat rekap bulanan])
    U16([Tanya perkembangan murid])
  end
  CM[Calon murid] --> U1
  M[Murid] --> U2 & U3 & U4 & U5
  G[Guru] --> U6 & U7 & U8 & U9
  A[Admin] --> U10 & U11 & U12 & U13 & U14 & U15
  P[Pemilik usaha] --> U15 & U16
```

### 3.3.3 Activity Diagram Sistem Saat Ini

Tiga proses utama sistem lama digambarkan dalam activity diagram, yaitu
pendaftaran dan pembayaran, penjadwalan guru, serta tes simulasi dan
kenaikan tingkat.

Gambar 3.7 menggambarkan pendaftaran dan pembayaran. Calon murid
menghubungi admin melalui WhatsApp, admin menjawab dan meminta data,
lalu mencatat data di spreadsheet. Admin menyebutkan harga paket, murid
mentransfer dan mengirim foto bukti, admin memeriksa mutasi rekening; jika
cocok, admin mencatat pembayaran dan memasukkan murid ke grup kelas,
jika tidak cocok admin menanyakan ulang kepada murid.

[GAMBAR 3.7: activity diagram pendaftaran dan pembayaran pada sistem lama]

Gambar 3.7
Activity Diagram Pendaftaran dan Pembayaran pada Sistem Saat Ini

```mermaid
%% Alat bantu menggambar Gambar 3.7 (bukan isi buku); swimlane: Calon murid | Admin
flowchart TD
  A1([Mulai]) --> A2[Calon murid: hubungi admin via WhatsApp]
  A2 --> A3[Admin: jawab, minta data diri]
  A3 --> A4[Calon murid: kirim data]
  A4 --> A5[Admin: catat di spreadsheet, sebutkan harga paket]
  A5 --> A6[Calon murid: transfer, kirim foto bukti]
  A6 --> A7[Admin: cek mutasi rekening]
  A7 --> A8{Cocok?}
  A8 -- Tidak --> A9[Admin: tanya ulang] --> A6
  A8 -- Ya --> A10[Admin: catat pembayaran & sisa sesi, masukkan ke grup kelas]
  A10 --> A11([Selesai])
```

Gambar 3.8 menggambarkan penjadwalan guru. Admin menanyakan
ketersediaan setiap guru melalui chat dan menunggu jawaban, menyusun
jadwal di spreadsheet, lalu membagikannya ke grup. Jika guru atau murid
melaporkan bentrok, admin mengubah jadwal dan membagikannya kembali.
Jika seorang guru berhalangan pada satu pertemuan, admin menghubungi guru
lain satu per satu sampai ada yang bersedia, lalu memberi tahu murid.

[GAMBAR 3.8: activity diagram penjadwalan guru pada sistem lama]

Gambar 3.8
Activity Diagram Penjadwalan Guru pada Sistem Saat Ini

```mermaid
%% Alat bantu menggambar Gambar 3.8 (bukan isi buku); swimlane: Admin | Guru | Murid
flowchart TD
  B1([Mulai]) --> B2[Admin: tanya ketersediaan tiap guru via chat]
  B2 --> B3[Guru: balas ketersediaan]
  B3 --> B4[Admin: susun jadwal di spreadsheet]
  B4 --> B5[Admin: bagikan ke grup WhatsApp]
  B5 --> B6{Ada laporan bentrok?}
  B6 -- Ya --> B7[Admin: ubah jadwal] --> B5
  B6 -- Tidak --> B8{Guru berhalangan pada satu pertemuan?}
  B8 -- Ya --> B9[Admin: hubungi guru lain satu per satu] --> B10{Ada yang bersedia?}
  B10 -- Tidak --> B11[Admin: batalkan pertemuan, beri tahu murid] --> B13
  B10 -- Ya --> B12[Admin: beri tahu murid guru pengganti] --> B13
  B8 -- Tidak --> B13([Selesai])
```

Gambar 3.9 menggambarkan tes simulasi dan kenaikan tingkat. Guru
menyiapkan lembar soal dan mengawasi tes di kelas, murid mengerjakan di
kertas, guru mengoreksi dan menghitung nilai per bagian, lalu memasukkan
nilai ke aplikasi web Nilai Simulasi HSK. Ketika guru menilai murid sudah
siap, guru dan admin memeriksa riwayat nilai simulasi secara manual dan
memutuskan kenaikan tingkat, lalu memberi tahu murid.

[GAMBAR 3.9: activity diagram tes simulasi dan kenaikan tingkat pada sistem lama]

Gambar 3.9
Activity Diagram Tes Simulasi dan Kenaikan Tingkat pada Sistem Saat Ini

```mermaid
%% Alat bantu menggambar Gambar 3.9 (bukan isi buku); swimlane: Guru | Murid | Admin
flowchart TD
  C1([Mulai]) --> C2[Guru: siapkan lembar soal kode tes]
  C2 --> C3[Murid: kerjakan tes di kertas, diawasi guru]
  C3 --> C4[Guru: koreksi, hitung nilai per bagian]
  C4 --> C5[Guru: input nilai ke web Nilai Simulasi HSK]
  C5 --> C6{Murid dianggap siap naik?}
  C6 -- Belum --> C7[Lanjut belajar] --> C9
  C6 -- Ya --> C8[Guru & admin: periksa riwayat nilai manual, putuskan naik tingkat, beri tahu murid] --> C9
  C9([Selesai])
```

## 3.4 Permasalahan pada Sistem Saat Ini

Berdasarkan uraian dan pemodelan di atas, permasalahan utama sistem lama
dirangkum pada Tabel 3.3 beserta penyebab dan akibatnya. Permasalahan
tersebut menjadi dasar analisis kebutuhan pada Bab IV dan dijawab oleh
rancangan sistem baru pada Bab V.

Tabel 3.3
Permasalahan pada Sistem Saat Ini

| No | Masalah | Penyebab | Akibat |
|---|---|---|---|
| 1 | Bentrok jadwal guru dan ruang | Jadwal disusun di spreadsheet tanpa pengecekan otomatis; ketersediaan guru ditanya lewat chat | Bentrok baru diketahui menjelang kelas; kelas tertunda atau dibatalkan |
| 2 | Guru pengganti sulit dicari | Tidak ada data ketersediaan dan level yang diajar tiap guru dalam satu tempat | Admin menghubungi guru satu per satu; murid terlambat diberi tahu |
| 3 | Data murid tersebar | Pendaftaran di chat dan spreadsheet, kehadiran di kertas, nilai di aplikasi web terpisah | Data sulit dicari dan tidak sinkron antarsumber |
| 4 | Selisih sisa sesi paket | Sisa sesi dihitung manual dari daftar hadir kertas; izin dan alpa diperlakukan berbeda tanpa catatan yang seragam | Perselisihan sisa sesi antara admin dan murid; paket kedaluwarsa tidak terpantau |
| 5 | Pemeriksaan pembayaran memakan waktu | Bukti transfer dicocokkan dengan mutasi rekening satu per satu | Waktu admin habis untuk pekerjaan berulang; pembayaran yang belum dicek menunda masuk kelas |
| 6 | Koreksi latihan dan tes lambat | Latihan dan tes di kertas, dikoreksi manual, nilai diketik ulang | Umpan balik ke murid terlambat; kesalahan ketik nilai |
| 7 | Kenaikan tingkat tidak terstandar | Riwayat nilai diperiksa manual; tidak ada aturan tertulis jumlah tes yang harus lulus | Keputusan naik tingkat berbeda antarguru; murid tidak tahu syaratnya |
| 8 | Perkembangan murid sulit dipantau | Catatan ada pada masing-masing guru; tidak ada ringkasan per murid | Pemilik usaha dan orang tua tidak punya gambaran; murid yang tertinggal terlambat ditangani |
| 9 | Rekap bisnis manual | Murid baru, pendapatan, dan jam mengajar direkap di akhir bulan dari beberapa sumber | Rekap terlambat dan rawan salah |

Kesembilan masalah tersebut bermuara pada tiga hal: data yang tersebar,
pekerjaan berulang yang dilakukan manual oleh admin, dan tidak adanya
gambaran perkembangan murid yang dapat dipantau. Sistem baru yang
dirancang pada bab berikutnya memindahkan seluruh proses tersebut ke dalam
satu aplikasi dengan basis data terpusat dan logika penting yang dijalankan di
server.
