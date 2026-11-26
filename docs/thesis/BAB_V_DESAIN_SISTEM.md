# BAB V
# DESAIN SISTEM

Bab ini menjelaskan rancangan sistem baru yang menjawab kebutuhan pada
Bab IV. Rancangan mengikuti proposal tugas akhir dengan nama koleksi, fungsi,
dan aturan yang dipakai pada kode yang dibangun. Bab ini berisi deskripsi
sistem baru dan arsitekturnya, perbedaan jadwal dan sesi, penjadwalan guru
dan pengecekan bentrok, konsistensi data voucher, tipe soal dan algoritma
penilaian, sistem level dan kenaikan tingkat, laporan progress, pemodelan
sistem baru, desain basis data, aturan akses, daftar Cloud Functions, dan
desain antarmuka.

## 5.1 Deskripsi Sistem Baru

Sistem baru adalah satu aplikasi Flutter yang berjalan di web, Android, dan
iOS dari satu basis kode, dengan Firebase sebagai backend. Aplikasi melayani
tiga peran utama, yaitu admin, guru, dan murid, ditambah peran orang tua
sebagai akun tambahan yang ditautkan ke akun anaknya dengan kode anak.
Seluruh data tersimpan dalam satu basis data Cloud Firestore, dan logika yang
menentukan uang atau nilai (pemotongan sesi, penilaian, pengecekan bentrok,
kenaikan tingkat) dijalankan di Cloud Functions, bukan di perangkat pengguna.

Arsitektur sistem dari sisi aplikasi ditunjukkan pada Gambar 5.1.

[GAMBAR 5.1: arsitektur Sistem dari Sisi Aplikasi]

Gambar 5.1
Arsitektur Sistem dari Sisi Aplikasi

Ketiga kelompok pengguna memakai aplikasi Flutter yang sama: admin terutama di
PC, guru di telepon, serta murid dan orang tua di Android, iPhone, atau web.
Di dalam aplikasi, kode disusun dengan pola MVVM: View menampilkan halaman per
peran, ViewModel mengelola keadaan halaman dengan ChangeNotifier dan Provider,
dan Service menjadi satu-satunya lapisan yang berbicara dengan Firebase
melalui FlutterFire [11] [19]. Dua pekerjaan berat berjalan di peramban admin
tanpa layanan luar, yaitu pembacaan naskah soal HSK dari PDF (PaddleOCR
melalui onnxruntime-web) dan penulisan transkrip rekaman (Whisper melalui
transformers.js). Aplikasi tidak pernah menghubungi Midtrans secara langsung;
hanya Cloud Functions yang memegang server key dan menerima webhook [15].

Layanan di sisi server dirinci pada Gambar 5.2.

[GAMBAR 5.2: arsitektur Sistem dari Sisi Firebase]

Gambar 5.2
Arsitektur Sistem dari Sisi Firebase

Firebase Authentication menangani login, Cloud Firestore menyimpan data dan
menjaganya dengan Security Rules, Cloud Storage menyimpan rekaman, gambar, dan
naskah PDF, Firebase Cloud Messaging mengirim notifikasi, dan Firebase Hosting
menyajikan versi web, berkas APK, serta berkas model pembaca naskah. Cloud
Functions dipanggil langsung dari aplikasi (callable), berjalan ketika data
berubah (trigger Firestore), berjalan terjadwal, atau menerima HTTP dari
Midtrans (webhook); di sinilah penilaian, pemotongan voucher, pengecekan
bentrok, kenaikan tingkat, dan laporan dijalankan. Firebase Emulator Suite
dipakai selama pengembangan dan pengujian otomatis, dan Cloud Firestore
dicadangkan setiap hari dengan masa simpan tujuh hari.

## 5.2 Jadwal dan Sesi

Jadwal dan sesi adalah dua data yang berbeda. Jadwal (koleksi schedules)
adalah pola kelas yang berulang setiap minggu: hari, jam mulai dan selesai,
ruang (Main atau Sub Room), guru, sampai tiga guru pendamping, kuota kursi,
dan periode berlaku. Sesi (koleksi class_sessions) adalah satu pertemuan
nyata pada tanggal tertentu yang dibuat sistem dari jadwal, dengan ID
{jadwalId}_{tanggal} agar satu tanggal tidak dibuat dua kali. Sesi memiliki
status scheduled, ongoing, done, cancelled, atau needs_teacher, jumlah murid
yang memesan, waktu check-in guru, dan data absensi. Sesi adalah satuan yang
dipesan murid, diisi absensinya oleh guru, dan memotong satu sesi voucher.
Perbedaan keduanya dirangkum pada Tabel 5.1.

Tabel 5.1
Perbedaan Jadwal dan Sesi

| Aspek | Jadwal (schedules) | Sesi (class_sessions) |
|---|---|---|
| Pengertian | Pola kelas yang berulang setiap minggu | Satu pertemuan nyata pada satu tanggal |
| Dibuat oleh | Admin melalui saveSchedule | Sistem melalui generateSessions, empat belas hari ke depan; admin dapat menambah sesi lepas |
| Data utama | Hari, jam, ruang, guru, guru pendamping, kuota, periode | Tanggal, jam, guru, ruang, pemesan, check-in, status |
| Status | Aktif atau tidak aktif | scheduled, ongoing, done, cancelled, needs_teacher |
| Dipesan murid | Tidak | Ya, sampai kuota penuh; sisanya masuk daftar tunggu |
| Absensi dan voucher | Tidak ada | Ada; menutup sesi memotong voucher |
| Perubahan | Mengubah sesi yang belum berjalan | Hanya sesi pada tanggal itu |

Sesi dimulai sendiri pada jam mulainya; check-in guru hanya mencatat
kedatangan dan keterlambatan. Mengikuti ketentuan Easy Study, sesi dengan
pemesan kurang dari batas minimum (settings/scheduling.minStudents) dapat
ditutup otomatis beberapa jam sebelum mulai, dan hari libur nasional (koleksi
holidays, diambil dari daftar SKB tiga menteri) atau hari yang ditutup admin
membatalkan sesi pada hari itu dengan mengembalikan pesanan murid.

Perubahan status sebuah sesi kelas ditunjukkan pada Gambar 5.3.

[GAMBAR 5.3: diagram Status Sesi Kelas]

Gambar 5.3
Diagram Status Sesi Kelas

Sesi dibuat oleh generateSessions dengan status scheduled, atau needs_teacher
bila guru libur pada tanggal itu sampai admin menunjuk guru pengganti. Sesi
menjadi ongoing dengan sendirinya ketika jam mulai tiba dan menjadi done
setelah guru menutupnya dengan closeSession. Sesi menjadi cancelled bila
dibatalkan admin, harinya ditutup, muridnya terlalu sedikit, atau jadwalnya
dihapus; hari yang dibuka kembali mengembalikan sesinya menjadi scheduled.
Semua perubahan status ditulis oleh Cloud Functions.

Urutan pemesanan sesi kelas oleh murid ditunjukkan pada Gambar 5.4.

[GAMBAR 5.4: sequence Diagram Pemesanan Sesi Kelas]

Gambar 5.4
Sequence Diagram Pemesanan Sesi Kelas

Pemesanan dilakukan fungsi bookSession, yang dapat dipanggil murid atau orang
tua yang tertaut dengannya. Di dalam satu transaksi, fungsi membaca sesi,
voucher, dan pesanan lain murid, lalu memeriksa alasan penolakan dengan
bookingRefusal. Bila tidak ada alasan penolakan, fungsi membuat dokumen
attendance, menambah bookedCount pada sesi, dan menambah sessionsBooked pada
voucher. Bila ditolak, tidak ada data yang berubah dan aplikasi menampilkan
alasannya.

## 5.3 Penjadwalan Guru dan Pengecekan Bentrok

Admin menyusun jadwal pada halaman Timetable. Saat jadwal disimpan,
fungsi saveSchedule menjalankan pengecekan bentrok di dalam satu transaksi
Firestore dengan dokumen kunci pada koleksi schedule_locks, sehingga dua
admin yang menyimpan jadwal bersamaan tidak menghasilkan jadwal yang
bentrok. Pengecekan yang dijalankan dirangkum pada Tabel 5.2, dan urutannya
ditulis pada Algoritma 5.1. Dua waktu dianggap beririsan bila mulai A kurang
dari selesai B dan mulai B kurang dari selesai A; admin dapat menambahkan
jeda minimal antarkelas (settings/scheduling.minGapMinutes, bawaan 0 menit
sesuai permintaan pemilik). Ketersediaan guru hanya diperiksa bila saklar
kesiapan guru (settings/scheduling.teacherReadiness) dinyalakan; saklar ini
dimatikan pada operasional Easy Study karena keempat guru selalu siap, dan
dinyalakan untuk uji coba.

Tabel 5.2
Pengecekan pada Penjadwalan Guru

| No | Pengecekan | Waktu | Akibat bila tidak terpenuhi |
|---|---|---|---|
| 1 | Validasi data: jam selesai setelah jam mulai, kuota minimal satu, ruang dikenal | Saat jadwal disimpan | Jadwal ditolak |
| 2 | Ketersediaan guru (bila kesiapan guru dinyalakan) | Saat jadwal atau sesi disimpan | Jadwal ditolak, jam kosong guru ditampilkan |
| 3 | Bentrok guru dan guru pendamping dengan jadwal atau sesi lepas lain, termasuk jeda minimal | Saat jadwal atau sesi disimpan | Jadwal ditolak, kelas yang bentrok disebutkan |
| 4 | Bentrok ruang | Saat jadwal atau sesi disimpan | Jadwal ditolak, kelas yang memakai ruang disebutkan |
| 5 | Beban mengajar mingguan | Saat jadwal disimpan | Peringatan, jadwal tetap dapat disimpan |
| 6 | Guru pengganti: tersedia, dapat mengajar, tidak bentrok | Saat admin menunjuk pengganti | Hanya calon yang lolos yang ditawarkan |
| 7 | Check-in guru (bila kesiapan guru dinyalakan) | Lima belas menit setelah jam mulai | Notifikasi keterlambatan ke admin |
| 8 | Penutupan sesi | Setelah jam selesai | Sesi tampil sebagai belum ditutup pada tindak lanjut admin |

Algoritma 5.1
Pengecekan Bentrok Jadwal
01: masukan: jadwal J (hari, mulai, selesai, guru, guru pendamping, ruang, periode) dan jeda G
02: daftarBentrok ← kosong
03: jika kesiapan guru aktif dan J di luar jam ketersediaan guru maka tambah "ketersediaan"
04: untuk setiap jadwal aktif lain L dengan hari sama dan periode beririsan:
05:    jika guru L sama dan mulai L < selesai J + G dan mulai J < selesai L + G maka tambah "guru"
06:    jika ruang L sama dan waktunya beririsan dengan jeda G maka tambah "ruang"
07: untuk setiap sesi lepas S pada hari dan periode yang sama: periksa guru dan ruang seperti baris 05 dan 06
08: jika daftarBentrok kosong maka simpan J dalam satu transaksi dengan kunci schedule_locks
09: jika tidak maka tolak dan tampilkan setiap alasan beserta kelas yang bentrok

Setelah jadwal tersimpan, fungsi terjadwal generateSessions membuat sesi
untuk empat belas hari ke depan setiap hari. Bila seorang guru berhalangan,
admin membuka daftar calon pengganti (substituteCandidates) yang sudah
disaring: tersedia pada jam itu, dapat mengajar tingkat kelas tersebut, dan
tidak bentrok; penunjukan (assignSubstitute) memberi tahu murid yang sudah
memesan. Murid memesan tempat pada sesi melalui bookSession dengan urutan
pemeriksaan pada Algoritma 5.2; murid yang terlambat masih dapat memesan
sampai kelas berakhir, dan kelas yang penuh menawarkan daftar tunggu
(joinWaitlist) yang otomatis memesankan tempat bila ada yang membatalkan.

Algoritma 5.2
Pemesanan Sesi oleh Murid
01: masukan: sesi S, murid M, waktu sekarang T
02: jika status S = needs_teacher maka tolak "belum ada guru"
03: jika status S bukan scheduled atau ongoing, atau S sudah ditutup, maka tolak "ditutup"
04: jika jam selesai S ≤ T maka tolak "terlambat"
05: jika S mempunyai tingkat dan tingkat M berbeda maka tolak "tingkat"
06: jika bookedCount S ≥ capacity S maka tolak "penuh" dan tawarkan daftar tunggu
07: V ← voucher aktif M dengan tenggat ≥ tanggal S dan sisa yang dapat dipesan > 0, tenggat terdekat
08: jika V tidak ada atau sudah kedaluwarsa maka tolak "tidak ada sesi"
09: jika M sudah memesan sesi lain yang beririsan pada tanggal itu maka tolak "bentrok"
10: dalam satu transaksi: bookedCount S ← +1; sessionsBooked V ← +1; buat attendance {S, M, booked}

## 5.4 Konsistensi Data Voucher

Paket sesi yang dibeli murid disimpan sebagai term pada koleksi
student_class_terms dengan field packageSize, sessionsUsed, sessionsBooked,
sessionsRemaining, sessionsForfeited, startDate, deadlineDate, status (active,
depleted, atau expired), dan sourceInvoiceId yang menautkannya ke invoice
pembayaran. Sisa sesi yang masih dapat dipesan dihitung dengan Rumus 5.1,
sehingga murid tidak dapat memesan lebih banyak sesi daripada sisanya.

Sisa dapat dipesan = sessionsRemaining − sessionsBooked      (5.1)

Semua perubahan angka voucher terjadi di dalam transaksi Firestore [10],
yang membaca dokumen terlebih dahulu dan menulis semua perubahan sekaligus;
bila dokumen yang dibaca berubah oleh proses lain, transaksi diulang dengan
data terbaru, dan bila gagal tidak ada perubahan yang tersimpan. Pemesanan
(bookSession) menambah sessionsBooked, pembatalan (cancelBooking)
menguranginya, dan penutupan sesi (closeSession) memindahkan pesanan menjadi
pemakaian seperti pada Algoritma 5.3. Setiap pemotongan ditulis sebagai satu
dokumen buku besar voucher_history dengan ID {sesiId}_{muridId}; karena satu
ID hanya dapat dibuat sekali dan status sesi diperiksa di awal transaksi,
pemanggilan ulang closeSession tidak memotong voucher dua kali (idempoten).
Fungsi terjadwal expireVouchers (pukul 00.30 WIB) menghanguskan sisa sesi
setelah tenggat dua bulan, dan reconcileVouchers memeriksa bahwa
sessionsUsed setiap term sama dengan jumlah dokumen buku besarnya. Contoh
perubahan data pada paket delapan sesi ditunjukkan pada Tabel 5.3.

Algoritma 5.3
Penutupan Sesi dan Pemotongan Voucher
01: masukan: sesi S dan status kehadiran setiap murid (hadir, izin, alpa)
02: dalam satu transaksi: baca S; jika status S sudah done maka selesai tanpa perubahan
03: jika S belum dimulai maka tolak "mulai sesi dahulu"
04: untuk setiap catatan kehadiran A pada S yang belum ditutup:
05:    status ← status yang dikirim guru; bawaan alpa bila murid memesan tetapi tidak hadir
06:    V ← term voucher yang dipakai A (atau term aktif terdekat tenggatnya)
07:    jika status = hadir atau alpa maka sessionsUsed V +1, sessionsRemaining V −1, sessionsBooked V −1
08:    jika status = izin maka sessionsBooked V −1 (sesi kembali ke voucher)
09:    tulis voucher_history/{S}_{M} dengan status dan jumlah sesi yang dipotong (1 atau 0)
10:    tandai A tertutup dan tercatat
11: tulis setiap V; jika sessionsRemaining V = 0 maka status V ← depleted
12: status S ← done; rekap guru bulan ini: sesi +1, jam +lama sesi, murid hadir +jumlah hadir

Tabel 5.3
Contoh Perubahan Data Voucher Delapan Sesi

| No | Kejadian | sessionsUsed | sessionsBooked | sessionsRemaining | Dapat dipesan |
|---|---|---|---|---|---|
| 1 | Voucher dibuat dari invoice yang lunas | 0 | 0 | 8 | 8 |
| 2 | Murid memesan tiga sesi | 0 | 3 | 8 | 5 |
| 3 | Sesi pertama ditutup, murid hadir | 1 | 2 | 7 | 5 |
| 4 | Murid izin sebelum sesi kedua | 1 | 1 | 7 | 6 |
| 5 | Sesi ketiga ditutup, murid alpa | 2 | 0 | 6 | 6 |
| 6 | closeSession sesi ketiga terpanggil ulang | 2 | 0 | 6 | 6 (tidak berubah) |

Urutan penutupan sesi kelas oleh guru ditunjukkan pada Gambar 5.5.

[GAMBAR 5.5: sequence Diagram Penutupan Sesi Kelas]

Gambar 5.5
Sequence Diagram Penutupan Sesi Kelas

Aplikasi hanya mengirim ID sesi dan status kehadiran; seluruh perubahan data
dilakukan fungsi closeSession di dalam satu transaksi Firestore. Fungsi
memeriksa status sesi terlebih dahulu, lalu menulis buku besar
voucher_history, mengubah dokumen attendance dan sisa sesi voucher, serta
menandai sesi sebagai done. Bila fungsi dipanggil lagi untuk sesi yang sama,
pemeriksaan pada langkah 4 menghentikannya, sehingga voucher murid tidak
terpotong dua kali.

Perubahan status tagihan dan voucher ditunjukkan pada Gambar 5.6.

[GAMBAR 5.6: diagram Status Tagihan dan Voucher]

Gambar 5.6
Diagram Status Tagihan dan Voucher

Tagihan dibuat dengan status pending dan menjadi paid setelah pembayaran
Midtrans berhasil atau setelah admin mencatat pembayaran tunai atau transfer.
Tagihan yang tidak dibayar menjadi expired atau failed, dan admin dapat
menyisihkannya sebagai discarded lalu memulihkannya kembali. Tagihan yang
lunas menghasilkan voucher berstatus active. Voucher menjadi depleted ketika
sisa sesinya habis dan expired ketika tenggatnya terlewati.

## 5.5 Tipe Soal dan Algoritma Penilaian

Seluruh soal tersimpan di bank soal (koleksi question_bank). Setiap butir
memiliki tipe soal, keterampilan (mendengarkan, membaca, atau menulis),
tingkat HSK, kunci jawaban, pembahasan, dan untuk lembar kerja (worksheet)
dapat memiliki bagian (section), gambar per pilihan, satu rekaman untuk
seluruh lembar, dan transkripnya. Setiap lembar kerja mempunyai jenis
latihan: Exercise, Quiz, HSK Simulation, atau Standard Course. Dari bank soal
disusun paket (koleksi exercises) yang berisi lembar kerja dan butir soal;
lembar HSK Simulation hanya dikerjakan melalui kode tes yang diawasi (subbab
5.6), sedangkan paket lainnya adalah latihan yang dapat diulang; paket yang
diberi batas waktu memakai percobaan bernomor dengan jam server. Perbedaan latihan dan tes dirangkum pada Tabel 5.4, dan bentuk
soal yang tersedia pada Tabel 5.5.

Tabel 5.4
Perbedaan Latihan dan Tes Simulasi HSK

| Aspek | Latihan | Tes Simulasi HSK |
|---|---|---|
| Tujuan | Melatih pemahaman materi | Mengukur kemampuan untuk kenaikan tingkat |
| Tempat dan pembukaan | Di mana saja, ditugaskan guru atau admin | Di Easy Study, dibuka guru dengan token enam karakter yang berlaku lima belas menit |
| Waktu | Tanpa batas, kecuali paket diberi batas menit | Per bagian sesuai format HSK, dihitung jam server |
| Percobaan | Berulang kali | Duduk pertama yang sah dihitung; duduk ulang hanya pada sesi baru dan menjadi latihan |
| Rekaman | Diputar bebas | Diputar menurut aturan bagian |
| Ulasan | Setelah jawaban dikumpulkan | Setelah tes ditutup, tanpa kunci untuk tes penempatan pengunjung |
| Kegunaan nilai | Laporan progress | Kenaikan tingkat dan leaderboard |

Tabel 5.5
Tipe dan Bentuk Soal

| Keterampilan | Bentuk soal | Penilaian |
|---|---|---|
| Mendengarkan | Pilihan ganda dengan teks atau gambar; benar atau salah; mencocokkan | Otomatis |
| Membaca | Isian rumpang; mencocokkan kalimat; pemahaman bacaan pilihan ganda; mengurutkan kalimat | Otomatis |
| Menulis | Mengetik pinyin dari hanzi; mengetik hanzi dari pinyin; melengkapi hanzi; mengisi beberapa rumpang dalam satu kalimat (satu jawaban per rumpang); menyusun kata menjadi kalimat; menulis kalimat dari gambar; esai | Otomatis dengan toleransi (Algoritma 5.4); soal beberapa rumpang dinilai per rumpang dan mendapat bagian rumpang yang benar; kalimat dari gambar dan esai dinilai guru |

Murid menjawab seluruh soal lebih dahulu dan mengirim sekali; fungsi
finishExercise memeriksa seluruh jawaban dengan kunci yang hanya dapat
dibaca server, menghitung nilai, lalu mengembalikan ulasan. Nilai setiap
bagian dihitung dengan Rumus 5.2. Jawaban ketik tidak dicocokkan mentah,
melainkan dengan Algoritma 5.4 yang menerima tanda baca lebar penuh, tanda
baca akhir, hanzi tradisional, dan nada pinyin berupa angka maupun tanda;
jawaban yang hampir benar mendapat setengah poin dan ditandai agar guru
meninjaunya, sedangkan soal menyusun kalimat tidak pernah mendapat nilai
sebagian. Soal dengan beberapa rumpang (ulasan pelajaran Standard Course)
dicocokkan rumpang demi rumpang dengan cara yang sama, dan nilainya adalah
bagian rumpang yang benar. Soal menulis bebas (kalimat dari gambar dan esai) bernilai sepuluh
poin dan hanya dinilai guru melalui antrean penilaian (koleksi marking_items,
fungsi markAnswer); hasil yang masih menunggu penilaian berstatus
pending_marking tanpa keputusan lulus. Contoh pencocokan ditunjukkan pada
Tabel 5.6.

Nilai bagian = poin diperoleh ÷ poin maksimal × 100      (5.2)

Algoritma 5.4
Pencocokan Jawaban Typing
01: masukan: jawaban J, daftar kunci K yang diterima, jenis soal (hanzi, pinyin, atau urutan kalimat)
02: jika jenis = hanzi: N(x) ← lebar penuh menjadi setengah, tanda baca CJK disamakan, spasi dan tanda baca akhir dihapus, tradisional menjadi sederhana (OpenCC)
03:    untuk setiap kunci k: d ← jarak Levenshtein per karakter antara N(J) dan N(k)
04:       jika d = 0 maka kembalikan 1 (poin penuh)
05:       jika d = 1 dan 1 − d/n ≥ 0,75 maka ingat 0,5 (ditinjau guru)
06: jika jenis = pinyin: urai J dan setiap k menjadi suku kata (huruf dan nada); nada angka dan tanda nada sama-sama diterima
07:    jika jumlah dan huruf setiap suku kata sama: bila nada sama atau kunci tanpa nada kembalikan 1, bila tidak ingat 0,5 (ditinjau guru)
08: jika jenis = urutan kalimat: hanya kecocokan tepat yang bernilai 1
09: kembalikan nilai terbaik yang diingat; bila tidak ada, 0

Tabel 5.6
Contoh Pencocokan Jawaban Typing

| Kunci | Jawaban murid | Proses | Nilai |
|---|---|---|---|
| 你好 | 你好！ | Tanda baca akhir dihapus, sama persis | 100 % |
| 谢谢 | 謝謝 | Hanzi tradisional diubah menjadi sederhana, sama persis | 100 % |
| nǐ hǎo | ni3 hao3 | Tanda nada dibaca sebagai angka, sama persis | 100 % |
| nǐ hǎo | ni hao | Semua suku kata benar, nada tidak ditulis | 50 %, ditinjau guru |
| 我很喜欢喝茶 | 我很喜欢和茶 | d = 1, n = 6, S = 0,83 (satu karakter homofon) | 50 %, ditinjau guru |
| 把书放在桌子上 | 书把放在桌子上 | Soal menyusun kalimat, urutan salah | 0 % |

## 5.6 Sistem Level dan Kenaikan Tingkat

Cakupan tingkat adalah HSK 1 sampai HSK 6, dikelompokkan menjadi tiga
level seperti pada Tabel 5.7. Aplikasi tidak membuat rapor; penilaian dipakai
untuk satu tujuan, yaitu menentukan kapan murid naik ke tingkat berikutnya.
Setiap paket tes simulasi mempunyai kode tes (koleksi test_codes) berupa
untaian acak yang diketik admin, dengan tingkat HSK dan tahun terbit sebagai
field terpisah, dan mengikuti format resmi HSK per tingkat pada Tabel 5.8
(koleksi test_formats) dengan bagian menulis dikerjakan sebagai soal ketik.

Tabel 5.7
Pembagian Level

| Level | Tingkat | Kosakata acuan |
|---|---|---|
| Beginner | HSK 1 dan HSK 2 | 150 sampai 300 kata |
| Intermediate | HSK 3 dan HSK 4 | 600 sampai 1.200 kata |
| Advance | HSK 5 dan HSK 6 | 2.500 sampai 5.000 kata |

Tabel 5.8
Format Tes Simulasi HSK per Tingkat

| Tingkat | Mendengarkan | Membaca | Menulis | Total soal | Durasi | Nilai maksimal / lulus |
|---|---|---|---|---|---|---|
| HSK 1 | 20 | 20 | – | 40 | 35 menit | 200 / 120 |
| HSK 2 | 35 | 25 | – | 60 | 50 menit | 200 / 120 |
| HSK 3 | 40 | 30 | 10 | 80 | 85 menit | 300 / 180 |
| HSK 4 | 45 | 40 | 15 | 100 | 100 menit | 300 / 180 |
| HSK 5 | 45 | 45 | 10 | 100 | 120 menit | 300 / 180 |
| HSK 6 | 50 | 50 | 1 | 101 | 135 menit | 300 / 180 |

Tes simulasi diawasi: guru membuka sesi tes (openTestSession) dan
memperoleh token enam karakter yang berlaku lima belas menit; murid memulai
tes dengan token itu (startTest); setiap bagian mempunyai jam server dan
jawaban dikirim per bagian (submitTestPart); setiap kali murid meninggalkan
halaman tes, kejadiannya dicatat (reportTestEvent) dan tampak pada layar
pengawasan guru; guru menutup sesi (closeTestSession) dan dapat menyatakan
hasil tidak sah. Penilaian per bagian dan keputusan lulus mengikuti Algoritma
5.5, dan setiap hasil akhir menggerakkan pemicu onTestResultWritten yang
memperbarui leaderboard kode tes (koleksi leaderboards, murid melihat nama
Mandarin peserta lain) dan menghitung kenaikan tingkat menurut Algoritma 5.6.
Murid naik tingkat setelah lulus pada sejumlah kode tes berbeda
(settings/promotion.minCodes, bawaan tiga) atau, bila admin membuat daftar
centang untuk tingkat itu (koleksi level_paths), setelah seluruh butir daftar
terpenuhi; rekomendasi (koleksi level_promotions) disetujui atau ditolak admin,
dan admin juga dapat menaikkan tingkat langsung dengan alasan. Contoh riwayat
tes seorang murid HSK 3 ditunjukkan pada Tabel 5.9.

Urutan pelaksanaan tes simulasi yang diawasi guru ditunjukkan pada Gambar 5.7.

[GAMBAR 5.7: sequence Diagram Tes Simulasi dengan Token]

Gambar 5.7
Sequence Diagram Tes Simulasi dengan Token

Guru membuka sesi tes dan menyebutkan token yang dihasilkan kepada murid di
kelas. Murid memulai tes dengan token itu, menerima soal tanpa kunci jawaban,
dan mengirim jawaban setiap bagian melalui submitTestPart. Setelah bagian
terakhir, fungsi menghitung nilai dan menulis test_results, lalu murid melihat
kartu hasilnya. Penulisan hasil itu memicu onTestResultWritten yang
memperbarui leaderboard, hitungan kenaikan tingkat, dan ringkasan progress
berdasarkan duduk pertama yang sah.

Murid dapat mengerjakan kode tes yang sama lagi hanya pada sesi tes baru yang
dibuka guru. Setiap pengerjaan diberi nomor duduk; duduk pertama yang sah
dihitung untuk leaderboard, hitungan kenaikan tingkat, dan rekomendasi
penempatan, sedangkan duduk berikutnya disimpan sebagai latihan karena murid
sudah melihat ulasan jawabannya. Setiap baris leaderboard memuat waktu
selesai; staf dapat mengekspornya sebagai CSV atau PDF, sedangkan murid hanya
dapat membagikan kartu hasilnya sendiri.

Algoritma 5.5
Penilaian Tes Simulasi per Bagian
01: masukan: bagian B (mendengarkan, membaca, menulis) dengan soal dan jawaban murid; nilai maksimal setiap bagian 100
02: untuk setiap bagian: poin ← 0; untuk setiap soal tambahkan poinnya bila benar; soal menulis bebas menunggu penilaian guru
03:    nilai bagian ← poin ÷ poin maksimal × 100, dibulatkan
04: total ← jumlah nilai bagian; batas lulus ← 60 % dari nilai maksimal (120 dari 200, 180 dari 300)
05: jika ada soal menulis bebas yang belum dinilai maka status ← pending_marking (belum lulus atau gagal)
06: jika tidak maka status ← final dan lulus ← total ≥ batas lulus dan hasil sah
07: simpan test_results; pemicu memperbarui leaderboard dan kenaikan tingkat

Algoritma 5.6
Rekomendasi Kenaikan Tingkat
01: masukan: hasil tes R milik murid M yang sudah final; tingkat M = t
02: jika R tidak sah, belum final, atau tes penempatan maka selesai
03: perbarui leaderboards/{kode}/entries/{M} dengan total dan durasi
04: jika ada daftar centang level_paths/t maka selesai ← setiap butir latihan (nilai terbaik ≥ minimum) dan butir tes (lulus) terpenuhi
05: jika tidak maka kodeLulus ← himpunan kode berbeda tingkat t yang lulus oleh M; selesai ← |kodeLulus| ≥ minCodes
06: tulis promotion_progress/{M} dengan hitungan, kode, dan modenya
07: jika selesai dan belum ada rekomendasi terbuka maka buat level_promotions/{M}_{t} berstatus menunggu dan beri tahu admin
08: admin menyetujui: level M ← t + 1, tulis level_history, hitungan dimulai dari nol, beri tahu murid dan orang tua; atau menolak dengan alasan

Tabel 5.9
Contoh Riwayat Tes Simulasi Murid HSK 3

| No | Kode tes | Mendengarkan | Membaca | Menulis | Total | Hasil | Kode lulus |
|---|---|---|---|---|---|---|---|
| 1 | Kode A | 58 | 62 | 50 | 170 | Tidak lulus | 0 |
| 2 | Kode B | 70 | 65 | 60 | 195 | Lulus | 1 |
| 3 | Kode C | 72 | 70 | 58 | 200 | Lulus | 2 |
| 4 | Kode D | 75 | 68 | 62 | 205 | Lulus | 3, rekomendasi naik ke HSK 4 |

Tes penempatan memakai paket tes simulasi yang ada. Calon murid yang
mendaftar sendiri dapat memilih tes penempatan, dan pengunjung tanpa akun
dapat mengerjakannya dari halaman /placement di Easy Study dengan kode guru;
hasilnya berupa kode hasil enam karakter yang diklaim sekali pada formulir
pendaftaran. Rekomendasi tingkatnya mengikuti Algoritma 5.7, dan admin
menetapkan tingkat awal saat menyetujui pendaftaran (decideRegistration).

Algoritma 5.7
Rekomendasi Tingkat pada Tes Penempatan
01: masukan: tingkat kertas tes p dan keputusan lulus L (total ≥ batas lulus)
02: jika L maka rekomendasi ← p + 1 (paling tinggi HSK 6), jika tidak maka rekomendasi ← p
03: untuk pengunjung tanpa akun: simpan placement_results dengan kode hasil enam karakter dan sidik kunci; tidak ada ulasan jawaban
04: saat mendaftar, kode hasil diklaim sekali dan rekomendasinya ditampilkan kepada admin
05: admin menetapkan tingkat awal saat menyetujui pendaftaran; data pengunjung dihapus setelah 180 hari

## 5.7 Laporan Progress

Ringkasan progress setiap murid disimpan dalam satu dokumen
progress_summary/{muridId} yang hanya ditulis fungsi refreshProgressSummary.
Ringkasan diperbarui oleh pemicu setiap ada hasil latihan, absensi, perubahan
voucher, catatan guru, atau hasil tes, dan oleh pekerjaan harian pukul 07.00.
Isinya adalah posisi level dan tingkat beserta kemajuan kenaikan tingkat,
nilai latihan per minggu dan rata-rata per keterampilan, riwayat tes simulasi
dengan peringkatnya, persentase kehadiran (hadir dibagi hadir ditambah alpa)
dan riwayat absensi, sisa sesi dan tenggat voucher, catatan guru, serta
riwayat kenaikan tingkat. Satu widget laporan yang sama dipakai pada tab
Progress murid, halaman pertama orang tua, halaman murid pada akun guru dan
admin, dan cetakan laporan. Lima peringatan pada Tabel 5.10 dihitung menurut
Algoritma 5.8; setiap murid berstatus baik (tanpa peringatan), perlu perhatian
(satu), atau perlu tindak lanjut (dua atau lebih).

Tabel 5.10
Indikator Peringatan Progress Murid

| No | Indikator | Kondisi | Diberitahukan kepada |
|---|---|---|---|
| 1 | Kehadiran | Kurang dari 75 % dalam 30 hari terakhir, dengan minimal empat catatan | Guru dan admin |
| 2 | Penurunan nilai | Rata-rata latihan 14 hari terakhir di bawah 60, atau turun 10 poin atau lebih dari 14 hari sebelumnya | Guru |
| 3 | Tidak aktif berlatih | Tidak mengerjakan latihan selama 14 hari | Murid dan guru |
| 4 | Sisa voucher | Sisa sesi dua atau kurang, atau tenggat dalam tujuh hari | Murid dan admin |
| 5 | Hasil tes simulasi | Gagal pada dua tes simulasi berturut-turut | Guru dan admin |

Algoritma 5.8
Peringatan Progress Murid
01: masukan: ringkasan progress murid M dan waktu sekarang T
02: peringatan ← kosong
03: jika catatan kehadiran 30 hari ≥ 4 dan persentase hadir < 75 % maka tambah P1 kehadiran
04: jika percobaan latihan 14 hari ≥ 2 dan rata-rata < 60, atau turun ≥ 10 dari 14 hari sebelumnya, maka tambah P2 nilai latihan
05: jika T − latihan terakhir ≥ 14 hari maka tambah P3 tidak aktif
06: jika sisa sesi voucher ≤ 2 atau tenggat ≤ 7 hari maka tambah P4 voucher
07: jika dua tes simulasi terakhir yang dihitung gagal berturut-turut maka tambah P5 tes
08: status ← baik bila 0 peringatan, perlu perhatian bila 1, perlu tindak lanjut bila 2 atau lebih
09: kirim pemberitahuan setiap peringatan kepada peran yang berhak, paling banyak sekali per tujuh hari per peringatan

## 5.8 Pemodelan Sistem Baru

Sistem baru dimodelkan dengan use case diagram per peran dan activity diagram
untuk empat alur utama. Use case umum untuk semua peran adalah login,
pemilihan bahasa antarmuka, penggantian kata sandi, dan penerimaan notifikasi.
Urutan pesan antara aplikasi, Cloud Functions, dan Cloud Firestore untuk tiga
alur terpenting sudah digambarkan dengan sequence diagram pada Gambar 5.4,
Gambar 5.5, dan Gambar 5.7, dan struktur datanya dibahas pada subbab 5.9.

Use case admin dibagi menjadi dua diagram menurut bidang pekerjaannya; Gambar
5.8 memuat pengelolaan akun, bank soal, dan jadwal.

[GAMBAR 5.8: use Case Diagram Admin: Akun, Bank Soal, dan Jadwal]

Gambar 5.8
Use Case Diagram Admin: Akun, Bank Soal, dan Jadwal

Admin menyetujui atau menolak pendaftaran murid, mengelola akun guru, murid,
dan orang tua, serta mengelola bank soal dan kode tes, termasuk membaca naskah
soal HSK dari PDF. Pada bidang jadwal, admin menyusun jadwal dengan pengecekan
bentrok, menunjuk guru pengganti, mengelola sesi, hari libur, dan aturan
jadwal, serta mengirim pengumuman.

Gambar 5.9 memuat use case admin untuk voucher, pembayaran, kenaikan tingkat,
dan laporan.

[GAMBAR 5.9: use Case Diagram Admin: Voucher, Kenaikan Tingkat, dan Laporan]

Gambar 5.9
Use Case Diagram Admin: Voucher, Kenaikan Tingkat, dan Laporan

Admin mengelola paket voucher dan daftar harga, mencatat pembayaran tunai atau
transfer, memantau pembayaran Midtrans dan invoice, serta memeriksa voucher
dan jejak audit. Admin juga mengatur aturan kenaikan tingkat, memutuskan
rekomendasi kenaikan tingkat yang ditulis sistem, dan melihat laporan progress
semua murid, laporan bulanan, serta rekap guru.

Use case guru ditunjukkan pada Gambar 5.10.

[GAMBAR 5.10: use Case Diagram Guru]

Gambar 5.10
Use Case Diagram Guru

Di bidang kelas, guru melihat jadwal mengajar dan sesi hari ini, mengisi
ketersediaan bila fitur itu dinyalakan, melakukan check-in, mengisi absensi
hadir, izin, atau alpa, lalu menutup sesi. Guru juga melihat data dan progress
muridnya serta menulis catatan tindak lanjut. Di bidang soal dan tes, guru
menulis soal dan lembar kerja, menyusun dan menugaskan paket latihan, membuka
dan mengawasi tes, menilai jawaban menulis bebas, meninjau jawaban Typing yang
ditandai, dan melihat leaderboard dengan nama lengkap murid.

Use case murid ditunjukkan pada Gambar 5.11.

[GAMBAR 5.11: use Case Diagram Murid]

Gambar 5.11
Use Case Diagram Murid

Murid mendaftar sendiri dan dapat memilih tes penempatan, melihat sisa sesi
dan tenggat voucher, membeli paket melalui Midtrans, memesan atau membatalkan
sesi termasuk masuk daftar tunggu, dan melihat riwayat kehadirannya. Untuk
belajar, murid mengerjakan latihan yang ditugaskan, mengikuti tes simulasi
dengan token, lalu melihat nilai, ulasan, leaderboard, dan laporan progress.
Murid juga dapat menautkan akun orang tua dengan kode anak serta mengubah
bahasa, mengganti kata sandi, atau menghapus akunnya.

Use case orang tua ditunjukkan pada Gambar 5.12.

[GAMBAR 5.12: use Case Diagram Orang Tua]

Gambar 5.12
Use Case Diagram Orang Tua

Orang tua adalah akun tambahan yang ditautkan ke akun anaknya dengan kode
anak. Setelah tertaut, orang tua melihat sisa sesi, tenggat voucher, riwayat
kehadiran, dan laporan progress anaknya, serta dapat membeli paket dan memesan
atau membatalkan sesi atas nama anak. Use case yang hanya dimiliki orang tua
adalah membayar tagihan anak; tujuh use case lainnya sama dengan milik murid
pada Gambar 5.11.

Gambar 5.13 menggambarkan pendaftaran dan persetujuan murid.

[GAMBAR 5.13: activity Diagram Pendaftaran dan Persetujuan Murid]

Gambar 5.13
Activity Diagram Pendaftaran dan Persetujuan Murid

Calon murid mengisi formulir pendaftaran dan memilih mulai dari Beginner atau
mengikuti tes penempatan, lalu sistem membuat akun berstatus pending dan
menampilkannya pada daftar Persetujuan. Bila calon murid mempunyai kode hasil
penempatan, admin melihat rekomendasi tingkatnya sebelum meninjau pendaftaran.
Admin menolak dengan alasan, atau menyetujui dengan menetapkan tingkat awal
dan guru; setelah disetujui, fungsi decideRegistration mengaktifkan akun dan
memberi tahu murid, yang kemudian dapat masuk ke beranda murid.

Alur dari pemesanan sampai penutupan sesi dibagi menjadi dua diagram; Gambar
5.14 menggambarkan pemesanan sesi.

[GAMBAR 5.14: activity Diagram Pemesanan Sesi]

Gambar 5.14
Activity Diagram Pemesanan Sesi

Fungsi generateSessions membuat sesi dari jadwal untuk empat belas hari ke
depan, lalu murid memilih sesi pada kalender. Fungsi bookSession memeriksa
status, waktu, tingkat, kuota, voucher, dan bentrok sesuai Algoritma 5.2. Bila
pemeriksaan tidak lolos, murid melihat alasannya dan dapat masuk daftar tunggu
bila kelas penuh; bila lolos, tempat dipesan dengan menambah bookedCount pada
sesi dan sessionsBooked pada voucher serta membuat dokumen attendance.
Penghubung A menandai kelanjutan alur pada Gambar 5.15.

Gambar 5.15 melanjutkan alur tersebut sampai sesi ditutup.

[GAMBAR 5.15: activity Diagram Pelaksanaan dan Penutupan Sesi]

Gambar 5.15
Activity Diagram Pelaksanaan dan Penutupan Sesi

Sistem mengirim pengingat satu jam sebelum sesi, dan sesi dimulai sendiri pada
jam mulainya. Guru melakukan check-in yang mencatat kedatangannya, mengisi
absensi hadir, izin, atau alpa sambil membandingkannya dengan papan kehadiran,
lalu menutup sesi. Fungsi closeSession memotong voucher, menulis buku besar
voucher, dan memperbarui rekap guru dalam satu transaksi (Algoritma 5.3),
kemudian ringkasan progress diperbarui dan pemberitahuan dikirim bila ada
peringatan.

Alur tes simulasi sampai kenaikan tingkat juga dibagi menjadi dua diagram;
Gambar 5.16 menggambarkan pelaksanaan tes dengan token.

[GAMBAR 5.16: activity Diagram Tes Simulasi dengan Token]

Gambar 5.16
Activity Diagram Tes Simulasi dengan Token

Guru membuka sesi tes untuk satu kode tes, dan sistem menerbitkan token enam
karakter yang berlaku lima belas menit. Murid memasukkan token dan memulai
tes; fungsi startTest mencatat jam server untuk setiap bagian, sehingga batas
waktu tidak bergantung pada jam perangkat murid. Murid mengerjakan dan
mengirim jawaban per bagian, dan sistem menilai setiap bagian sesuai Algoritma
5.5. Penghubung A menandai kelanjutan alur pada Gambar 5.17.

Gambar 5.17 menggambarkan penilaian akhir sampai kenaikan tingkat.

[GAMBAR 5.17: activity Diagram Penilaian Akhir dan Kenaikan Tingkat]

Gambar 5.17
Activity Diagram Penilaian Akhir dan Kenaikan Tingkat

Bila tes memuat soal menulis bebas, jawabannya masuk antrean penilaian dan
dinilai guru melalui fungsi markAnswer; bila tidak, hasil langsung menjadi
final. Hasil final masuk ke leaderboard dan dipakai untuk menghitung syarat
kenaikan tingkat sesuai Algoritma 5.6. Bila syarat terpenuhi, sistem menulis
rekomendasi yang disetujui atau ditolak admin; setelah disetujui, tingkat
murid dinaikkan, riwayatnya dicatat, dan murid beserta orang tuanya diberi
tahu.

Gambar 5.18 menggambarkan pembelian voucher.

[GAMBAR 5.18: activity Diagram Pembelian Voucher]

Gambar 5.18
Activity Diagram Pembelian Voucher

Murid atau orang tua memilih paket 8 atau 16 sesi pada daftar harga, lalu
fungsi createInvoice membuat tagihan terbuka atau memakai ulang tagihan lama
yang belum dibayar. Untuk pembayaran daring, fungsi meminta Snap token dengan
server key yang hanya ada di Cloud Functions, pembeli membayar pada halaman
Midtrans, dan notifikasi pembayaran diperiksa tanda tangannya sebelum invoice
ditandai lunas. Untuk pembayaran tunai atau transfer, admin mencatatnya dengan
markInvoicePaid. Kedua jalur berakhir pada langkah yang sama: term voucher
dibuat dengan masa berlakunya dan dicatat pada voucher_history, lalu murid
diberi tahu; fungsi expireVouchers menghanguskan sisa sesi setelah tenggat.

## 5.9 Desain Basis Data

Cloud Firestore menyimpan data sebagai dokumen di dalam koleksi [8].
Hubungan antarkoleksi digambarkan pada Gambar 5.19 sampai Gambar 5.24, dan
koleksi utama beserta field pentingnya dirangkum pada Tabel 5.11. Beberapa ID
dokumen disusun dari data lain agar satu kejadian tidak tersimpan dua kali:
{jadwalId}_{tanggal} untuk sesi, {sesiId}_{muridId} untuk absensi dan buku
besar voucher, {muridId}_{tingkat} untuk rekomendasi kenaikan, dan
{guruId}_{bulan} untuk rekap guru. Pengaturan yang dapat diubah admin
disimpan pada koleksi settings (pricing, scheduling, promotion, rooms).

Hubungan antara pengguna, jadwal mingguan, dan sesi kelas ditunjukkan pada
Gambar 5.19.

[GAMBAR 5.19: struktur Koleksi Pengguna, Jadwal, dan Sesi Kelas]

Gambar 5.19
Struktur Koleksi Pengguna, Jadwal, dan Sesi Kelas

Koleksi users menyimpan satu dokumen untuk setiap akun dengan ID yang sama
dengan uid Firebase Authentication, beserta peran, status, dan tingkatnya.
Koleksi schedules menyimpan pola kelas mingguan, sedangkan class_sessions
menyimpan kejadian kelas pada satu tanggal. ID sesi disusun dari ID jadwal dan
tanggalnya, sehingga fungsi generateSessions yang dijalankan berulang tidak
membuat sesi ganda. Field teacherId pada sesi disalin dari jadwal dan berubah
bila admin menunjuk guru pengganti.

Pemesanan sesi dan kehadiran murid disimpan pada koleksi attendance seperti
pada Gambar 5.20.

[GAMBAR 5.20: struktur Koleksi Pemesanan, Kehadiran, dan Daftar Tunggu]

Gambar 5.20
Struktur Koleksi Pemesanan, Kehadiran, dan Daftar Tunggu

Satu dokumen attendance mewakili satu murid pada satu sesi; field booked
mencatat pesanan, sedangkan attendanceStatus dan sessionCredited diisi saat
sesi ditutup. ID dokumen disusun dari ID sesi dan ID murid, sehingga seorang
murid tidak dapat memesan sesi yang sama dua kali. Field classTermId menunjuk
voucher yang sesinya dipakai untuk pesanan itu. Koleksi waitlist menyimpan
antrean kelas yang penuh dengan pola ID yang sama; ketika ada kursi kosong,
antrean pertama dipesankan secara otomatis.

Koleksi yang menyimpan pembayaran dan voucher ditunjukkan pada Gambar 5.21.

[GAMBAR 5.21: struktur Koleksi Tagihan, Voucher, dan Buku Besar Voucher]

Gambar 5.21
Struktur Koleksi Tagihan, Voucher, dan Buku Besar Voucher

Setiap voucher pada student_class_terms menunjuk tagihan asalnya melalui
sourceInvoiceId, dan satu tagihan menghasilkan paling banyak satu voucher.
Setiap perubahan jumlah sesi dicatat sebagai satu dokumen voucher_history yang
menunjuk voucher melalui termId. ID buku besar disusun dari kejadiannya: ID
tagihan untuk pembelian, gabungan ID sesi dan ID murid untuk pemakaian, dan ID
voucher untuk sisa sesi yang hangus. Karena satu ID hanya dapat dibuat sekali,
satu kejadian tidak dapat tercatat dua kali.

Koleksi yang dipakai untuk latihan ditunjukkan pada Gambar 5.22.

[GAMBAR 5.22: struktur Koleksi Bank Soal, Paket Latihan, dan Hasil Latihan]

Gambar 5.22
Struktur Koleksi Bank Soal, Paket Latihan, dan Hasil Latihan

Setiap butir soal disimpan sebagai satu dokumen question_bank beserta kode dan
judul lembar soalnya. Paket latihan pada exercises tidak menyalin soal, tetapi
hanya menyimpan daftar lembar dan butir soal yang dipakainya. Hasil pengerjaan
ditulis ke exercise_results oleh fungsi finishExercise; paket berwaktu yang
dapat diulang juga menyimpan nomor percobaannya. Jawaban yang harus diperiksa
guru masuk ke marking_items dengan ID gabungan ID hasil dan ID soal, sehingga
satu jawaban hanya memiliki satu butir penilaian.

Tes simulasi yang diawasi memakai empat koleksi seperti pada Gambar 5.23.

[GAMBAR 5.23: struktur Koleksi Kode Tes, Sesi Tes, Percobaan, dan Hasil Tes]

Gambar 5.23
Struktur Koleksi Kode Tes, Sesi Tes, Percobaan, dan Hasil Tes

Kode tes menjadi ID dokumen test_codes dan menunjuk lembar soalnya melalui
sheetKey. Setiap kali guru membuka tes, satu dokumen test_sessions dibuat
dengan token yang berlaku selama 15 menit. Pengerjaan murid disimpan pada
test_attempts dan hasilnya pada test_results dengan ID yang sama, yaitu
gabungan kode tes dan ID murid. Murid yang mengerjakan kode yang sama pada
sesi baru mendapat dokumen dengan akhiran nomor duduk, dan hanya duduk pertama
yang sah yang ditandai counts untuk leaderboard dan kenaikan tingkat.

Tiga koleksi yang isinya dihitung dari data lain ditunjukkan pada Gambar 5.24.

[GAMBAR 5.24: koleksi Turunan untuk Leaderboard, Kenaikan Tingkat, dan Laporan Progress]

Gambar 5.24
Koleksi Turunan untuk Leaderboard, Kenaikan Tingkat, dan Laporan Progress

Setiap kali sebuah dokumen test_results ditulis, trigger onTestResultWritten
memperbarui entri leaderboard murid pada kode tes itu, menghitung ulang jumlah
kode yang lulus, dan memperbarui ringkasan progress. Entri leaderboard
menyimpan rankKey, yaitu urutan peringkat dalam satu nilai, sehingga papan
peringkat dapat dibaca per halaman. Dokumen level_promotions berisi
rekomendasi kenaikan tingkat yang menunggu keputusan admin. Karena ketiganya
hanya ditulis oleh Cloud Functions, murid tidak dapat mengubah peringkat,
rekomendasi, maupun ringkasannya sendiri.

Tabel 5.11
Koleksi Utama Cloud Firestore

| Koleksi | Isi | Field utama |
|---|---|---|
| users | Akun dan profil semua peran | role, status, active, name, nameChinese, level, levels (guru), availability, linkedParentUid, placementChoice, placementResultCode, rejectReason |
| schedules | Jadwal mingguan | weekday, startMinutes, endMinutes, room, teacherId, coTeacherIds, capacity, level, validFrom, validTo, active |
| class_sessions | Sesi per tanggal | scheduleId, sessionDate, startMinutes, endMinutes, teacherId, coTeacherIds, room, capacity, bookedCount, status, checkInAt, lateCheckIn, isConcluded, generated, holiday |
| attendance | Pesanan dan absensi murid per sesi | sessionId, studentId, booked, attended, attendanceStatus, classTermId, sessionCredited, closed, joinedAt |
| waitlist | Daftar tunggu kelas penuh | sessionId, studentId, sessionDate, createdAt |
| student_class_terms | Voucher (term) murid | studentId, packageSize, sessionsUsed, sessionsBooked, sessionsRemaining, sessionsForfeited, startDate, deadlineDate, status, sourceInvoiceId, voucherCode |
| voucher_history | Buku besar pemakaian voucher | kind, studentId, termId, sessionId, sessionDate, status, sessions, date |
| invoices | Tagihan dan pembayaran | studentId, kind, item, packageSize, amount, status, paymentMethod, midtransOrderId, paidAt, paidBy, classTermId, discardReason |
| question_bank | Butir soal dan lembar kerja | type, skillCategory, category, level, question, section, sheetCode, sheetTitle, sectionAudioUrl, transcript, createdBy |
| exercises | Paket latihan dan tes | title, level, bankSheets, bankQuestionIds, timeLimitMinutes, isPublished, teacherId |
| exercise_assignments, exercise_attempts, exercise_results | Penugasan, percobaan berjalan, hasil akhir | exerciseId, studentId, dueDate; startedAt; score, correct, total, category, late, attemptNo, submittedAt |
| marking_items | Antrean penilaian guru | resultId, studentId, questionId, answerText, maxPoints, mark, status |
| test_formats, test_codes | Format HSK per tingkat; kode tes | parts, durasi, passMark; code, level, year, sheetKey, active, placement |
| test_sessions, test_attempts, test_results | Sesi tes yang dibuka guru, percobaan murid, hasil | token, openedBy, codeId; part, partClocks, events; parts, total, mark, passed, valid, status, sittingNo, counts |
| placement_results | Hasil tes penempatan pengunjung | codeId, level, total, passed, recommendedLevel, resultCode, claimed |
| leaderboards/{codeId}/entries | Peringkat per kode tes | studentId, studentNameChinese, total, parts, seconds, finishedAt, rankKey |
| promotion_progress, level_promotions, level_paths | Kemajuan, rekomendasi, dan daftar centang kenaikan tingkat | count, codes, minCodes, mode; fromLevel, toLevel, status, decision, declineReason; items |
| progress_summary, progress_notes | Ringkasan progress dan catatan guru | attendance, practice, tests, voucher, warnings, status; studentId, teacherId, note |
| notifications, announcements | Pemberitahuan per pengguna dan pengumuman | kind, title, body, forRole, userId, read; title, body, audience, toDate, notify |
| teacher_recaps, reports, audit_logs | Rekap guru per bulan, laporan bulanan, jejak audit | held, hours, lateCheckIns, students; newStudents, revenue, activeStudents; action, actorId, targetId |
| settings, holidays, schedule_locks, paper_drafts | Pengaturan, hari libur, kunci transaksi jadwal, naskah soal yang belum selesai dibaca | items, minGapMinutes, teacherReadiness, minCodes; date, closed; – ; pages, slots |

## 5.10 Aturan Akses

Firestore Security Rules [9] dijalankan server untuk setiap permintaan
baca dan tulis dari aplikasi, sedangkan Cloud Functions memakai Admin SDK dan
tidak dibatasi aturan ini. Prinsipnya: data yang menentukan uang atau nilai
hanya ditulis fungsi; murid membaca data miliknya sendiri; orang tua membaca
data anak yang ditautkan; staf membaca data murid; admin mengelola data induk.
Ringkasan aturan untuk koleksi utama ditunjukkan pada Tabel 5.12. Kunci
jawaban tidak pernah dikirim ke perangkat murid: jawaban dikirim ke fungsi,
dan fungsi mengembalikan nilai beserta ulasan.

Tabel 5.12
Ringkasan Aturan Akses

| Koleksi | Murid | Orang tua | Guru | Admin | Cloud Functions |
|---|---|---|---|---|---|
| users | Baca dan ubah profil sendiri (bukan level dan status) | Baca anak yang ditautkan | Baca | Baca dan tulis | Tulis |
| schedules, schedule_locks | Baca jadwal | Baca | Baca | Baca (tulis lewat saveSchedule) | Tulis |
| class_sessions, attendance | Baca sesi; baca absensi sendiri | Baca absensi anak | Baca | Baca | Tulis (bookSession, closeSession) |
| student_class_terms, voucher_history | Baca milik sendiri | Baca milik anak | Baca murid | Baca | Tulis |
| invoices | Baca milik sendiri | Baca milik anak | Tidak | Baca dan buat | Tulis (createInvoice, markInvoicePaid, webhook) |
| question_bank, exercises | Baca paket yang ditugaskan, tanpa kunci | Tidak | Tulis milik sendiri | Tulis | Baca |
| exercise_results, test_results, marking_items | Baca milik sendiri | Baca milik anak | Baca murid; nilai lewat markAnswer | Baca | Tulis |
| test_codes, test_sessions, test_attempts | Tidak (lewat fungsi) | Tidak | Baca; buka sesi lewat fungsi | Tulis kode (hapus hanya kode yang belum dipakai) | Tulis |
| leaderboards | Baca (nama Mandarin peserta lain) | Baca | Baca | Baca | Tulis |
| level_promotions, promotion_progress, progress_summary | Baca milik sendiri | Baca milik anak | Baca | Baca; putuskan lewat decidePromotion | Tulis |
| notifications, announcements | Baca milik sendiri; baca pengumuman | Sama | Sama | Tulis pengumuman | Tulis |
| settings, holidays, level_paths, paper_drafts | Baca pengaturan umum | Baca | Baca | Tulis | Baca |

## 5.11 Daftar Cloud Functions

Seluruh logika sisi server berada pada 74 Cloud Functions Node.js 22 [7],
dengan logika murni (tanpa Firestore) dipisahkan ke berkas tersendiri agar
dapat diuji dengan skrip Node: scheduling, teaching_day, payments,
typing_matcher, supervised_test, marking, promotion, placement, progress, dan
reports. Fungsi dikelompokkan menurut bidangnya pada Tabel 5.13.

Tabel 5.13
Daftar Cloud Functions menurut Bidang

| Bidang | Fungsi (pemicu) |
|---|---|
| Akun dan tautan | resolveLinkCode, resolveChildCode, linkChild, deleteUserAccount, deleteMyAccount (callable); onUserCreated (trigger); cleanupExpiredLinkCodes (terjadwal) |
| Pendaftaran dan penempatan | decideRegistration, registrationPlacement, placementMenu, startPlacement, submitPlacementPart, reportPlacementEvent, resolvePlacementResult, runPlacementCleanup (callable); cleanPlacementResults (terjadwal) |
| Jadwal dan sesi | checkScheduleConflict, saveSchedule, deleteSchedule, setDayClosed, importHolidays, confirmSchedule, requestScheduleChange, resolveScheduleChange (callable); generateSessions (terjadwal) |
| Pemesanan dan daftar tunggu | bookSession, cancelBooking, joinWaitlist, leaveWaitlist (callable); onSessionSeatsChanged (trigger) |
| Hari mengajar | checkInSession, closeSession, substituteCandidates, assignSubstitute, cancelSession, reconcileVouchers, teacherRecap, runTeachingDayPass (callable); sessionReminders, checkTeacherCheckIn (terjadwal) |
| Voucher dan pembayaran | createInvoice, discardInvoice, markInvoicePaid (callable); midtransNotification (HTTP); expireVouchers (terjadwal) |
| Latihan | startExercise, checkExerciseAnswer, finishExercise (callable); onExerciseResultCreated, onExerciseResultWritten (trigger) |
| Tes simulasi dan penilaian guru | openTestSession, startTest, submitTestPart, reportTestEvent, closeTestSession, setTestResultValidity, getTestReview, markAnswer, resetTestAttempt (callable); closeForgottenTestSessions (terjadwal) |
| Kenaikan tingkat dan leaderboard | decidePromotion, promoteStudent (callable); onTestResultWritten, onExerciseResultForPath, onLevelPathWritten (trigger) |
| Progress | rebuildProgressSummaries (callable); onAttendanceWritten, onClassTermWritten, onProgressNoteWritten (trigger); dailyReminders (terjadwal) |
| Pemberitahuan dan laporan | onNotificationCreated, onAnnouncementCreated (trigger); monthlyReport (terjadwal); rebuildMonthlyReport (callable) |

## 5.12 Desain Antarmuka

Antarmuka mengikuti arahan desain Pensil yang dipakai pada halaman
depan (maskot pensil, warna hijau dan kuning merek Easy Study), dengan
tampilan yang lebih tenang di dalam aplikasi (permukaan putih, sedikit
hiasan) serta mode gelap. Setiap peran mempunyai halaman beranda dengan tab
di bawah pada telepon dan menu samping di layar lebar; bahasa antarmuka
(Indonesia atau Inggris) dipilih pada halaman login dan tab profil.

Daftar yang dapat menjadi panjang, seperti pengguna, tagihan, antrean
penilaian, jejak audit, dan riwayat kelas, dibaca per halaman berisi 25 baris
dengan kursor Cloud Firestore, dan daftar yang berurutan menurut tanggal
mempunyai pilihan rentang tanggal, sehingga aplikasi hanya membaca data yang
sedang ditampilkan. Laporan admin memakai satu pilihan periode dari bulan ke
bulan, dan ekspor CSV atau PDF mengikuti rentang yang dipilih.

Peta halaman dibagi menjadi dua diagram; Gambar 5.25 memuat halaman umum dan
halaman admin.

[GAMBAR 5.25: peta Halaman Umum dan Admin]

Gambar 5.25
Peta Halaman Umum dan Admin

Halaman umum dapat dibuka tanpa masuk: halaman depan, login dengan pilihan
bahasa, pendaftaran murid baru, tes penempatan untuk pengunjung, halaman
menunggu persetujuan, dan kebijakan privasi. Halaman admin disusun untuk PC
dan mencakup dashboard, pengguna dan persetujuan, bank soal dan kode tes,
paket latihan, timetable, halaman kelas, voucher dan invoice, promosi tingkat,
laporan, pengumuman, pengaturan organisasi, dan profil.

Gambar 5.26 memuat halaman guru, murid, dan orang tua.

[GAMBAR 5.26: peta Halaman Guru, Murid, dan Orang Tua]

Gambar 5.26
Peta Halaman Guru, Murid, dan Orang Tua

Halaman guru dan murid disusun untuk telepon dan mengikuti urutan pekerjaan
sehari-hari: guru dari jadwal mengajar sampai antrean penilaian, murid dari
beranda sampai profil. Orang tua mempunyai empat halaman, yaitu progress anak,
kehadiran anak, tagihan dan pembayaran, serta profil. Tampilan setiap halaman
dibahas pada Bab VI.
