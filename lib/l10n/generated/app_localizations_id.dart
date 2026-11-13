// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get commonCancel => 'Batal';

  @override
  String get commonOk => 'OK';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Kata sandi';

  @override
  String get commonSignIn => 'Masuk';

  @override
  String get commonSignOut => 'Keluar';

  @override
  String get commonCreateNewAccount => 'Buat akun baru';

  @override
  String get commonRememberDevice => 'Ingat di perangkat ini';

  @override
  String get commonClassSession => 'Sesi kelas';

  @override
  String get commonViewClassCalendar => 'Lihat kalender kelas';

  @override
  String get commonViewGrades => 'Lihat nilai & transkrip';

  @override
  String get commonLearningMaterials => 'Materi belajar';

  @override
  String get commonYourLevel => 'Level Anda';

  @override
  String get commonCodeHint => 'Kode 6 karakter';

  @override
  String get commonHskLevel => 'Level HSK';

  @override
  String get commonLessonsPerTerm => 'Pelajaran per periode';

  @override
  String commonLessonsPerTermOption(int count) {
    return '$count pelajaran per periode';
  }

  @override
  String get commonCompleted => 'Selesai';

  @override
  String get commonFull => 'Penuh';

  @override
  String commonSpotsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sisa $count tempat',
    );
    return '$_temp0';
  }

  @override
  String get commonCopy => 'Salin';

  @override
  String get commonStudent => 'Murid';

  @override
  String get commonParent => 'Orang tua';

  @override
  String get pushRowLabel => 'Notifikasi push';

  @override
  String get pushRowHint =>
      'Pengingat di perangkat ini saat ada tugas jatuh tempo atau nilai keluar.';

  @override
  String get pushRowBlocked =>
      'Notifikasi diblokir di pengaturan browser atau HP.';

  @override
  String get pushEnableFailed => 'Notifikasi tidak bisa diaktifkan. Coba lagi.';

  @override
  String get languageRowLabel => 'Bahasa / Language';

  @override
  String get languageToggleIndonesian => 'Bahasa Indonesia';

  @override
  String get languageToggleEnglish => 'English';

  @override
  String get themeRowLabel => 'Tampilan';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeSystemHint =>
      'Sistem: mengikuti pengaturan HP atau komputer Anda.';

  @override
  String get textSizeRowLabel => 'Ukuran teks';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeBig => 'Besar';

  @override
  String get textSizeBigger => 'Lebih besar';

  @override
  String get appearanceMenuTooltip => 'Tampilan: mode gelap dan ukuran teks';

  @override
  String get authBrandHeadline => 'Belajar Mandarin,\ndengan mudah.';

  @override
  String get teacherLinkCodeLabel => 'Kode tautan guru';

  @override
  String get teacherLinkCodeHelper =>
      'Minta kode terbaru kepada guru Anda (diperbarui setiap 15 menit)';

  @override
  String get teacherLinkCodeRequired => 'Masukkan kode tautan guru Anda';

  @override
  String get loginSubtitle => 'Ketuk akun untuk masuk';

  @override
  String get loginFailed => 'Gagal masuk';

  @override
  String loginProfileLoadFailed(String code) {
    return 'Anda sudah masuk, tetapi profil Anda tidak dapat dimuat ($code). Periksa koneksi Anda lalu coba lagi.';
  }

  @override
  String get loginRemoveAccountTitle => 'Hapus akun?';

  @override
  String loginRemoveAccountBody(String name) {
    return 'Hapus $name dari perangkat ini? Anda dapat masuk lagi nanti.';
  }

  @override
  String get loginRemove => 'Hapus';

  @override
  String get loginResetTitle => 'Atur ulang kata sandi';

  @override
  String get loginResetBody =>
      'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat kata sandi baru.';

  @override
  String get loginSendResetLink => 'Kirim tautan';

  @override
  String loginResetSent(String email) {
    return 'Jika $email memiliki akun, tautan untuk mengatur ulang kata sandi sedang dikirim. Periksa kotak masuk dan folder spam Anda.';
  }

  @override
  String get loginResetInvalidEmail =>
      'Alamat email tersebut sepertinya kurang tepat. Periksa lalu coba lagi.';

  @override
  String get loginResetTooManyRequests =>
      'Terlalu banyak percobaan. Tunggu beberapa menit lalu coba lagi.';

  @override
  String get loginResetFailed =>
      'Tautan tidak dapat dikirim. Silakan coba lagi.';

  @override
  String get loginWithAnotherEmail => 'Masuk dengan email lain';

  @override
  String get loginAnotherAccount => 'Akun lain';

  @override
  String get loginForgotPassword => 'Lupa kata sandi?';

  @override
  String get loginBackToAccountList => 'Kembali ke daftar akun';

  @override
  String get loginBackToTestLogin => 'Kembali ke login uji';

  @override
  String get loginNoSavedAccounts => 'Belum ada akun tersimpan';

  @override
  String get loginNoSavedAccountsHint =>
      'Masuk sekali, dan akun Anda akan muncul di sini agar lebih cepat lain kali.';

  @override
  String get registerTitle => 'Buat akun';

  @override
  String get registerSubtitle =>
      'Bergabung dengan Easy Study sebagai murid atau orang tua';

  @override
  String get registerErrorEmailInUse =>
      'Email ini sudah terdaftar. Silakan Masuk.';

  @override
  String get registerErrorWeakPassword =>
      'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';

  @override
  String get registerErrorInvalidEmail => 'Alamat email tidak valid.';

  @override
  String get registerErrorOperationNotAllowed =>
      'Masuk dengan email/kata sandi dinonaktifkan di Firebase.';

  @override
  String registerErrorGeneric(String code) {
    return 'Pendaftaran gagal ($code)';
  }

  @override
  String get registerErrorPermissionDenied =>
      'Firestore menolak tindakan ini. Terbitkan firestore.rules dari proyek.';

  @override
  String registerErrorFirebase(String code) {
    return 'Kesalahan Firebase ($code)';
  }

  @override
  String get registerEmailInvalid => 'Masukkan email yang valid';

  @override
  String get registerPasswordTooShort => 'Minimal 6 karakter';

  @override
  String get registerChildCodeLabel => 'Kode akses anak';

  @override
  String get registerChildCodeHelper =>
      'Lihat di Profil anak Anda, bagian \'Akses orang tua\'.';

  @override
  String get registerChildCodeRequired => 'Masukkan kode akses anak Anda';

  @override
  String get registerSubmitParent => 'Daftar sebagai orang tua';

  @override
  String get identityNameIndonesian => 'Nama Indonesia';

  @override
  String get identityNameIndonesianRequired => 'Nama Indonesia wajib diisi';

  @override
  String get identityNameChinese => 'Nama Mandarin';

  @override
  String get identityNameChineseOptional => 'Nama Mandarin (opsional)';

  @override
  String get identityNameChineseRequired => 'Nama Mandarin wajib diisi';

  @override
  String get identityWhatsapp => 'Nomor WhatsApp';

  @override
  String get identityWhatsappOptional => 'Nomor WhatsApp (opsional)';

  @override
  String get identityWhatsappRequired => 'Nomor WhatsApp wajib diisi';

  @override
  String get identityParentSection => 'Orang tua / wali';

  @override
  String get identityParentSectionHint => 'Kontak keluarga murid.';

  @override
  String get identityParentName => 'Nama orang tua';

  @override
  String get identityParentNameOptional => 'Nama orang tua (opsional)';

  @override
  String get identityParentNameRequired => 'Nama orang tua wajib diisi';

  @override
  String get identityParentPhone => 'Telepon orang tua';

  @override
  String get identityParentPhoneOptional => 'Telepon orang tua (opsional)';

  @override
  String get identityParentPhoneRequired => 'Telepon orang tua wajib diisi';

  @override
  String get completeProfileTitle => 'Lengkapi profil Anda';

  @override
  String get completeProfileMissing =>
      'Akun Anda ditemukan, tetapi data profil Anda belum ada.';

  @override
  String get completeProfileFailed => 'Profil tidak dapat dilengkapi';

  @override
  String get completeProfileSave => 'Simpan profil';

  @override
  String get studentNavHome => 'Beranda';

  @override
  String get studentNavMyClasses => 'Riwayat';

  @override
  String get studentNavLessons => 'Pelajaran';

  @override
  String get studentNavProgress => 'Kemajuan';

  @override
  String get navPayments => 'Pembayaran';

  @override
  String get navProfile => 'Profil';

  @override
  String studentHomeGreeting(String name) {
    return 'Halo, $name';
  }

  @override
  String get studentHomeContinueLearning => 'Lanjutkan belajar';

  @override
  String get studentHomeNoPracticeTitle => 'Belum ada latihan';

  @override
  String get studentHomeNoPracticeSubtitle =>
      'Atur level HSK Anda di Profil untuk membuka latihan, atau tunggu latihan baru diterbitkan.';

  @override
  String studentHomeLevelPractice(String level) {
    return 'Latihan $level';
  }

  @override
  String get studentHomeNextLesson => 'Pelajaran berikutnya';

  @override
  String studentHomeLessonMeta(String term, int order) {
    return '$term · Pelajaran $order';
  }

  @override
  String get studentHomeAllDoneTitle => 'Semua pelajaran selesai';

  @override
  String get studentHomeAllDoneSubtitle =>
      'Kerja bagus — Anda telah menyelesaikan semua pelajaran yang tersedia.';

  @override
  String get studentHomeCompletedPractice => 'Latihan yang sudah selesai';

  @override
  String get studentHomeSessionsLeft => 'Sisa sesi';

  @override
  String get studentHomeExercisesDone => 'Latihan selesai';

  @override
  String get studentHomeAvgScore => 'Nilai rata-rata';

  @override
  String studentHomeStreak(int days) {
    return '$days hari berturut-turut';
  }

  @override
  String studentHomeBest(int score) {
    return 'terbaik $score%';
  }

  @override
  String studentHomeUntil(String date) {
    return 'sampai $date';
  }

  @override
  String get studentHomeNoVoucher => 'belum ada voucher';

  @override
  String studentHomeSeeAll(int count) {
    return 'Lihat semua ($count)';
  }

  @override
  String studentHomeSeeScores(int count) {
    return '$count selesai · lihat nilai Anda';
  }

  @override
  String get studentHomeQuickCalendar => 'Kalender';

  @override
  String get studentHomeQuickGrades => 'Nilai';

  @override
  String get studentHomeQuickMaterials => 'Materi';

  @override
  String get studentHomeQuickHistory => 'Riwayat';

  @override
  String get studentJoinTitle => 'Ikuti sesi kelas';

  @override
  String get studentJoinHint =>
      'Pilih kelas yang sedang dibuka di bawah. Anda tetap terdaftar sampai guru menutup kelas tersebut.';

  @override
  String get studentJoinNoSessionsTitle => 'Tidak ada sesi yang dibuka';

  @override
  String get studentJoinNoSessionsSubtitle =>
      'Belum ada sesi kelas yang dibuka saat ini. Silakan cek lagi nanti.';

  @override
  String get studentJoinPermissionDenied =>
      'Tidak dapat bergabung: akses ditolak.';

  @override
  String studentJoinFailed(String code) {
    return 'Tidak dapat bergabung ($code)';
  }

  @override
  String get studentJoinClassFullTitle => 'Kelas penuh';

  @override
  String studentJoinClassFullBody(int capacity, int joined) {
    String _temp0 = intl.Intl.pluralLogic(
      capacity,
      locale: localeName,
      other: '$capacity murid',
    );
    return 'Kelas ini sudah mencapai kapasitas $_temp0 ($joined/$capacity bergabung). Coba sesi lain atau cek lagi nanti.';
  }

  @override
  String get studentJoinJoined => 'Anda telah bergabung di sesi ini';

  @override
  String get studentJoinLeftClass => 'Anda telah keluar dari kelas ini';

  @override
  String studentJoinCount(int joined, int capacity) {
    return '$joined / $capacity bergabung';
  }

  @override
  String get studentJoinView => 'Lihat';

  @override
  String get studentJoinLeave => 'Keluar';

  @override
  String get studentJoinNoSessionsLeft => 'Sesi habis';

  @override
  String get studentJoinJoin => 'Gabung';

  @override
  String get studentLessonsNoContentTitle => 'Belum ada konten';

  @override
  String get studentLessonsNoDemoData =>
      'Belum ada data demo — jalankan scripts/seed_test_accounts.sh lalu python3 scripts/seed_report_demo_data.py';

  @override
  String get studentLessonsSetLevel =>
      'Atur level HSK Anda di Profil untuk membuka latihan dan pelajaran.';

  @override
  String studentLessonsWillAppear(String level) {
    return 'Latihan dan pelajaran $level yang sudah diterbitkan akan muncul di sini.';
  }

  @override
  String studentLessonsExercisesHeader(String level, int count) {
    return 'Latihan $level ($count)';
  }

  @override
  String get studentLessonsNoExercisesTitle => 'Belum ada latihan';

  @override
  String get studentLessonsNoExercisesSetLevel =>
      'Atur level HSK Anda di Profil untuk melihat latihan.';

  @override
  String studentLessonsNoPublishedExercises(String level) {
    return 'Belum ada latihan $level yang diterbitkan.';
  }

  @override
  String studentLessonsLevelTermInfo(String level, int count) {
    return '$level · $count pelajaran per periode';
  }

  @override
  String studentLessonsTermHeader(String term, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pelajaran',
    );
    return 'Periode $term ($_temp0)';
  }

  @override
  String studentLessonsQuizScore(String score) {
    return 'Kuis: $score%';
  }

  @override
  String get studentMyClassesEmptyTitle => 'Belum ada kelas yang diikuti';

  @override
  String get studentMyClassesEmptySubtitle =>
      'Buka Beranda lalu ketuk Gabung pada sesi kelas yang dibuka.';

  @override
  String get studentMyClassesTapToSee =>
      'Ketuk untuk melihat siapa yang bergabung';

  @override
  String get historyVouchersTitle => 'Voucher Anda';

  @override
  String get historyNoVouchers =>
      'Belum ada voucher. Setelah Anda membayar paket, admin menambahkannya di sini.';

  @override
  String historyVoucherTitle(int sessions) {
    return 'Voucher $sessions sesi';
  }

  @override
  String historyValid(String start, String end) {
    return 'Berlaku $start – $end';
  }

  @override
  String get historyStatusActive => 'Aktif';

  @override
  String get historyStatusUsedUp => 'Habis';

  @override
  String get historyStatusExpired => 'Kedaluwarsa';

  @override
  String historySessionsUsed(int used, int total) {
    return '$used dari $total sesi terpakai';
  }

  @override
  String historyRemaining(int count) {
    return 'Sisa $count';
  }

  @override
  String historyShowSessions(int count) {
    return 'Lihat kelas ($count)';
  }

  @override
  String get historyHideSessions => 'Sembunyikan kelas';

  @override
  String get historyNoSessionsYet =>
      'Belum ada kelas yang dipotong dari voucher ini.';

  @override
  String get historyAllClasses => 'Semua kelas';

  @override
  String historyClassesCount(int count) {
    return '$count kelas';
  }

  @override
  String get attendancePresent => 'Hadir';

  @override
  String get attendanceExcused => 'Izin';

  @override
  String get attendanceAbsent => 'Alpa';

  @override
  String get attendanceJoined => 'Bergabung';

  @override
  String get studentPaymentsDisabledTitle => 'Pembayaran tidak aktif';

  @override
  String get studentPaymentsDisabledSubtitle =>
      'Saat ini pusat belajar Anda tidak menerima pembayaran melalui aplikasi. Hubungi guru Anda mengenai paket sesi.';

  @override
  String get studentPaymentsInvoices => 'Tagihan';

  @override
  String get studentPaymentsNoInvoices =>
      'Belum ada tagihan. Tagihan paket sesi dari guru Anda akan muncul di sini.';

  @override
  String studentPaymentsSessionsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count sesi',
    );
    return '$_temp0';
  }

  @override
  String get studentPaymentsQuotaHint =>
      'Sesi ditambahkan otomatis setelah pembayaran dikonfirmasi.';

  @override
  String studentPaymentsParentHandles(String name) {
    return 'Pembayaran diurus oleh $name.';
  }

  @override
  String get studentPaymentsParentHandlesHint =>
      'Orang tua Anda melihat tagihan yang sama dan bisa membayarnya. Anda tetap bisa membayar sendiri di bawah bila perlu.';

  @override
  String get studentProgressNoProgressTitle => 'Belum ada kemajuan';

  @override
  String get studentProgressNoProgressSubtitle =>
      'Selesaikan pelajaran atau kuis untuk melihat riwayat Anda di sini.';

  @override
  String get studentProgressNoLessonsTitle => 'Belum ada pelajaran';

  @override
  String studentProgressNoLessonsSubtitle(String level) {
    return 'Belum ada pelajaran untuk $level.';
  }

  @override
  String get studentProgressYourHskLevel => 'level HSK Anda';

  @override
  String get studentProgressTermSize => 'Pelajaran per periode';

  @override
  String get studentProgressStartFirst =>
      'Mulai pelajaran pertama Anda untuk memantau kemajuan';

  @override
  String get studentProgressTermPlan => 'Rencana periode Anda';

  @override
  String get studentProgressCurrentTerm => 'Periode saat ini';

  @override
  String get studentProgressLessons => 'Pelajaran';

  @override
  String get studentProgressExercises => 'Latihan';

  @override
  String get studentProgressAttempts => 'Percobaan';

  @override
  String get studentProgressAvgScore => 'Nilai rata-rata';

  @override
  String get studentProgressBestScore => 'Nilai terbaik';

  @override
  String get studentProgressNoExercisesTitle =>
      'Belum ada latihan yang selesai';

  @override
  String get studentProgressNoExercisesSubtitle =>
      'Selesaikan latihan dari Beranda atau Pelajaran, nilai Anda akan muncul di sini.';

  @override
  String resultCorrectOf(int correct, int total) {
    return '$correct/$total benar';
  }

  @override
  String get commonExerciseFallback => 'Latihan';

  @override
  String get studentProfileUpdated => 'Profil diperbarui';

  @override
  String get studentProfilePersonalTitle => 'Informasi pribadi';

  @override
  String get studentProfilePersonalSubtitle =>
      'Nama Indonesia dan Mandarin, WhatsApp, serta kontak orang tua.';

  @override
  String get studentProfileLearningTitle => 'Pembelajaran';

  @override
  String get studentProfileLearningSubtitle =>
      'Level HSK Anda menentukan latihan yang Anda lihat.';

  @override
  String studentProfileCodeFailed(String error) {
    return 'Kode tidak dapat dibuat: $error';
  }

  @override
  String get studentProfileParentAccessTitle => 'Akses orang tua';

  @override
  String get studentProfileParentAccessBody =>
      'Bagikan kode ini kepada orang tua agar mereka dapat mendaftar dan mengikuti kemajuan Anda (hanya dapat dilihat).';

  @override
  String get studentProfileCodeCopied => 'Kode disalin';

  @override
  String get studentProfileShowParentCode => 'Tampilkan kode akses orang tua';

  @override
  String studentClassLeaveFailed(String code) {
    return 'Tidak dapat keluar dari kelas ($code)';
  }

  @override
  String get studentClassNotFound => 'Kelas tidak ditemukan';

  @override
  String get studentClassYourTeacher => 'Guru Anda';

  @override
  String studentClassTimeAndTeacher(String time, String teacher) {
    return '$time · Guru: $teacher';
  }

  @override
  String studentClassStudentsJoined(int joined, int capacity) {
    return '$joined/$capacity murid bergabung';
  }

  @override
  String get studentClassLeaveClass => 'Keluar dari kelas';

  @override
  String studentClassWhoJoined(int count) {
    return 'Yang bergabung ($count)';
  }

  @override
  String get studentClassNoneJoined => 'Belum ada murid yang bergabung.';

  @override
  String studentClassYou(String name) {
    return '$name (Anda)';
  }

  @override
  String get studentClassJoinedFromApp => 'Bergabung lewat aplikasi';

  @override
  String get studentClassAddedByTeacher => 'Ditambahkan oleh guru';

  @override
  String get lessonDetailTitle => 'Pelajaran';

  @override
  String get lessonDetailNotFoundTitle => 'Pelajaran tidak ditemukan';

  @override
  String get lessonDetailNotFoundSubtitle =>
      'Pelajaran ini mungkin sudah dihapus.';

  @override
  String get lessonDetailVocabulary => 'Kosakata & catatan';

  @override
  String get lessonDetailStartQuiz => 'Mulai kuis';

  @override
  String get parentNavOverview => 'Ringkasan';

  @override
  String get parentNavCalendar => 'Kalender';

  @override
  String get parentNoChildrenTitle => 'Belum ada anak yang terhubung';

  @override
  String get parentNoChildrenSubtitle =>
      'Minta admin pusat belajar untuk menghubungkan akun Anda dengan anak Anda, atau daftar ulang dengan kode akses anak.';

  @override
  String get parentChildLabel => 'Anak';

  @override
  String get parentOverviewSessionsRemaining => 'Sisa sesi';

  @override
  String get parentOverviewLessonsDone => 'Pelajaran selesai';

  @override
  String get parentOverviewAvgScore => 'Nilai rata-rata';

  @override
  String get parentOverviewRecentGrades => 'Nilai terbaru';

  @override
  String get parentOverviewNoGrades => 'Belum ada latihan yang dinilai.';

  @override
  String get parentOverviewPractice => 'Latihan';

  @override
  String get parentOverviewRecentClasses => 'Kelas terbaru';

  @override
  String get parentOverviewClassHistory => 'Kelas dan voucher';

  @override
  String get parentOverviewNoClasses => 'Belum ada kelas yang dihadiri.';

  @override
  String get parentPaymentsEmptyTitle => 'Belum ada tagihan';

  @override
  String get parentPaymentsEmptySubtitle =>
      'Tagihan untuk anak Anda akan muncul di sini.';

  @override
  String get parentProfileRole => 'Orang Tua';

  @override
  String get parentProfileLinkedChildren => 'Anak yang terhubung';

  @override
  String get parentProfileNoChildren =>
      'Belum ada anak yang terhubung. Minta admin untuk menghubungkan akun Anda.';

  @override
  String get exercisePlayNotAvailableTitle => 'Latihan tidak tersedia';

  @override
  String get exercisePlayNotAvailableSubtitle =>
      'Latihan ini belum ditugaskan kepada Anda. Tanyakan kepada guru Anda.';

  @override
  String get exercisePlayLegacyTitle => 'Format latihan lama';

  @override
  String get exercisePlayLegacySubtitle =>
      'Latihan ini dibuat sebelum ada bank soal dan tidak bisa dikerjakan lagi. Minta latihan baru kepada guru Anda.';

  @override
  String get exercisePlayLoadFailedTitle => 'Latihan tidak dapat dimuat';

  @override
  String get exercisePlayNotFoundTitle => 'Latihan tidak ditemukan';

  @override
  String get exercisePlayNotFoundSubtitle =>
      'Latihan ini mungkin sudah dihapus.';

  @override
  String get exercisePlayNoQuestionsTitle => 'Belum ada soal';

  @override
  String get exercisePlayNoQuestionsSubtitle =>
      'Guru Anda belum menambahkan soal ke latihan ini.';

  @override
  String get exercisePlayChecking => 'Memeriksa jawaban Anda…';

  @override
  String get exercisePlayCouldNotSubmitTitle => 'Jawaban tidak terkirim';

  @override
  String get exercisePlayCouldNotSubmitMessage =>
      'Jawaban tidak dapat dikirim.';

  @override
  String get exercisePlayCheckConnection =>
      'Periksa koneksi Anda lalu coba lagi.';

  @override
  String get exercisePlayTryAgain => 'Coba lagi';

  @override
  String get exercisePlayDone => 'Selesai';

  @override
  String get exercisePlayTimeUpSubtitle =>
      'Waktu habis. Jawaban yang sudah Anda isi telah dikirim.';

  @override
  String get exercisePlayReview => 'Pembahasan';

  @override
  String get exercisePlaySubmitNowTitle => 'Kirim sekarang?';

  @override
  String exercisePlayUnansweredWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal belum dijawab. Soal tersebut akan dihitung salah.',
    );
    return '$_temp0';
  }

  @override
  String get exercisePlayKeepAnswering => 'Lanjut menjawab';

  @override
  String get exercisePlaySubmit => 'Kirim';

  @override
  String exercisePlaySentenceOf(int current, int total) {
    return 'Kalimat $current dari $total';
  }

  @override
  String exercisePlayBlankOf(int current, int total) {
    return 'Isian $current dari $total';
  }

  @override
  String exercisePlayMatchOf(int current, int total) {
    return 'Pasangan $current dari $total';
  }

  @override
  String exercisePlayQuestionOf(int current, int total) {
    return 'Soal $current dari $total';
  }

  @override
  String exercisePlayAnsweredOf(int answered, int total) {
    return '$answered dari $total dijawab';
  }

  @override
  String get exercisePlayComposePrompt =>
      'Susun kata-kata menjadi kalimat yang benar';

  @override
  String get exercisePlayComposeHint =>
      'Ketuk kata di bawah untuk menyusun kalimat Anda';

  @override
  String get exercisePlayComposeEmpty => 'Kalimat Anda akan muncul di sini…';

  @override
  String get exercisePlayWordBank => 'Bank kata';

  @override
  String get exercisePlayPictureSentencePrompt =>
      'Tulis satu kalimat yang memakai kata ini:';

  @override
  String get exercisePlayClozeLabel => 'Pilih kata untuk bagian yang kosong';

  @override
  String get exercisePlayPromptLabel => 'Soal';

  @override
  String get exercisePlayChooseResponse => 'Pilih jawaban yang paling tepat';

  @override
  String get exercisePlayBack => 'Kembali';

  @override
  String get exercisePlaySubmitAnswers => 'Kirim jawaban';

  @override
  String get exercisePlayNextSentence => 'Kalimat berikutnya';

  @override
  String get exercisePlayNextMatch => 'Pasangan berikutnya';

  @override
  String get exercisePlayNextQuestion => 'Soal berikutnya';

  @override
  String get exercisePlaySubmitAllNow => 'Kirim semua jawaban sekarang';

  @override
  String exercisePlayReviewPictureSentence(String keyword) {
    return 'Tulis satu kalimat dengan \"$keyword\"';
  }

  @override
  String get exercisePlayReviewCompose => 'Susun kata-kata menjadi kalimat';

  @override
  String exercisePlayReviewQuestionNumber(int number) {
    return 'Soal $number';
  }

  @override
  String exercisePlayReviewKeywordKey(String keyword) {
    return 'Kalimat yang memakai \"$keyword\"';
  }

  @override
  String get exercisePlayNotAnswered => 'Belum dijawab';

  @override
  String exercisePlayYourAnswer(String answer) {
    return 'Jawaban Anda: $answer';
  }

  @override
  String exercisePlayCorrectAnswer(String answer) {
    return 'Kunci jawaban: $answer';
  }

  @override
  String get materialsTitle => 'Materi';

  @override
  String get materialsAdd => 'Tambah materi';

  @override
  String get materialsEmptyTitle => 'Belum ada materi';

  @override
  String get materialsEmptyStudentSubtitle =>
      'Materi yang diterbitkan guru Anda akan muncul di sini.';

  @override
  String get materialsEmptyStaffSubtitle =>
      'Ketuk \"Tambah materi\" untuk mengunggah file atau menambah sumber belajar.';

  @override
  String get materialsOpenFailed => 'File tidak dapat dibuka.';

  @override
  String get materialsEdit => 'Edit';

  @override
  String get materialsStatusPublished => 'Diterbitkan';

  @override
  String get materialsStatusDraft => 'Draf';

  @override
  String get materialsEditTitle => 'Edit materi';

  @override
  String get materialsFieldTitle => 'Judul';

  @override
  String get materialsTitleRequired => 'Masukkan judul';

  @override
  String get materialsFieldLevel => 'Level (opsional)';

  @override
  String get materialsFieldSkill => 'Keterampilan (opsional)';

  @override
  String get materialsFieldTags => 'Tag (pisahkan dengan koma)';

  @override
  String get materialsReplaceFile => 'Ganti file';

  @override
  String get materialsUploadFile => 'Unggah file (opsional)';

  @override
  String get materialsPublishedHint =>
      'Dapat dilihat oleh murid dan orang tua.';

  @override
  String get materialsSaveChanges => 'Simpan perubahan';

  @override
  String get materialsDelete => 'Hapus';

  @override
  String get materialsDeleteTitle => 'Hapus materi?';

  @override
  String materialsDeleteBody(String title) {
    return 'Hapus \"$title\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String scoreSummaryCorrectOf(int correct, int total) {
    return '$correct dari $total benar';
  }

  @override
  String get scoreSummaryPassed => 'Kerja bagus!';

  @override
  String get scoreSummaryKeepPracticing =>
      'Terus berlatih — Anda semakin baik.';

  @override
  String get statusPillOpen => 'Dibuka';

  @override
  String get statusPillClosed => 'Ditutup';

  @override
  String get statusPillConcluded => 'Selesai';

  @override
  String get tableToolsExportCsv => 'Ekspor CSV';

  @override
  String tableToolsDownloadingRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mengunduh $count baris sebagai CSV…',
    );
    return '$_temp0';
  }

  @override
  String tableToolsCopiedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baris disalin sebagai CSV ke papan klip.',
    );
    return '$_temp0';
  }

  @override
  String tableToolsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dipilih',
    );
    return '$_temp0';
  }

  @override
  String get tableToolsClear => 'Hapus pilihan';

  @override
  String get adminDashTotalUsers => 'Total pengguna';

  @override
  String adminDashUsersBreakdown(int students, int teachers) {
    return '$students murid · $teachers guru';
  }

  @override
  String get adminDashActiveMurid => 'Murid aktif';

  @override
  String get adminDashIncomePerMonth => 'Pemasukan / bln';

  @override
  String adminDashNoPaymentsInMonth(String month) {
    return 'Belum ada pembayaran di bulan $month';
  }

  @override
  String adminDashPaymentsInMonth(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pembayaran di bulan $month',
    );
    return '$_temp0';
  }

  @override
  String get adminDashNeedsAttention => 'Perlu perhatian';

  @override
  String get adminDashAllCaughtUpNoAlerts =>
      'Semua beres — tidak ada peringatan voucher saat ini.';

  @override
  String get adminDashFinancialSummary => 'Ringkasan keuangan';

  @override
  String get adminDashRevenueThisMonth => 'Pemasukan bulan ini';

  @override
  String get adminDashPendingPayments => 'Pembayaran menunggu';

  @override
  String get adminDashVouchersWithoutPayment => 'Voucher tanpa pembayaran';

  @override
  String get adminDashActiveVouchersNoInvoice => 'Voucher aktif tanpa tagihan';

  @override
  String get adminDashPendingToChase => 'Pembayaran yang perlu ditagih';

  @override
  String get adminDashOverdue => 'terlambat';

  @override
  String adminDashDue(String date) {
    return 'jatuh tempo $date';
  }

  @override
  String get adminDashNoPaymentsYet => 'Belum ada pembayaran yang tercatat.';

  @override
  String get adminDashRecentPayments => 'Pembayaran terbaru';

  @override
  String get adminDashNewStudentsPerMonth => 'Murid baru / bulan';

  @override
  String get adminDashQuickActions => 'Aksi cepat';

  @override
  String get adminDashNewExercise => 'Latihan baru';

  @override
  String get adminDashNewClass => 'Kelas baru';

  @override
  String adminDashVoucherDepleted(String name) {
    return '$name — voucher habis';
  }

  @override
  String adminDashVoucherLowBalance(String name) {
    return '$name — sisa sesi sedikit';
  }

  @override
  String get adminDashStatAllUsersTitle => 'Semua pengguna';

  @override
  String get adminDashStatAllUsersDesc =>
      'Semua akun di platform — admin, guru, dan murid.';

  @override
  String get adminDashStatActiveMuridDesc => 'Akun murid yang sedang aktif.';

  @override
  String get adminDashStatExercisesTitle => 'Latihan terbit';

  @override
  String get adminDashStatExercisesDesc =>
      'Lembar soal latihan yang sudah terbit dan terlihat oleh murid.';

  @override
  String get adminDashStatIncomeTitle => 'Pemasukan bulanan';

  @override
  String get adminDashStatIncomeDesc =>
      'Pembayaran yang diterima setiap bulan (tagihan yang ditandai lunas, menurut tanggal pembayaran), selama dua belas bulan terakhir.';

  @override
  String get adminDashStatSignupsTitle => 'Pendaftaran murid baru';

  @override
  String get adminDashStatSignupsDesc =>
      'Murid yang mendaftar pada setiap bulan dari enam bulan terakhir.';

  @override
  String get adminDashStatVoucherAlertsTitle => 'Peringatan voucher';

  @override
  String get adminDashStatVoucherAlertsDesc =>
      'Paket kelas dengan sisa dua sesi atau kurang, atau sudah habis.';

  @override
  String get adminDashNoActiveMurid => 'Belum ada murid aktif';

  @override
  String get adminDashActiveAccountsAppear =>
      'Akun murid yang aktif akan muncul di sini.';

  @override
  String adminDashMuridCount(int count) {
    return '$count murid';
  }

  @override
  String adminDashGuruCount(int count) {
    return '$count guru';
  }

  @override
  String adminDashAdminCount(int count) {
    return '$count admin';
  }

  @override
  String adminDashInactiveCount(int count) {
    return '$count nonaktif';
  }

  @override
  String get adminDashNoUsers => 'Belum ada pengguna';

  @override
  String get adminDashUsersAppear =>
      'Pengguna akan muncul di sini setelah mendaftar.';

  @override
  String get adminDashInactive => 'Nonaktif';

  @override
  String get adminDashNoPublishedExercises => 'Belum ada latihan yang terbit';

  @override
  String get adminDashPublishFromTab => 'Terbitkan latihan dari tab Latihan.';

  @override
  String adminDashQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal',
    );
    return '$_temp0';
  }

  @override
  String get adminDashPublished => 'Terbit';

  @override
  String get adminDashNoSignups => 'Belum ada pendaftaran murid';

  @override
  String get adminDashSignupsAppear =>
      'Pendaftaran murid baru akan muncul di sini.';

  @override
  String get adminDashAllCaughtUp => 'Semua beres';

  @override
  String get adminDashNoVoucherAlerts =>
      'Tidak ada peringatan voucher saat ini.';

  @override
  String get adminDashNoPaymentsTwelveMonths =>
      'Tidak ada pembayaran dalam dua belas bulan terakhir';

  @override
  String get adminDashPaymentsShowHint =>
      'Pembayaran muncul di sini setelah tagihan ditandai lunas di Pembayaran.';

  @override
  String adminDashPaymentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pembayaran',
    );
    return '$_temp0';
  }

  @override
  String get adminReportsTitle => 'Laporan';

  @override
  String adminReportsLoadFailed(String error) {
    return 'Data laporan tidak dapat dimuat: $error';
  }

  @override
  String adminReportsSubtitle(String month) {
    return 'Angka terkini untuk $month. Setiap PDF mencakup 6 bulan terakhir.';
  }

  @override
  String get adminReportsSectionClasses => 'Kelas & guru';

  @override
  String get adminReportsSectionMoney => 'Keuangan';

  @override
  String get adminReportsSectionPlatform => 'Ekspor platform';

  @override
  String get adminReportsPdf => 'PDF';

  @override
  String get adminReportsAttendanceTitle => 'Absensi per murid';

  @override
  String get adminReportsAttendanceDesc =>
      'Hadir / Izin / Alpa setiap murid, bulan demi bulan.';

  @override
  String get adminReportsAlpa => 'Alpa';

  @override
  String get adminReportsRetentionTitle => 'Murid baru & retensi';

  @override
  String get adminReportsRetentionDesc =>
      'Pendaftaran per bulan dan berapa yang masih aktif hari ini.';

  @override
  String get adminReportsNewThisMonth => 'Baru bulan ini';

  @override
  String get adminReportsRetention => 'Retensi';

  @override
  String get adminReportsProgressTitle => 'Kemajuan per level HSK';

  @override
  String get adminReportsProgressDesc =>
      'Latihan yang ditugaskan dan selesai, rata-rata skor terbaik, tanpa aktivitas.';

  @override
  String get adminReportsDone => 'Selesai';

  @override
  String get adminReportsNoActivity => 'Tanpa aktivitas';

  @override
  String get adminReportsOverdueHomeworkTitle => 'PR terlambat';

  @override
  String get adminReportsOverdueHomeworkDesc =>
      'Tugas lewat jatuh tempo yang belum dikumpulkan, per guru.';

  @override
  String get adminReportsOpen => 'Belum dikerjakan';

  @override
  String get adminReportsTeachers => 'Guru';

  @override
  String get adminReportsFillRateTitle => 'Tingkat keterisian kelas';

  @override
  String get adminReportsFillRateDesc =>
      'Kursi terisi dibanding kapasitas, per bulan dan per kelas.';

  @override
  String get adminReportsClasses => 'Kelas';

  @override
  String get adminReportsEmpty => 'Kosong';

  @override
  String get adminReportsTeacherRecapTitle => 'Rekap guru';

  @override
  String get adminReportsTeacherRecapDesc =>
      'Kelas, jam mengajar, murid yang diajar, dan absensi per guru.';

  @override
  String get adminReportsClassesHeld => 'Kelas terlaksana';

  @override
  String get adminReportsHours => 'Jam';

  @override
  String get adminReportsTermAlertsTitle => 'Peringatan sisa periode';

  @override
  String get adminReportsTermAlertsDesc =>
      'Siapa yang perlu dihubungi: sisa 2 sesi atau kurang, kedaluwarsa dalam 7 hari, sudah kedaluwarsa.';

  @override
  String get adminReportsLowBalance => 'Sisa sedikit';

  @override
  String get adminReportsExpiring => 'Segera kedaluwarsa';

  @override
  String get adminReportsRevenueTitle => 'Pemasukan per bulan';

  @override
  String get adminReportsRevenueDesc =>
      'Tagihan lunas per item, ditambah semua tagihan belum lunas dan berapa lama terlambatnya.';

  @override
  String get adminReportsThisMonth => 'Bulan ini';

  @override
  String get adminReportsUnpaid => 'Belum lunas';

  @override
  String get adminReportsUserRosterTitle => 'Daftar pengguna';

  @override
  String get adminReportsUserRosterDesc =>
      'Semua akun dengan peran, tanggal bergabung, dan status.';

  @override
  String get adminReportsUsers => 'Pengguna';

  @override
  String get adminReportsGrowthTitle => 'Pendaftaran & pertumbuhan';

  @override
  String get adminReportsGrowthDesc =>
      'Murid baru per bulan dan sebaran level HSK saat ini.';

  @override
  String get adminReportsLastSixMonths => '6 bulan terakhir';

  @override
  String get adminReportsVouchersTitle => 'Voucher & paket';

  @override
  String get adminReportsVouchersDesc =>
      'Semua paket sesi beserta kode dan sisa sesinya.';

  @override
  String get adminReportsPackages => 'Paket';

  @override
  String get adminReportsIssuedThisMonth => 'Diterbitkan bulan ini';

  @override
  String get adminReportsWorksheetInventoryTitle => 'Inventaris lembar soal';

  @override
  String get adminReportsWorksheetInventoryDesc =>
      'Lembar soal latihan per level HSK dan bagian keterampilan.';

  @override
  String get adminReportsWorksheets => 'Lembar soal';

  @override
  String get adminReportsDraft => 'Draf';

  @override
  String get adminPriceTitle => 'Daftar harga';

  @override
  String get adminPriceSaved => 'Daftar harga disimpan';

  @override
  String adminPriceSaveFailed(String error) {
    return 'Tidak dapat menyimpan: $error';
  }

  @override
  String adminPriceRemoveTitle(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get adminPriceRemoveBody =>
      'Tagihan yang sudah dibuat tetap memakai harganya. Tagihan baru tidak bisa lagi memilih item ini.';

  @override
  String get adminPriceVoucherValidity => 'Masa berlaku voucher';

  @override
  String get adminPriceValidityDaysLabel =>
      'Jumlah hari voucher berlaku setelah dibayar';

  @override
  String get adminPriceValidityHelper => 'Brosur: 2 bulan = 60 hari';

  @override
  String get adminPriceSave => 'Simpan';

  @override
  String get adminPriceIntro =>
      'Semua hal yang bisa dibayar. Buat tagihan memilih satu baris dari daftar ini dan server menagih persis harga ini. Baris yang memberi sesi kelas menjadi voucher setelah dibayar.';

  @override
  String get adminPriceItems => 'Item';

  @override
  String get adminPriceAddItem => 'Tambah item';

  @override
  String adminPriceGives(String what) {
    return 'Memberi $what';
  }

  @override
  String get adminPriceEdit => 'Ubah';

  @override
  String adminPriceValiditySummary(int days, String months) {
    return '$days hari sejak pembayaran ($months bulan)';
  }

  @override
  String adminPriceLastSaved(String date) {
    return 'Terakhir disimpan $date';
  }

  @override
  String get adminPriceNewItem => 'Item baru';

  @override
  String get adminPriceEditItem => 'Ubah item';

  @override
  String get adminPriceName => 'Nama';

  @override
  String get adminPriceNameHint => 'mis. 8 sesi kelas';

  @override
  String get adminPriceNameRequired => 'Masukkan nama';

  @override
  String get adminPricePriceLabel => 'Harga (Rp, bilangan bulat)';

  @override
  String get adminPricePriceInvalid => 'Masukkan harga di atas 0';

  @override
  String get adminPriceWhatItGives => 'Yang diberikan';

  @override
  String get adminPriceSessionsLabel => 'Jumlah sesi kelas';

  @override
  String get adminPriceSessionsInvalid => 'Masukkan 1 atau lebih';

  @override
  String get adminPriceKindSessions => 'Sesi kelas';

  @override
  String get adminPriceKindBook => 'Buku / materi';

  @override
  String get adminPriceKindRegistration => 'Pendaftaran';

  @override
  String get adminPriceKindOther => 'Lainnya';

  @override
  String get orgSettingsTitle => 'Pengaturan';

  @override
  String get orgSettingsFeatures => 'Fitur';

  @override
  String get orgSettingsPaymentsHint =>
      'Tampilkan tagihan dan tampilan bayar/checkout untuk murid dan admin. Matikan untuk menyembunyikan penagihan sepenuhnya.';

  @override
  String get orgSettingsEvalOpen => 'Formulir evaluasi dibuka';

  @override
  String get orgSettingsEvalOpenHint =>
      'Izinkan guru membuat atau mengubah evaluasi semester. Tutup di antara periode untuk membekukan formulir.';

  @override
  String get orgSettingsTeacherReschedule => 'Guru boleh mengubah jadwal';

  @override
  String get orgSettingsTeacherRescheduleHint =>
      'Izinkan guru mengubah sesi kelasnya sendiri. Matikan agar hanya admin yang bisa mengubah jadwal.';

  @override
  String get orgSettingsAccounts => 'Akun';

  @override
  String get orgSettingsRequireEmailVerification => 'Wajibkan verifikasi email';

  @override
  String get orgSettingsRequireEmailVerificationHint =>
      'Preferensi tersimpan untuk alur pendaftaran mendatang. Belum diberlakukan otomatis.';

  @override
  String get orgSettingsAutoPasswords => 'Buat kata sandi staf otomatis';

  @override
  String get orgSettingsAutoPasswordsHint =>
      'Preferensi tersimpan untuk pembuatan akun staf mendatang. Belum diberlakukan otomatis.';

  @override
  String get orgSettingsPrices => 'Harga';

  @override
  String get orgSettingsPriceListHint =>
      'Hal yang bisa dibayar: sesi, buku, pendaftaran. Tagihan memilih dari daftar ini.';

  @override
  String get orgSettingsAdministration => 'Administrasi';

  @override
  String get orgSettingsAuditLogsHint =>
      'Peristiwa keuangan dan izin, terbaru di atas.';

  @override
  String get orgSettingsMaterialsHint =>
      'Berkas bersama untuk murid dan orang tua.';

  @override
  String orgSettingsLastUpdated(String date) {
    return 'Terakhir diperbarui $date';
  }

  @override
  String get auditLogTitle => 'Log audit';

  @override
  String get auditLogEmptyTitle => 'Belum ada aktivitas';

  @override
  String get auditLogEmptySubtitle =>
      'Pergerakan uang dan perubahan izin akan tercatat di sini secara otomatis.';

  @override
  String get cohortNoStudentsTitle => 'Belum ada murid';

  @override
  String get cohortNoStudentsSubtitle =>
      'Murid akan muncul di sini setelah mendaftar di aplikasi.';

  @override
  String get cohortNoMatch =>
      'Tidak ada murid yang cocok dengan pencarian ini.';

  @override
  String get cohortLevel => 'Level';

  @override
  String get cohortThisTerm => 'Periode ini';

  @override
  String get cohortHomework => 'PR';

  @override
  String get cohortQuizAvg => 'Rata-rata kuis';

  @override
  String get cohortSessionsLeft => 'Sisa sesi';

  @override
  String get cohortLastActive => 'Terakhir aktif';

  @override
  String cohortStudentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count murid',
    );
    return '$_temp0';
  }

  @override
  String cohortShownCount(int count) {
    return '$count ditampilkan';
  }

  @override
  String cohortNeedAttentionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count perlu perhatian',
    );
    return '$_temp0';
  }

  @override
  String get cohortSearchStudents => 'Cari murid';

  @override
  String get cohortAllLevels => 'Semua level';

  @override
  String cohortQuizPercent(int score) {
    return 'Kuis $score%';
  }

  @override
  String get cohortCentreStatistics => 'Statistik pusat belajar';

  @override
  String get cohortHomeworkDone => 'PR selesai';

  @override
  String get cohortOverdue => 'Terlambat';

  @override
  String get cohortAvgQuiz => 'Rata-rata kuis';

  @override
  String get cohortAvgPractice => 'Rata-rata latihan';

  @override
  String get cohortClassesThisWeek => 'Kelas minggu ini';

  @override
  String get cohortNeedAttention => 'Perlu perhatian';

  @override
  String get cohortStudents => 'Murid';

  @override
  String get cohortRosterCsvDownloaded => 'CSV daftar murid diunduh';

  @override
  String get cohortRosterCsvCopied => 'CSV daftar murid disalin ke papan klip';

  @override
  String get cohortReportsSubtitle =>
      'Ekspor ringkasan pusat belajar dan inventaris lembar soal untuk arsip Anda.';

  @override
  String get cohortCentreSummary => 'Ringkasan pusat belajar';

  @override
  String get cohortCentreSummaryDesc =>
      'Penyelesaian PR, rata-rata kuis, sisa sesi, dan murid yang perlu perhatian.';

  @override
  String cohortStudentsTracked(int count) {
    return 'Murid terpantau: $count';
  }

  @override
  String cohortWorksheetsPublished(int count) {
    return 'Lembar soal terbit: $count';
  }

  @override
  String get cohortStudentRoster => 'Daftar murid';

  @override
  String get cohortStudentRosterDesc =>
      'Daftar lengkap murid dengan kemajuan, PR, dan sisa sesi. Ekspor spreadsheet.';

  @override
  String cohortStudentsPreview(int count) {
    return 'Murid: $count';
  }

  @override
  String get cohortColumnsPreview => 'Kolom: level, PR, kuis, sesi';

  @override
  String get cohortWorksheetInventoryDesc =>
      'Semua lembar soal latihan yang dibuat, dikelompokkan per level HSK dan bagian keterampilan (Membaca, Mendengarkan, dll.).';

  @override
  String cohortTotalWorksheets(int count) {
    return 'Total lembar soal: $count';
  }

  @override
  String get teacherActivityThisWeek => 'Aktivitas minggu ini';

  @override
  String get teacherActivityThisWeekSubtitle =>
      'Pelajaran selesai dan pengumpulan latihan';

  @override
  String get teacherActivityHomeworkOverview => 'Ringkasan PR';

  @override
  String get teacherActivityQuickView => 'Lihat cepat';

  @override
  String get teacherActivityNoHomeworkAssign =>
      'Belum ada PR yang ditugaskan. Tugaskan latihan dari tab Latihan.';

  @override
  String teacherActivityToDo(int count) {
    return '$count belum dikerjakan';
  }

  @override
  String teacherActivityOverdueCount(int count) {
    return '$count terlambat';
  }

  @override
  String teacherActivityDoneCount(int count) {
    return '$count selesai';
  }

  @override
  String teacherActivityAssignmentsCompleted(int done, int total) {
    return '$done/$total tugas selesai';
  }

  @override
  String get teacherActivityNoHomework => 'Belum ada PR yang ditugaskan.';

  @override
  String teacherActivityCompletedOf(int done, int total) {
    return '$done/$total selesai';
  }

  @override
  String get teacherActivityPending => 'Menunggu';

  @override
  String get teacherActivityClose => 'Tutup';

  @override
  String get teacherActivityRecent => 'Aktivitas terbaru';

  @override
  String get teacherActivityNoRecent =>
      'Tidak ada aktivitas terbaru untuk filter ini.';

  @override
  String get teacherActivityFilterAll => 'Semua';

  @override
  String get teacherActivityJustNow => 'Baru saja';

  @override
  String teacherActivityMinutesAgo(int count) {
    return '$count mnt lalu';
  }

  @override
  String teacherActivityHoursAgo(int count) {
    return '$count jam lalu';
  }

  @override
  String teacherActivityDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String get adminShellNavDashboard => 'Dasbor';

  @override
  String get adminShellNavUsers => 'Pengguna';

  @override
  String get adminShellNavExercises => 'Latihan';

  @override
  String get adminShellNavQuestionBank => 'Bank soal';

  @override
  String get adminShellNavClasses => 'Kelas';

  @override
  String get adminShellNavVouchers => 'Voucher';

  @override
  String get adminShellNavReports => 'Laporan';

  @override
  String get adminShellNavAccount => 'Akun';

  @override
  String get adminShellScanWorksheet => 'Pindai lembar soal';

  @override
  String get adminShellNewClass => 'Kelas baru';

  @override
  String get adminProfileSubtitle => 'Administrator platform';

  @override
  String get adminProfileIntro =>
      'Kelola pengguna, voucher, laporan, dan notifikasi dari tab admin. Alur mengajar menggunakan peran Guru.';

  @override
  String get adminProfileCentreSettings => 'Pengaturan pusat belajar';

  @override
  String get adminProfileCentreSettingsHint =>
      'Pembayaran, evaluasi, materi, log audit.';

  @override
  String get adminProfilePersonalSubtitle =>
      'Nama Indonesia dan Mandarin serta kontak WhatsApp.';

  @override
  String get profileWidgetPhotoUpdated => 'Foto profil diperbarui';

  @override
  String get profileWidgetEmailHelper =>
      'Hubungi admin untuk mengganti email Anda';

  @override
  String get profileWidgetParentHint =>
      'Dipakai staf untuk menghubungi keluarga bila diperlukan.';

  @override
  String get profileWidgetAccountTitle => 'Akun';

  @override
  String get profileWidgetMemberSince => 'Anggota sejak';

  @override
  String get profileWidgetStatus => 'Status';

  @override
  String get profileWidgetInactive => 'Nonaktif';

  @override
  String get profileWidgetSaveChanges => 'Simpan perubahan';

  @override
  String get linkCardCopied => 'Kode tautan disalin';

  @override
  String get linkCardTitle => 'Penautan murid';

  @override
  String get linkCardBody =>
      'Bagikan kode ini saat murid mendaftar. Kode diperbarui setiap 15 menit.';

  @override
  String get linkCardCopyTooltip => 'Salin kode';

  @override
  String linkCardRefreshesIn(String time) {
    return 'Diperbarui dalam $time';
  }

  @override
  String get termDatesTitle => 'Tanggal periode';

  @override
  String get termStartDate => 'Tanggal mulai';

  @override
  String get termDeadlineDate => 'Tanggal batas akhir';

  @override
  String get termSave => 'Simpan';

  @override
  String get termDelete => 'Hapus';

  @override
  String termMeetingsLeftTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa pertemuan kelas periode ini',
    );
    return '$_temp0';
  }

  @override
  String get termNoPaidSessions =>
      'Sesi berbayar sudah habis. Minta guru Anda menambahkan periode baru.';

  @override
  String termUsedRemaining(int used, int remaining, int total) {
    return '$used terpakai · sisa $remaining dari $total';
  }

  @override
  String termValidUntil(String date) {
    return 'Berlaku sampai $date';
  }

  @override
  String get termNoActiveInRange =>
      'Tidak ada periode aktif pada rentang tanggal saat ini.';

  @override
  String termActivePackages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paket aktif',
    );
    return '$_temp0';
  }

  @override
  String get termChargedOnConclude =>
      'Satu sesi dipotong setiap kali guru Anda menutup kelas.';

  @override
  String termSessionsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count sesi kelas',
    );
    return '$_temp0';
  }

  @override
  String get termNoActiveInRangeShort =>
      'Tidak ada periode aktif dalam rentang tanggal';

  @override
  String get termDeductOnConclude => 'Sesi dipotong saat guru menutup kelas.';

  @override
  String termRowLabel(int sessions, String start, String end) {
    return '$sessions sesi · $start – $end';
  }

  @override
  String get termNoPaymentRecorded => 'Belum ada pembayaran tercatat';

  @override
  String termPaidLine(String amount, String method) {
    return 'Lunas $amount ($method)';
  }

  @override
  String termPendingPayment(String amount) {
    return 'Menunggu pembayaran · $amount';
  }

  @override
  String get termUpdated => 'Periode diperbarui';

  @override
  String get termDeleteTitle => 'Hapus periode ini?';

  @override
  String termDeleteBody(int sessions, int remaining) {
    return 'Hapus periode $sessions sesi (sisa $remaining)? Pemotongan kelas sebelumnya yang terkait periode ini tetap tersimpan di riwayat. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get termDeleted => 'Periode dihapus';

  @override
  String get termNoPackages =>
      'Belum ada paket periode berbayar. Tambahkan periode 8 atau 16 sesi saat murid membayar.';

  @override
  String termPackageTitle(int sessions) {
    return 'Periode $sessions sesi';
  }

  @override
  String get termEdit => 'Ubah periode';

  @override
  String get termDeleteTooltip => 'Hapus periode';

  @override
  String termStartDeadline(String start, String deadline) {
    return 'Mulai: $start · Batas akhir: $deadline';
  }

  @override
  String get termOutsideDates => 'Hari ini di luar tanggal periode';

  @override
  String termRemainingOf(int remaining, int total) {
    return 'Sisa $remaining / $total';
  }

  @override
  String termClassesAttended(int count) {
    return 'Kelas yang dihadiri ($count)';
  }

  @override
  String get termNoClassesCharged =>
      'Belum ada kelas yang dipotong dari periode ini.';

  @override
  String get termNoConcludedVisits => 'Belum ada kunjungan kelas yang ditutup.';

  @override
  String get termClassFallback => 'Kelas';

  @override
  String get termMinusOneSession => '−1 sesi';

  @override
  String termRemainingRangeError(int max) {
    return 'Masukkan sisa sesi antara 0 dan $max';
  }

  @override
  String termEditTitle(int sessions) {
    return 'Ubah periode $sessions sesi';
  }

  @override
  String get termSessionsRemaining => 'Sisa sesi';

  @override
  String termOutOfPackage(int total) {
    return 'Dari $total sesi dalam paket ini';
  }

  @override
  String get termAddTitle => 'Tambah periode berbayar';

  @override
  String get termAddBody =>
      'Pilih jumlah sesi kelas yang dibayar murid. Sesi dipotong setiap kali Anda menutup kelas.';

  @override
  String termSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesi',
    );
    return '$_temp0';
  }

  @override
  String termPaymentNoteRecorded(String amount) {
    return 'Pembayaran menunggu sebesar $amount dicatat untuk admin.';
  }

  @override
  String termPaymentNoteNoItem(int count) {
    return 'Tidak ada item daftar harga untuk $count sesi: admin harus menambahkan pembayaran secara manual.';
  }

  @override
  String termPaymentNoteFailed(String error) {
    return 'Pembayaran tidak dapat dicatat ($error); admin harus menambahkannya di Pembayaran.';
  }

  @override
  String termAdded(int sessions) {
    return 'Periode $sessions sesi ditambahkan.';
  }

  @override
  String get termAddButton => 'Tambah periode';

  @override
  String get termPaidTermsTitle => 'Periode kelas berbayar';

  @override
  String get termPackagesTitle => 'Paket periode';

  @override
  String termOtherVisits(int count) {
    return 'Kunjungan lain yang ditutup ($count)';
  }

  @override
  String get adminUsersRoleAdmin => 'Admin';

  @override
  String get adminUsersRoleTeacher => 'Guru';

  @override
  String get adminUsersRoleStudent => 'Murid';

  @override
  String get adminUsersRoleParent => 'Orang tua';

  @override
  String get adminUsersAllRoles => 'Semua peran';

  @override
  String get adminUsersAllStatus => 'Semua status';

  @override
  String get adminUsersColName => 'Nama';

  @override
  String get adminUsersColRole => 'Peran';

  @override
  String get adminUsersColHsk => 'HSK';

  @override
  String get adminUsersColWhatsapp => 'WhatsApp';

  @override
  String get adminUsersColParentPhone => 'Telepon orang tua';

  @override
  String get adminUsersColActions => 'Aksi';

  @override
  String adminUsersActivated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count akun diaktifkan.',
    );
    return '$_temp0';
  }

  @override
  String adminUsersDeactivated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count akun dinonaktifkan.',
    );
    return '$_temp0';
  }

  @override
  String adminUsersHskDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Level HSK untuk $count murid',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersApply => 'Terapkan';

  @override
  String adminUsersLevelSet(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count murid diatur ke $level.',
    );
    return '$_temp0';
  }

  @override
  String get adminUsersActivate => 'Aktifkan';

  @override
  String get adminUsersDeactivate => 'Nonaktifkan';

  @override
  String get adminUsersSetHskLevel => 'Atur level HSK';

  @override
  String adminUsersSetHskLevelCount(int count) {
    return 'Atur level HSK ($count)';
  }

  @override
  String get adminUsersNoChildLinked => 'Belum ada anak yang terhubung';

  @override
  String adminUsersChildrenMore(String names, int more) {
    return 'Anak: $names +$more';
  }

  @override
  String adminUsersChildren(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Anak: $names',
    );
    return '$_temp0';
  }

  @override
  String adminUsersParentOf(String name) {
    return 'Orang tua: $name';
  }

  @override
  String adminUsersDeleteTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String adminUsersDeleteBody(String email) {
    return '$email tidak akan bisa masuk lagi dan profilnya dihapus. Tindakan ini tidak dapat dibatalkan. Hasil latihan, tagihan, dan absensi tetap tersimpan sebagai catatan pusat belajar.';
  }

  @override
  String get adminUsersDeleteAccount => 'Hapus akun';

  @override
  String adminUsersDeleted(String email) {
    return '$email dihapus.';
  }

  @override
  String get adminUsersDeleteFailed => 'Akun tidak dapat dihapus.';

  @override
  String adminUsersLoadFailed(String error) {
    return 'Pengguna tidak dapat dimuat: $error';
  }

  @override
  String get adminUsersEmpty =>
      'Tidak ada pengguna. Jalankan scripts/seed_test_accounts.sh atau pastikan akun admin Anda memiliki role: admin di Firestore.';

  @override
  String get adminUsersNoMatch =>
      'Tidak ada pengguna yang cocok dengan pencarian Anda.';

  @override
  String get adminUsersNewUser => 'Pengguna baru';

  @override
  String get adminUsersSearchHint => 'Cari pengguna…';

  @override
  String get adminUsersSortBy => 'Urutkan';

  @override
  String get adminUsersEditProfile => 'Ubah profil';

  @override
  String get adminUsersEdit => 'Ubah';

  @override
  String get adminUserFormTitle => 'Daftarkan pengguna baru';

  @override
  String get adminUserFormHeading => 'Buat akun Murid atau Guru';

  @override
  String get adminUserFormIntro =>
      'Pengguna baru dapat masuk dengan email dan kata sandi yang Anda tentukan. Anda tetap masuk sebagai admin.';

  @override
  String get adminUserFormRoleParentShort => 'Ortu';

  @override
  String get adminUserFormSelectChild =>
      'Pilih minimal satu anak untuk orang tua ini.';

  @override
  String adminUserFormCreated(String role, String name) {
    return 'Akun $role dibuat untuk $name';
  }

  @override
  String get adminUserFormErrorEmailInUse => 'Email ini sudah terdaftar.';

  @override
  String adminUserFormSubmit(String role) {
    return 'Buat akun $role';
  }

  @override
  String get adminUserFormChildHint =>
      'Pilih murid yang dapat diikuti orang tua ini (hanya dapat dilihat).';

  @override
  String get adminUserFormNoStudents => 'Belum ada murid untuk ditautkan.';

  @override
  String get adminUserFormSearchHint => 'Cari nama, email, atau level HSK';

  @override
  String adminUserFormSelectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get adminUserFormNoMatch =>
      'Tidak ada murid yang cocok dengan pencarian ini.';

  @override
  String get adminUserFormNotFound => 'Pengguna tidak ditemukan';

  @override
  String adminUserFormUpdated(String name) {
    return '$name diperbarui';
  }

  @override
  String get adminUserFormEditTitle => 'Ubah pengguna';

  @override
  String adminUserFormEditRole(String role) {
    return 'Ubah $role';
  }

  @override
  String get adminUserFormProfileDetails => 'Detail profil';

  @override
  String get adminUserFormHskHint =>
      'Ubah level HSK untuk menentukan latihan yang dapat diakses murid ini.';

  @override
  String get adminInvoicesStatusPending => 'Menunggu';

  @override
  String get adminInvoicesStatusPaid => 'Lunas';

  @override
  String get adminInvoicesStatusFailed => 'Gagal';

  @override
  String get adminInvoicesMethodOnline => 'Online';

  @override
  String get adminInvoicesMethodCash => 'Tunai';

  @override
  String get adminInvoicesMethodTransfer => 'Transfer';

  @override
  String get adminInvoicesMethodAtCentre => 'Di pusat belajar';

  @override
  String get adminInvoicesMethodManual => 'Manual';

  @override
  String get adminInvoicesItemBook => 'Materi & buku HSK';

  @override
  String get adminInvoicesGivesBook => 'buku / materi, tanpa sesi';

  @override
  String get adminInvoicesGivesRegistration => 'pendaftaran, tanpa sesi';

  @override
  String get adminInvoicesGivesNone => 'tanpa sesi';

  @override
  String get adminInvoicesColInvoice => 'Tagihan';

  @override
  String get adminInvoicesColInvoiceNumber => 'No. tagihan';

  @override
  String get adminInvoicesColItem => 'Item';

  @override
  String get adminInvoicesColAmount => 'Jumlah';

  @override
  String get adminInvoicesColMethod => 'Metode';

  @override
  String get adminInvoicesColDue => 'Jatuh tempo';

  @override
  String get adminInvoicesColPaidOn => 'Dibayar pada';

  @override
  String get adminInvoicesColCreated => 'Dibuat';

  @override
  String get adminInvoicesDisabledSubtitle =>
      'Aktifkan pembayaran di Pengaturan untuk membuat tagihan dan menagih murid untuk paket sesi.';

  @override
  String get adminInvoicesPriceList => 'Daftar harga';

  @override
  String get adminInvoicesCreate => 'Buat tagihan';

  @override
  String get adminInvoicesCodeOnlyBanner =>
      'Pembayaran berjalan dalam mode kode saja: tambahkan kunci Midtrans dan deploy Cloud Functions (Blaze) untuk mengaktifkan pembayaran langsung.';

  @override
  String get adminInvoicesEmptyTitle => 'Belum ada tagihan';

  @override
  String get adminInvoicesEmptySubtitle =>
      'Ketuk \"Buat tagihan\" untuk menagih murid untuk paket sesi atau buku HSK.';

  @override
  String get adminInvoicesOverdue => 'Terlambat';

  @override
  String get adminInvoicesMarkPaidMenu => 'Tandai lunas (tunai / transfer)';

  @override
  String get adminInvoicesDeletePending => 'Hapus tagihan menunggu';

  @override
  String get adminInvoicesStudentFallback => 'murid';

  @override
  String adminInvoicesRecorded(String name, String item, String method) {
    return 'Tercatat: $name membayar $item secara $method.';
  }

  @override
  String get adminInvoicesDeleteTitle => 'Hapus tagihan menunggu ini?';

  @override
  String adminInvoicesDeleteBody(String number, String item, String name) {
    return '$number · $item untuk $name. Voucher yang terkait akan kembali menampilkan \"Belum ada pembayaran\".';
  }

  @override
  String adminInvoicesDeleteFailed(String error) {
    return 'Tidak dapat menghapus: $error';
  }

  @override
  String adminInvoicesCardInvoice(String number) {
    return 'Tagihan $number';
  }

  @override
  String adminInvoicesCardDue(String date) {
    return 'jatuh tempo $date';
  }

  @override
  String get adminInvoicesPayNow => 'Bayar sekarang';

  @override
  String get adminInvoicesPayAtCentre =>
      'Bayar di pusat belajar secara tunai atau transfer bank. Admin akan menandainya lunas dan sesi Anda ditambahkan.';

  @override
  String get adminInvoicesMarkPaid => 'Tandai lunas';

  @override
  String get adminInvoicesItemFromPriceList => 'Item (dari Daftar harga)';

  @override
  String adminInvoicesGives(String gives) {
    return 'Memberi $gives.';
  }

  @override
  String get adminInvoicesVoucherOpened =>
      'Voucher dibuka saat tagihan ini lunas.';

  @override
  String get adminInvoicesCashTransfer => 'Tunai / transfer';

  @override
  String get adminInvoicesOnlineLink => 'Tautan online';

  @override
  String get adminInvoicesOnlineHint =>
      'Murid menerima tautan pembayaran Midtrans; sesi ditambahkan otomatis setelah mereka membayar.';

  @override
  String get adminInvoicesManualHint =>
      'Dicatat sebagai menunggu. Saat uang diterima, buka menu tagihan dan pilih Tandai lunas.';

  @override
  String get adminInvoicesOnlineNeedsKeys =>
      'Pembayaran online memerlukan kunci Midtrans dan Cloud Functions yang sudah di-deploy.';

  @override
  String get adminInvoicesDueDate => 'Jatuh tempo';

  @override
  String get adminInvoicesChange => 'Ubah';

  @override
  String adminInvoicesCreateWithPrice(String price) {
    return 'Buat tagihan · $price';
  }

  @override
  String get adminInvoicesChooseStudent => 'Pilih murid.';

  @override
  String get adminInvoicesChooseItem => 'Pilih item dari Daftar harga.';

  @override
  String adminInvoicesCreatedOnline(String name) {
    return 'Tagihan dibuat untuk $name';
  }

  @override
  String adminInvoicesCreatedManual(String name) {
    return 'Tagihan dibuat untuk $name · menunggu sampai Anda menandainya lunas';
  }

  @override
  String get adminInvoicesBankTransfer => 'Transfer bank';

  @override
  String get adminInvoicesNoteOptional => 'Catatan (opsional)';

  @override
  String get adminInvoicesNoteHint => 'mis. transfer BCA 27 Okt';

  @override
  String get adminInvoicesLinkedVoucherPaid =>
      'Voucher yang terkait ditandai lunas.';

  @override
  String adminInvoicesVoucherOpenedFor(int sessions) {
    return 'Voucher $sessions sesi dibuka untuk murid.';
  }

  @override
  String get adminInvoicesNoSessionsAdded =>
      'Tidak ada sesi yang ditambahkan untuk item ini.';

  @override
  String get adminInvoicesConfirmPayment => 'Konfirmasi pembayaran';

  @override
  String get adminVouchersNewVoucher => 'Voucher baru';

  @override
  String get adminVouchersPendingPayment => 'Menunggu pembayaran';

  @override
  String get adminVouchersNoPayment => 'Belum ada pembayaran';

  @override
  String get adminVouchersInvoiceMissing => 'Tagihan tidak ditemukan';

  @override
  String get adminVouchersStatusActive => 'aktif';

  @override
  String get adminVouchersStatusLow => 'hampir habis';

  @override
  String get adminVouchersStatusDepleted => 'habis';

  @override
  String get adminVouchersColVoucher => 'Voucher';

  @override
  String get adminVouchersColSessions => 'Sesi';

  @override
  String get adminVouchersColUsed => 'Terpakai';

  @override
  String get adminVouchersColRemaining => 'Sisa';

  @override
  String get adminVouchersColStart => 'Mulai';

  @override
  String get adminVouchersColDeadline => 'Batas akhir';

  @override
  String get adminVouchersColPayment => 'Pembayaran';

  @override
  String get adminVouchersColPackage => 'Paket';

  @override
  String get adminVouchersVoucherCode => 'Kode voucher';

  @override
  String get adminVouchersUnknownStudent => 'Murid tidak dikenal';

  @override
  String get adminVouchersEdit => 'Ubah voucher';

  @override
  String get adminVouchersDelete => 'Hapus voucher';

  @override
  String get adminVouchersThisVoucher => 'voucher ini';

  @override
  String get adminVouchersDeleteTitle => 'Hapus voucher?';

  @override
  String adminVouchersDeleteBody(String code, String name) {
    return 'Hapus $code milik $name? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String adminVouchersDeleted(String code) {
    return '$code dihapus';
  }

  @override
  String get adminVouchersIntro =>
      'Voucher adalah periode berbayar murid: 8 atau 16 sesi kelas dengan tanggal mulai dan batas akhir, selalu terkait dengan pembayaran (tab Pembayaran). \"Menunggu pembayaran\" berarti tagihannya belum lunas; \"Belum ada pembayaran\" adalah voucher lama yang dibuat sebelum pembayaran ditautkan. Satu sesi dipotong setiap kali kelas ditutup.';

  @override
  String get adminVouchersSearchHint => 'Cari kode atau murid…';

  @override
  String get adminVouchersFilterAll => 'Semua';

  @override
  String get adminVouchersEmptyTitle => 'Belum ada voucher';

  @override
  String get adminVouchersNoMatch =>
      'Tidak ada voucher yang cocok dengan pencarian Anda';

  @override
  String get adminVouchersEmptySubtitle =>
      'Buat voucher untuk menerbitkan paket sesi dengan kode yang dapat dilacak seperti 2026_07_001.';

  @override
  String adminVouchersCardSessions(int sessions, int remaining) {
    return '$sessions sesi · sisa $remaining';
  }

  @override
  String get adminVoucherFormAddPriceItem =>
      'Tambahkan item sesi ke Daftar harga terlebih dahulu.';

  @override
  String get adminVoucherFormRecordPaymentFor => 'Catat pembayaran untuk';

  @override
  String adminVoucherFormRecordFailed(String error) {
    return 'Pembayaran tidak dapat dicatat: $error';
  }

  @override
  String get adminVoucherFormNotFound => 'Voucher tidak ditemukan';

  @override
  String get adminVoucherFormChoosePayment =>
      'Pilih pembayaran untuk voucher ini, atau catat pembayaran baru.';

  @override
  String get adminVoucherFormUpdated => 'Voucher diperbarui';

  @override
  String get adminVoucherFormCreated => 'Voucher dibuat';

  @override
  String get adminVoucherFormIntro =>
      'Setiap voucher terkait dengan satu pembayaran. Pilih murid, lalu tagihan yang membayarnya (atau catat pembayaran tunai / transfer di sini). Kode unik dibuat otomatis (mis. 2026_07_001).';

  @override
  String get adminVoucherFormNoHsk => 'Tanpa HSK';

  @override
  String get adminVoucherFormSelectStudent => 'Pilih murid';

  @override
  String get adminVoucherFormPackageSize => 'Ukuran paket';

  @override
  String get adminVoucherFormPackageSizeFromPayment =>
      'Ukuran paket (dari pembayaran)';

  @override
  String adminVoucherFormOfTotal(int total) {
    return 'Dari total $total dalam paket ini';
  }

  @override
  String get adminVoucherFormEnterNumber => 'Masukkan angka';

  @override
  String adminVoucherFormRange(int max) {
    return 'Harus antara 0 dan $max';
  }

  @override
  String adminVoucherFormStart(String date) {
    return 'Mulai: $date';
  }

  @override
  String adminVoucherFormDeadline(String date) {
    return 'Batas akhir: $date';
  }

  @override
  String get adminVoucherFormNotesOptional => 'Catatan (opsional)';

  @override
  String get adminVoucherFormCreate => 'Buat voucher';

  @override
  String get adminVoucherFormPaymentHelper =>
      'Tagihan sesi yang lunas atau menunggu dan belum memiliki voucher';

  @override
  String get adminVoucherFormChoosePaymentShort =>
      'Pilih pembayaran atau catat yang baru';

  @override
  String get adminVoucherFormRecordPayment =>
      'Catat pembayaran tunai / transfer';

  @override
  String get adminVoucherFormNoPaymentOlder =>
      'Belum ada pembayaran tercatat (voucher lama)';

  @override
  String get teacherShellNavDashboard => 'Dasbor';

  @override
  String get teacherShellNavStudents => 'Murid';

  @override
  String get teacherShellNavExercises => 'Latihan';

  @override
  String get teacherShellNavClasses => 'Kelas';

  @override
  String get teacherShellNavGrades => 'Nilai';

  @override
  String get teacherShellNewClass => 'Kelas baru';

  @override
  String get teacherProfileRoleSubtitle => 'Guru · Pengajar pusat belajar';

  @override
  String get teacherProfilePersonalSubtitle =>
      'Nama Indonesia dan Mandarin serta kontak WhatsApp.';

  @override
  String get teacherDashNoDemoTitle => 'Belum ada data demo';

  @override
  String get teacherDashNoDemoSubtitle =>
      'Jalankan scripts/seed_test_accounts.sh lalu python3 scripts/seed_report_demo_data.py';

  @override
  String get teacherDashGradebook => 'Buku nilai';

  @override
  String teacherDashPendingCount(int count) {
    return '$count menunggu';
  }

  @override
  String get teacherDashActiveThisWeek => 'Aktif minggu ini';

  @override
  String get teacherDashNeedsAttention => 'Perlu perhatian';

  @override
  String get teacherDashAllCaughtUp => 'Semua sudah ditangani';

  @override
  String get teacherDashNoFollowUp =>
      'Tidak ada murid yang perlu ditindaklanjuti saat ini.';

  @override
  String get teacherDashRecentStudents => 'Murid terbaru';

  @override
  String get teacherDashNoStudentsTitle => 'Belum ada murid';

  @override
  String get teacherDashNoStudentsSubtitle =>
      'Murid akan muncul di sini setelah mendaftar.';

  @override
  String get teacherDashNoCompletedHomeworkTitle =>
      'Belum ada tugas yang selesai';

  @override
  String get teacherDashNoCompletedHomeworkSubtitle =>
      'Latihan yang selesai akan muncul di sini setelah murid mengirim skor.';

  @override
  String get teacherDashNoOverdueTitle => 'Tidak ada latihan yang terlambat';

  @override
  String get teacherDashNoOverdueSubtitle =>
      'Semua tugas yang diberikan masih sesuai jadwal.';

  @override
  String get teacherDashNoQuizScoresTitle => 'Belum ada skor kuis';

  @override
  String get teacherDashNoQuizScoresSubtitle =>
      'Rata-rata kuis muncul setelah murid menyelesaikan kuis pelajaran.';

  @override
  String get teacherDashNoPracticeScoresTitle => 'Belum ada skor latihan';

  @override
  String get teacherDashNoPracticeScoresSubtitle =>
      'Rata-rata latihan muncul setelah murid menyelesaikan latihan yang ditugaskan.';

  @override
  String get teacherDashNoHomeworkTitle => 'Belum ada tugas yang diberikan';

  @override
  String get teacherDashNoHomeworkSubtitle =>
      'Tugaskan latihan dari tab Latihan untuk memantau penyelesaiannya di sini.';

  @override
  String teacherDashExerciseCountLevel(int count, String level) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count latihan',
    );
    return '$_temp0 · $level';
  }

  @override
  String get teacherDashNoStudentsToShowTitle =>
      'Tidak ada murid untuk ditampilkan';

  @override
  String get teacherDashNoStudentsToShowSubtitle =>
      'Coba lagi nanti atau periksa daftar murid Anda.';

  @override
  String teacherDashHomeworkDone(int count) {
    return '$count selesai';
  }

  @override
  String teacherDashHomeworkToDo(int count) {
    return '$count belum dikerjakan';
  }

  @override
  String teacherDashHomeworkOverdue(int count) {
    return '$count terlambat';
  }

  @override
  String get teacherDashOverdue => 'Terlambat';

  @override
  String get teacherDashPending => 'Menunggu';

  @override
  String get teacherDashNoSessionPackagesTitle => 'Belum ada paket sesi';

  @override
  String get teacherDashNoSessionPackagesSubtitle =>
      'Tambahkan periode kelas di profil murid untuk memantau sesi.';

  @override
  String teacherDashSessionsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sisa $count sesi',
    );
    return '$_temp0';
  }

  @override
  String get teacherDashNoClassesThisWeekTitle => 'Tidak ada kelas minggu ini';

  @override
  String get teacherDashNoClassesThisWeekSubtitle =>
      'Buat sesi kelas dari tab Kelas.';

  @override
  String get teacherDashConcluded => 'Selesai';

  @override
  String get teacherDashNoActivityTitle => 'Belum ada aktivitas minggu ini';

  @override
  String get teacherDashNoActivitySubtitle =>
      'Aktivitas pelajaran dan latihan akan muncul di sini.';

  @override
  String get teacherDashStatStudentsTitle => 'Semua murid';

  @override
  String get teacherDashStatStudentsDescription =>
      'Semua murid terdaftar beserta kemajuan, tugas, dan sisa sesi.';

  @override
  String get teacherDashStatActiveThisWeekDescription =>
      'Murid yang menyelesaikan pelajaran atau mengirim latihan dalam 7 hari terakhir.';

  @override
  String get teacherDashStatHomeworkDoneTitle => 'Tugas selesai';

  @override
  String get teacherDashStatHomeworkDoneDescription =>
      'Latihan yang ditugaskan dan sudah diselesaikan murid.';

  @override
  String get teacherDashStatOverdueTitle => 'Latihan terlambat';

  @override
  String get teacherDashStatOverdueDescription =>
      'Latihan yang ditugaskan, sudah lewat jatuh tempo, dan belum selesai.';

  @override
  String get teacherDashStatAvgQuizTitle => 'Rata-rata kuis';

  @override
  String get teacherDashStatAvgQuizDescription =>
      'Rata-rata skor kuis per murid dari pelajaran yang selesai.';

  @override
  String get teacherDashStatAvgPracticeTitle => 'Rata-rata latihan';

  @override
  String get teacherDashStatAvgPracticeDescription =>
      'Skor latihan terbaik per murid dari latihan yang ditugaskan.';

  @override
  String get teacherDashStatSessionsLeftTitle => 'Sisa sesi kelas';

  @override
  String get teacherDashStatSessionsLeftDescription =>
      'Sisa sesi kelas tatap muka pada paket voucher yang aktif.';

  @override
  String get teacherDashStatClassesThisWeekTitle => 'Kelas minggu ini';

  @override
  String get teacherDashStatClassesThisWeekDescription =>
      'Sesi kelas yang dijadwalkan pada minggu kalender ini.';

  @override
  String get teacherDashStatNeedAttentionTitle => 'Murid yang perlu perhatian';

  @override
  String get teacherDashStatNeedAttentionDescription =>
      'Tugas terlambat, tugas yang lama tidak dikerjakan, murid tidak aktif, dan sisa sesi yang sedikit.';

  @override
  String get teacherDashStatWeeklyActivityTitle => 'Aktivitas mingguan';

  @override
  String get teacherDashStatWeeklyActivityDescription =>
      'Pelajaran yang selesai dan latihan yang dikirim dari hari ke hari.';

  @override
  String get teacherDashStatHomeworkOverviewTitle => 'Ringkasan tugas';

  @override
  String get teacherDashStatHomeworkOverviewDescription =>
      'Semua latihan yang ditugaskan beserta status, jatuh tempo, dan skor terbaik.';

  @override
  String teacherAttClassCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelas',
    );
    return '$_temp0';
  }

  @override
  String teacherAttConcludedCount(int count) {
    return '$count selesai';
  }

  @override
  String get teacherAttNewClassThisDay => 'Kelas baru di hari ini';

  @override
  String get teacherAttEmptyDayHint =>
      'Pilih hari lain, atau buat kelas pada tanggal ini. Titik di kalender menandai hari yang ada kelasnya: hijau toska = dibuka, abu-abu = selesai.';

  @override
  String get teacherAttClassConcludedTitle => 'Kelas ditutup';

  @override
  String teacherAttClassConcludedBody(String title, String summary) {
    return '$title ditutup. $summary.';
  }

  @override
  String teacherAttConcludeSummary(int charged, int excused) {
    String _temp0 = intl.Intl.pluralLogic(
      excused,
      locale: localeName,
      other: '$charged dipotong sesi, $excused izin',
      zero: '$charged dipotong sesi',
    );
    return '$_temp0';
  }

  @override
  String teacherAttConcludedSnack(String summary) {
    return 'Kelas ditutup. $summary.';
  }

  @override
  String teacherAttConcludedWithFailures(int charged, String names) {
    return 'Kelas ditutup. $charged dipotong sesi; tidak dapat dipotong: $names';
  }

  @override
  String teacherAttStudentAdded(String name) {
    return '$name ditambahkan ke kelas';
  }

  @override
  String get teacherAttRemoveStudentTitle => 'Hapus murid?';

  @override
  String teacherAttRemoveStudentBody(String name, String title) {
    return 'Hapus $name dari \"$title\"?';
  }

  @override
  String teacherAttStudentRemoved(String name) {
    return '$name dihapus dari kelas';
  }

  @override
  String get teacherAttAllStudentsInClass =>
      'Semua murid sudah ada di kelas ini';

  @override
  String get teacherAttAddStudent => 'Tambah murid';

  @override
  String get teacherAttClose => 'Tutup';

  @override
  String get teacherAttDeleteClassTitle => 'Hapus kelas ini?';

  @override
  String teacherAttDeleteClassBody(String title) {
    return 'Hapus \"$title\"? Semua catatan murid yang bergabung di kelas ini akan dihapus. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get teacherAttDelete => 'Hapus';

  @override
  String get teacherAttClassDeleted => 'Kelas dihapus';

  @override
  String get teacherAttThisStudent => 'Murid ini';

  @override
  String teacherAttNoCreditsFor(String name) {
    return '$name tidak punya sisa sesi kelas. Tambahkan periode 8 atau 16 sesi dari profilnya.';
  }

  @override
  String get teacherAttDeletePermissionDenied =>
      'Tidak dapat menghapus: akses ditolak.';

  @override
  String teacherAttDeleteFailed(String code) {
    return 'Tidak dapat menghapus kelas ($code)';
  }

  @override
  String teacherAttStatsConcluded(int joined, int charged) {
    return '$joined bergabung · $charged dipotong sesi';
  }

  @override
  String teacherAttStatsOpen(int joined, int capacity, int pending) {
    return '$joined/$capacity bergabung · $pending menunggu';
  }

  @override
  String teacherAttConcludedAt(String date) {
    return 'Selesai $date';
  }

  @override
  String get teacherAttConclude => 'Tutup';

  @override
  String get teacherAttEdit => 'Ubah';

  @override
  String get teacherAttAdd => 'Tambah';

  @override
  String get teacherAttAtCapacity => 'Kelas sudah penuh.';

  @override
  String teacherAttStudentsCount(int count) {
    return 'Murid ($count)';
  }

  @override
  String get teacherAttNoStudentsJoined => 'Belum ada murid yang bergabung.';

  @override
  String get teacherAttChipCharged => 'Dipotong sesi';

  @override
  String get teacherAttChipNotCharged => 'Tidak dipotong';

  @override
  String get teacherAttChipAdded => 'Ditambahkan';

  @override
  String get teacherAttNoAttendanceYet => 'Belum ada absensi yang tercatat.';

  @override
  String get teacherAttNoClassAttendanceYet =>
      'Belum ada absensi kelas yang tercatat.';

  @override
  String get teacherAttSessions => 'Sesi';

  @override
  String get teacherAttRate => 'Persentase';

  @override
  String get teacherSessionPermissionDenied =>
      'Tidak dapat menyelesaikan tindakan: akses ditolak.';

  @override
  String teacherSessionActionFailed(String code) {
    return 'Tidak dapat menyelesaikan tindakan ($code)';
  }

  @override
  String teacherSessionTimeAndDuration(String time, int minutes) {
    return '$time · $minutes menit';
  }

  @override
  String get teacherSessionStudentsJoined => 'Murid yang bergabung';

  @override
  String get teacherSessionSelfJoin => 'Gabung sendiri';

  @override
  String get teacherSessionDeleteClass => 'Hapus kelas';

  @override
  String get teacherSessionEndAfterStart =>
      'Waktu selesai harus setelah waktu mulai.';

  @override
  String get teacherSessionEditTitle => 'Ubah kelas';

  @override
  String get teacherSessionClassTitle => 'Judul kelas';

  @override
  String get teacherSessionClassTitleHint => 'mis. HSK 3 — Latihan berbicara';

  @override
  String get teacherSessionClassTitleRequired => 'Masukkan judul kelas';

  @override
  String get teacherSessionDate => 'Tanggal';

  @override
  String get teacherSessionStart => 'Mulai';

  @override
  String get teacherSessionEnd => 'Selesai';

  @override
  String get teacherSessionDuration => 'Durasi';

  @override
  String teacherSessionMinutes(int minutes) {
    return '$minutes menit';
  }

  @override
  String get teacherSessionCapacity => 'Kapasitas';

  @override
  String get teacherSessionCapacityHint =>
      'Jumlah maksimal murid yang bisa bergabung';

  @override
  String get teacherSessionCapacityMin => 'Masukkan kapasitas minimal 1';

  @override
  String get teacherSessionOpenToJoin => 'Dibuka untuk murid bergabung';

  @override
  String get teacherSessionOpenToJoinHint =>
      'Murid dapat bergabung dari Beranda selama kelas dibuka.';

  @override
  String get teacherSessionSaveChanges => 'Simpan perubahan';

  @override
  String get teacherSessionCreate => 'Buat kelas';

  @override
  String get teacherSessionModeOffline => 'Tatap muka';

  @override
  String get teacherSessionModeOnline => 'Daring';

  @override
  String get teacherSessionModeHybrid => 'Hibrida';

  @override
  String get teacherSessionRegDraft => 'Draf';

  @override
  String get teacherSessionRegOpen => 'Dibuka untuk pendaftaran';

  @override
  String get teacherSessionRegActive => 'Aktif';

  @override
  String get teacherSessionRegClosed => 'Ditutup';

  @override
  String teacherStudentsLoadFailed(String error) {
    return 'Tidak dapat memuat murid: $error';
  }

  @override
  String get studentDetailNotFound => 'Murid tidak ditemukan';

  @override
  String get studentDetailEditProfile => 'Ubah profil';

  @override
  String get studentDetailExportReport => 'Ekspor laporan kemajuan';

  @override
  String studentDetailLessonsPerTerm(int count) {
    return '$count pelajaran/periode';
  }

  @override
  String get studentDetailContact => 'Kontak';

  @override
  String get studentDetailExportReportPdf => 'Ekspor laporan kemajuan (PDF)';

  @override
  String get studentDetailAttendance => 'Absensi';

  @override
  String get studentDetailPracticeResults => 'Hasil latihan';

  @override
  String get studentDetailLessonProgressByTerm =>
      'Kemajuan pelajaran per periode';

  @override
  String get studentDetailNoLessonProgress => 'Belum ada kemajuan pelajaran.';

  @override
  String get studentDetailNoInvoices => 'Belum ada tagihan.';

  @override
  String studentDetailPaidTotal(String amount) {
    return 'Lunas $amount';
  }

  @override
  String studentDetailPendingTotal(String amount) {
    return 'Menunggu $amount';
  }

  @override
  String studentDetailPaidOn(String date) {
    return 'lunas $date';
  }

  @override
  String studentDetailDueOn(String date) {
    return 'jatuh tempo $date';
  }

  @override
  String studentDetailMoreInPayments(int count) {
    return 'dan $count lainnya di Pembayaran';
  }

  @override
  String studentDetailPresentCount(int count) {
    return '$count hadir';
  }

  @override
  String studentDetailExcusedCount(int count) {
    return '$count izin';
  }

  @override
  String studentDetailAbsentCount(int count) {
    return '$count alpa';
  }

  @override
  String get studentDetailNotMarked => 'Belum ditandai';

  @override
  String get teacherGradesNew => 'Nilai baru';

  @override
  String get teacherGradesEmptyTitle => 'Belum ada nilai';

  @override
  String get teacherGradesEmptySubtitle =>
      'Catat skor penilaian, atau jadwalkan nilai yang menunggu untuk diisi nanti.';

  @override
  String teacherGradesPendingHeader(int count) {
    return 'Nilai menunggu ($count)';
  }

  @override
  String get teacherGradesRecorded => 'Tercatat';

  @override
  String get teacherGradesNoRecorded => 'Belum ada nilai yang tercatat.';

  @override
  String get teacherGradesColAssessment => 'Penilaian';

  @override
  String get teacherGradesColCategory => 'Kategori';

  @override
  String get teacherGradesColScore => 'Skor';

  @override
  String get teacherGradesColLetter => 'Huruf';

  @override
  String get teacherGradesColStatus => 'Status';

  @override
  String get teacherGradesColActions => 'Tindakan';

  @override
  String get teacherGradesAddScore => 'Tambah skor';

  @override
  String get teacherGradesEdit => 'Ubah nilai';

  @override
  String get teacherGradesDelete => 'Hapus nilai';

  @override
  String get teacherGradesDeleteTitle => 'Hapus nilai?';

  @override
  String get teacherGradesDeleteBody => 'Nilai murid ini akan dihapus.';

  @override
  String get teacherGradesPickStudent => 'Pilih murid';

  @override
  String get teacherGradesPickStudentError => 'Pilih murid.';

  @override
  String teacherGradesSaveFailed(String error) {
    return 'Tidak dapat menyimpan nilai: $error';
  }

  @override
  String get teacherGradesTitleLabel => 'Judul';

  @override
  String get teacherGradesTitleHint => 'mis. Tes Berbicara, Ujian Tengah';

  @override
  String get teacherGradesTitleRequired => 'Masukkan judul';

  @override
  String get teacherGradesScoreLabel => 'Skor (0–100)';

  @override
  String get teacherGradesScoreLabelOptional =>
      'Skor (0–100) — kosongkan untuk dijadwalkan';

  @override
  String get teacherGradesScoreRange => 'Masukkan angka 0–100';

  @override
  String get teacherGradesSave => 'Simpan';

  @override
  String get teacherGradesCreate => 'Buat nilai';

  @override
  String teacherGradesLetterHint(String letter) {
    return 'Nilai huruf: $letter';
  }

  @override
  String get teacherGradesCategoryQuiz => 'Kuis';

  @override
  String get teacherGradesCategoryExercise => 'Latihan';

  @override
  String get teacherGradesCategorySpeaking => 'Berbicara';

  @override
  String get teacherGradesCategoryWriting => 'Menulis';

  @override
  String get teacherGradesCategoryExam => 'Ujian';

  @override
  String get teacherGradesCategoryOther => 'Lainnya';

  @override
  String get teacherGradesStatusPending => 'Menunggu';

  @override
  String get teacherGradesStatusGraded => 'Sudah dinilai';

  @override
  String get concludeTitle => 'Tutup kelas';

  @override
  String get concludeHint =>
      'Tandai siapa yang hadir. Hadir dan Alpa memotong 1 sesi dari periode murid; Izin (sebelum kelas) tidak dipotong.';

  @override
  String get concludeNoStudents =>
      'Tidak ada murid yang dipotong sesinya. Menutup kelas hanya mengakhiri kelas ini.';

  @override
  String concludeChargeSummary(int charged, int total) {
    return '$charged dari $total akan dipotong sesinya. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get leaveClassTitle => 'Keluar dari kelas ini?';

  @override
  String get leaveClassBody =>
      'Anda akan dikeluarkan dari daftar kelas. Anda dapat bergabung lagi dari Beranda jika kelas masih dibuka dan ada tempat.';

  @override
  String get leaveClassStay => 'Tetap di kelas';

  @override
  String get appShellBack => 'Kembali';

  @override
  String get evaluationsTitle => 'Evaluasi';

  @override
  String get evaluationsNew => 'Baru';

  @override
  String get evaluationsFormsClosed =>
      'Formulir evaluasi ditutup. Admin dapat membukanya di Pengaturan.';

  @override
  String get evaluationsEmpty => 'Belum ada evaluasi.';

  @override
  String get evaluationsFallbackTitle => 'Evaluasi';

  @override
  String get evaluationsPublished => 'Terbit';

  @override
  String get evaluationsDraft => 'Draf';

  @override
  String get evaluationsEditTitle => 'Ubah evaluasi';

  @override
  String get evaluationsNewTitle => 'Evaluasi baru';

  @override
  String get evaluationsTermLabel => 'Periode';

  @override
  String get evaluationsTermHint => 'mis. Semester 1 2026';

  @override
  String get evaluationsTermRequired => 'Masukkan periode';

  @override
  String get evaluationsRating => 'Rating';

  @override
  String get evaluationsStrengths => 'Kelebihan';

  @override
  String get evaluationsImprovements => 'Hal yang perlu ditingkatkan';

  @override
  String get evaluationsComment => 'Komentar';

  @override
  String get evaluationsSaveDraft => 'Simpan draf';

  @override
  String get evaluationsPublish => 'Terbitkan';

  @override
  String get transcriptEmptySubtitle =>
      'Hasil penilaian dan skor latihan akan muncul di sini setelah dicatat.';

  @override
  String get transcriptPendingHeader => 'Akan datang / menunggu';

  @override
  String get transcriptTeacherEvaluations => 'Evaluasi guru';

  @override
  String get transcriptTitle => 'Transkrip';

  @override
  String get transcriptPracticeExercise => 'Latihan praktik';

  @override
  String get transcriptLessonQuiz => 'Kuis pelajaran';

  @override
  String get transcriptToImprove => 'Perlu ditingkatkan';

  @override
  String transcriptAwaitingScore(String category) {
    return '$category · menunggu skor';
  }

  @override
  String get calendarFormatMonth => 'Bulan';

  @override
  String get calendarFormatTwoWeeks => '2 minggu';

  @override
  String get calendarFormatWeek => 'Minggu';

  @override
  String get calendarNoClasses => 'Tidak ada kelas';

  @override
  String calendarNoSessionsOn(String date) {
    return 'Tidak ada sesi kelas pada $date.';
  }

  @override
  String calendarCapacity(int count) {
    return 'Kapasitas $count';
  }

  @override
  String get calendarConcluded => 'selesai';

  @override
  String get exerciseTypeMultipleChoice => 'Pilihan ganda';

  @override
  String get exerciseTypeComposeSentences => 'Susun kalimat (组词成句)';

  @override
  String get exerciseTypeMatching => 'Menjodohkan (对话配对)';

  @override
  String get exerciseTypeListening => 'Menyimak (听力)';

  @override
  String get exerciseTypeReadingCloze => 'Isian (选词填空)';

  @override
  String get exerciseTypePictureSentence => 'Kalimat bergambar + kata kunci';

  @override
  String get exerciseTypeTypeHanzi => 'Tulis hanzi (写汉字)';

  @override
  String get exerciseCategoryExercise => 'Latihan';

  @override
  String get exerciseCategoryQuiz => 'Kuis';

  @override
  String get exerciseCategoryExam => 'Ujian';

  @override
  String get exerciseCategoryHskSimulation => 'Simulasi HSK';

  @override
  String get skillCategoryReading => 'Membaca';

  @override
  String get skillCategoryListening => 'Menyimak';

  @override
  String get skillCategoryTyping => 'Mengetik (Menulis)';

  @override
  String get skillCategorySpeaking => 'Berbicara';

  @override
  String bankTextOrder(String segments) {
    return 'Urutan: $segments';
  }

  @override
  String bankTextAnswer(String answer) {
    return 'Jawaban: $answer';
  }

  @override
  String bankTextPinyin(String pinyin, String answers) {
    return 'Pinyin $pinyin → $answers';
  }

  @override
  String get bankTextTypeHanziInEditor => 'tulis hanzi di editor';

  @override
  String bankTextKeyword(String keyword) {
    return 'Kata kunci: $keyword';
  }

  @override
  String get bankTextNoOptionsYet => 'Pilihan jawaban belum terbaca';

  @override
  String bankTextQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal',
    );
    return '$_temp0';
  }

  @override
  String exerciseCardToDoCount(int count) {
    return '$count belum dikerjakan';
  }

  @override
  String exerciseCardOverdueCount(int count) {
    return '$count lewat tempo';
  }

  @override
  String exerciseCardDoneCount(int count) {
    return '$count selesai';
  }

  @override
  String exerciseCardWorksheets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lembar soal',
    );
    return '$_temp0';
  }

  @override
  String get exerciseCardNotStarted => 'Belum dimulai';

  @override
  String get exerciseCardOverdueLower => 'lewat tempo';

  @override
  String exerciseCardBest(int score) {
    return 'Terbaik $score%';
  }

  @override
  String exerciseCardAttempts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count percobaan',
    );
    return '$_temp0';
  }

  @override
  String get exerciseCardTapToRetry => 'Ketuk untuk mencoba lagi';

  @override
  String exerciseCardLast(String date) {
    return 'Terakhir $date';
  }

  @override
  String get exerciseCardStatusToDo => 'Belum dikerjakan';

  @override
  String get exerciseCardStatusOverdue => 'Lewat tempo';

  @override
  String get exerciseCardStatusDone => 'Selesai';

  @override
  String exerciseCardDue(String date) {
    return 'Jatuh tempo $date';
  }

  @override
  String exerciseCardOverdueOn(String date) {
    return 'Lewat tempo · $date';
  }

  @override
  String get exerciseCardUnknownStudent => 'Murid tidak dikenal';

  @override
  String get exerciseCardThisLevel => 'level ini';

  @override
  String get exerciseCardStudentProgress => 'Kemajuan murid';

  @override
  String exerciseCardNoStudentsRegistered(String level) {
    return 'Belum ada murid $level yang terdaftar.';
  }

  @override
  String exerciseCardCompletedOpenTo(int completed, int total, String level) {
    return '$completed/$total selesai · terbuka untuk $level';
  }

  @override
  String get exerciseCardPending => 'Menunggu';

  @override
  String get exerciseCardClose => 'Tutup';

  @override
  String get exerciseCardNoPracticeTitle => 'Belum ada latihan yang ditugaskan';

  @override
  String get exerciseCardNoPracticeSubtitle =>
      'Latihan yang ditugaskan akan muncul di sini.';

  @override
  String exerciseCardBestScoreRetry(int score) {
    return 'Skor terbaik: $score% · Ketuk untuk mencoba lagi';
  }

  @override
  String get bankFiltersSearchHint => 'Cari lembar soal atau soal';

  @override
  String get bankFiltersTypeOfExercise => 'Jenis latihan';

  @override
  String get bankFiltersQuestionType => 'Tipe soal';

  @override
  String get bankFiltersLevel => 'Level';

  @override
  String get bankFiltersAll => 'Semua';

  @override
  String get bankTitle => 'Bank soal';

  @override
  String get bankCsvWorksheetOrQuestion => 'Lembar soal / soal';

  @override
  String get bankCsvCode => 'Kode';

  @override
  String get bankQuestions => 'Soal';

  @override
  String get bankUsed => 'Dipakai';

  @override
  String get bankActions => 'Tindakan';

  @override
  String bankTypeOfExerciseFor(String what) {
    return 'Jenis latihan untuk $what';
  }

  @override
  String bankLevelFor(String what) {
    return 'Level untuk $what';
  }

  @override
  String bankSetTo(String what, String value) {
    return '$what diubah menjadi $value.';
  }

  @override
  String bankDeleteWhat(String what) {
    return 'Hapus $what?';
  }

  @override
  String bankDeleteBulkBody(String questions) {
    return 'Semua $questions akan keluar dari bank soal. Latihan yang sudah memakainya tetap menyimpan salinannya. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String bankDeleted(String what) {
    return '$what dihapus.';
  }

  @override
  String bankCountJoin(String a, String b) {
    return '$a dan $b';
  }

  @override
  String get bankApply => 'Terapkan';

  @override
  String bankNewExerciseWithSheets(String worksheets) {
    return 'Latihan baru ($worksheets)';
  }

  @override
  String get bankSetTypeOfExercise => 'Atur jenis latihan';

  @override
  String get bankSetLevel => 'Atur level';

  @override
  String get bankDelete => 'Hapus';

  @override
  String get bankEdit => 'Ubah';

  @override
  String get bankTypeAQuestion => 'Ketik soal';

  @override
  String get bankLoadSamples =>
      'Muat lembar contoh pusat belajar (10 lembar soal)';

  @override
  String get bankBulkPaste => 'Impor massal — tempel';

  @override
  String get bankScanWorksheet => 'Pindai lembar soal';

  @override
  String get bankNoWorksheetsTitle => 'Belum ada lembar soal';

  @override
  String get bankNoWorksheetsSubtitle =>
      'Pindai lembar soal untuk menambahkannya sekaligus, atau ketik satu soal. Latihan mengambil soal dari sini.';

  @override
  String get bankNoMatchesTitle => 'Tidak ada yang cocok';

  @override
  String get bankAdjustFilters => 'Sesuaikan filter.';

  @override
  String bankUsedCount(int count) {
    return 'Dipakai $count';
  }

  @override
  String bankAddFromBankType(String type) {
    return 'Tambah dari bank soal — $type';
  }

  @override
  String bankAddCount(int count) {
    return 'Tambah ($count)';
  }

  @override
  String get bankFilterHint => 'Saring lembar soal dan soal…';

  @override
  String bankSelectAllFiltered(int count) {
    return 'Pilih semua ($count tersaring)';
  }

  @override
  String get bankNoMatchingTitle => 'Tidak ada soal bank yang cocok';

  @override
  String get bankNoMatchingSubtitle =>
      'Tambahkan dulu soal dengan tipe ini ke bank soal.';

  @override
  String get bankSheetAssignThis => 'Tugaskan lembar soal ini';

  @override
  String get bankSheetEditTooltip => 'Ubah lembar soal (judul, tipe, level)';

  @override
  String get bankSheetDeleteTooltip => 'Hapus lembar soal';

  @override
  String get bankSheetRemovedTitle => 'Lembar soal sudah dihapus';

  @override
  String get bankSheetRemovedSubtitle =>
      'Soal-soalnya sudah tidak ada di bank soal.';

  @override
  String get bankSheetAddQuestion => 'Tambah soal';

  @override
  String get bankSheetRemoveQuestionTitle => 'Hapus soal ini?';

  @override
  String get bankSheetRemoveQuestionBody =>
      'Soal ini akan keluar dari lembar soal dan bank soal. Latihan yang sudah memakainya tetap menyimpan salinannya.';

  @override
  String bankSheetDeleteSheetTitle(String code) {
    return 'Hapus lembar soal $code?';
  }

  @override
  String bankSheetDeleteSheetBody(String questions) {
    return 'Semua $questions akan keluar dari bank soal. Latihan yang sudah memakainya tetap menyimpan salinannya.';
  }

  @override
  String bankSheetUsedTimes(int count) {
    return 'dipakai $count×';
  }

  @override
  String get bankSheetNoPrompt => '(tanpa teks soal)';

  @override
  String get bankSheetEditQuestion => 'Ubah soal';

  @override
  String get bankSheetRemoveFromSheet => 'Hapus dari lembar soal';

  @override
  String get bankSheetEditSheet => 'Ubah lembar soal';

  @override
  String bankSheetCodeStays(String code) {
    return 'Kode $code tidak berubah.';
  }

  @override
  String get bankSheetCategoryHelper =>
      'Latihan, kuis, ujian, atau simulasi HSK.';

  @override
  String get bankSheetTypeChangesShape =>
      'Tipe ini menyimpan jawaban dengan cara berbeda: buka setiap soal setelahnya dan periksa jawabannya.';

  @override
  String get bankSheetTypeAppliesAll =>
      'Berlaku untuk semua soal di lembar ini.';

  @override
  String get bankEditorNeedTwoParts => 'Masukkan minimal dua bagian kalimat.';

  @override
  String get bankEditorEnterQuestion => 'Masukkan soal.';

  @override
  String get bankEditorNeedTwoWords =>
      'Masukkan minimal dua kata di bank kata.';

  @override
  String get bankEditorEnterPinyin => 'Masukkan petunjuk pinyin.';

  @override
  String get bankEditorNeedAccepted =>
      'Masukkan minimal satu jawaban yang diterima.';

  @override
  String get bankEditorEnterKeyword =>
      'Masukkan kata yang harus dipakai dalam kalimat.';

  @override
  String get bankEditorNeedTwoChoices => 'Masukkan minimal dua pilihan.';

  @override
  String get bankEditorCorrectEmpty => 'Pilihan yang benar masih kosong.';

  @override
  String bankEditorUploadFailed(String error) {
    return 'Unggah gagal: $error';
  }

  @override
  String bankEditorCouldNotSave(String error) {
    return 'Tidak dapat menyimpan: $error';
  }

  @override
  String bankEditorAddToSheetTitle(String title) {
    return 'Tambah soal ke $title';
  }

  @override
  String get bankEditorNewQuestion => 'Soal baru';

  @override
  String get bankEditorExplanationOptional => 'Pembahasan (opsional)';

  @override
  String get bankEditorExplanationHelper =>
      'Alasan jawaban itu benar. Murid melihatnya di halaman hasil setelah mengumpulkan, tidak pernah saat menjawab.';

  @override
  String get bankEditorSkill => 'Keterampilan';

  @override
  String get bankEditorSave => 'Simpan';

  @override
  String get bankEditorAddToWorksheet => 'Tambah ke lembar soal';

  @override
  String get bankEditorAddToBank => 'Tambah ke bank soal';

  @override
  String bankEditorOptionalSuffix(String label) {
    return '$label (opsional)';
  }

  @override
  String get bankEditorQuestion => 'Soal';

  @override
  String get bankEditorListeningHelper =>
      'Tambahkan audio di bawah; murid mendengarkannya lalu memilih jawaban.';

  @override
  String get bankEditorChoicesTick => 'Pilihan (tandai yang benar)';

  @override
  String get bankEditorSentenceWithBlank => 'Kalimat dengan bagian kosong';

  @override
  String get bankEditorQuestionOrLine => 'Soal atau kalimat';

  @override
  String get bankEditorClozeHelper =>
      'Tulis bagian kosong sebagai ____ ; murid memilih kata dari bank kata.';

  @override
  String get bankEditorMatchingHelper =>
      'Murid menjodohkannya dengan satu kata atau balasan dari bank kata.';

  @override
  String get bankEditorWordBank => 'Bank kata (satu per baris)';

  @override
  String get bankEditorWordBankHelper =>
      'Dipakai bersama oleh seluruh lembar soal: daftar yang sama pada setiap soal di lembar ini.';

  @override
  String get bankEditorCorrectAnswer => 'Kunci jawaban';

  @override
  String get bankEditorBlankNumber => 'Kosong ke-';

  @override
  String get bankEditorSentenceParts =>
      'Bagian kalimat dalam urutan yang benar (satu per baris)';

  @override
  String get bankEditorSentencePartsHelper =>
      'Murid melihatnya dalam urutan acak lalu menyusunnya kembali.';

  @override
  String get bankEditorInstruction => 'Petunjuk';

  @override
  String get bankEditorPinyinHint => 'Petunjuk pinyin';

  @override
  String get bankEditorPinyinHelper => 'Yang dilihat murid, mis. nǐ hǎo.';

  @override
  String get bankEditorAcceptedAnswers =>
      'Jawaban yang diterima (satu per baris)';

  @override
  String get bankEditorAcceptedHelper => 'Hanzi yang dianggap benar, mis. 你好.';

  @override
  String get bankEditorKeywordLabel => 'Kata yang harus dipakai dalam kalimat';

  @override
  String get bankEditorKeywordHelper =>
      'Murid menulis kalimat dengan kata ini tentang gambar tersebut.';

  @override
  String bankEditorChoice(String letter) {
    return 'Pilihan $letter';
  }

  @override
  String get bankEditorRemoveChoice => 'Hapus pilihan';

  @override
  String get bankEditorAddChoice => 'Tambah pilihan';

  @override
  String get bankEditorMediaOptional => 'Media (opsional)';

  @override
  String get bankEditorAddImage => 'Tambah gambar';

  @override
  String get bankEditorImageAttached => 'Gambar terlampir';

  @override
  String get bankEditorAddAudio => 'Tambah audio';

  @override
  String get bankEditorAudioAttached => 'Audio terlampir';

  @override
  String get bankImportPasteTitle => 'Tempel soal';

  @override
  String get bankImportPasteHint =>
      'Tempel teks lembar soal (soal bernomor + pilihan A/B/C/D).';

  @override
  String get bankImportPasteExample =>
      '1. 你好 artinya…\nA. halo\nB. selamat tinggal';

  @override
  String get bankImportType => 'Tipe';

  @override
  String get bankImportImport => 'Impor';

  @override
  String get bankImportNoneParsed => 'Tidak ada soal yang dapat dibaca.';

  @override
  String get bankImportAllSamplesPresent =>
      'Semua soal contoh sudah ada di bank soal.';

  @override
  String bankImportSampleSummary(String name, int count, String skippedNote) {
    return '$name: $count soal dari 10 lembar soal dengan kunci jawaban$skippedNote. Gambar untuk kata kunci 看图写句子 ditambahkan di editor.';
  }

  @override
  String bankImportSampleSkipped(int count) {
    return ', $count sudah ada di bank soal';
  }

  @override
  String get bankImportNothingToImport => 'Tidak ada soal untuk diimpor.';

  @override
  String bankImportParsedFromPaste(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal terbaca dari teks yang ditempel.',
    );
    return '$_temp0';
  }

  @override
  String bankImportReplacedSheet(String code, String questions) {
    return 'Lembar soal $code ($questions) diganti di bank soal.';
  }

  @override
  String bankImportAddedSheet(String code, String questions) {
    return 'Lembar soal $code ($questions) ditambahkan ke bank soal.';
  }

  @override
  String bankImportReplacedQuestions(String questions) {
    return '$questions diganti di bank soal.';
  }

  @override
  String bankImportAddedQuestions(String questions) {
    return '$questions ditambahkan ke bank soal.';
  }

  @override
  String bankImportCouldNotImport(String error) {
    return 'Tidak dapat mengimpor: $error';
  }

  @override
  String get bankImportReviewTitle => 'Periksa sebelum menambahkan';

  @override
  String bankImportReviewWorksheet(String code) {
    return 'Lembar soal $code';
  }

  @override
  String get bankImportReviewAddedAsOne =>
      'Ditambahkan ke bank soal sebagai satu lembar soal. Hapus centang pada soal yang tidak ingin disertakan.';

  @override
  String bankImportReviewAlreadyInBank(String questions) {
    return 'Lembar soal ini sudah ada di bank soal dengan $questions.';
  }

  @override
  String get bankImportReviewReplaceIt => 'Ganti';

  @override
  String get bankImportReviewKeepBoth => 'Simpan keduanya';

  @override
  String bankImportReviewReplaceWorksheet(String questions) {
    return 'Ganti lembar soal ($questions)';
  }

  @override
  String bankImportReviewAddWorksheet(String questions) {
    return 'Tambah lembar soal ($questions)';
  }

  @override
  String bankImportReviewAddToBank(int count) {
    return 'Tambah $count ke bank soal';
  }

  @override
  String bankHarvestCouldNotLoad(String error) {
    return 'Latihan tidak dapat dimuat: $error';
  }

  @override
  String bankHarvestNoNew(int skipped) {
    return 'Tidak ada soal baru — $skipped sudah ada di bank soal.';
  }

  @override
  String get bankHarvestTitle => 'Impor dari latihan';

  @override
  String bankHarvestFound(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ditemukan $count soal baru.',
    );
    return '$_temp0\n$skipped sudah ada di bank soal (dilewati).';
  }

  @override
  String bankHarvestImportCount(int count) {
    return 'Impor $count';
  }

  @override
  String bankHarvestImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal diimpor dari latihan.',
    );
    return '$_temp0';
  }

  @override
  String get worksheetCouldNotReadFile =>
      'File yang dipilih tidak dapat dibaca.';

  @override
  String worksheetImportFailed(String error) {
    return 'Impor gagal: $error';
  }

  @override
  String get worksheetImporting => 'Mengimpor lembar soal';

  @override
  String get worksheetTimingNote =>
      'PDF teks dan file Word butuh beberapa detik. Halaman hasil pindai dan foto butuh 20–40 detik per halaman; pindaian pertama juga mengunduh data OCR Mandarin (sekitar 15 MB).';

  @override
  String worksheetElapsed(String time) {
    return 'Berjalan $time';
  }

  @override
  String get worksheetEstimating => 'memperkirakan sisa waktu…';

  @override
  String get worksheetAlmostDone => 'hampir selesai';

  @override
  String worksheetAboutSecondsLeft(int seconds) {
    return 'sekitar $seconds detik lagi';
  }

  @override
  String worksheetAboutMinutesLeft(int minutes) {
    return 'sekitar $minutes menit lagi';
  }

  @override
  String get worksheetFewMinutesLeft => 'beberapa menit lagi';

  @override
  String worksheetAnswerKeyFilled(int filled, int total) {
    return 'Kunci jawaban: $filled dari $total jawaban diisi dari set contoh pusat belajar.';
  }

  @override
  String worksheetAnswerKeyFilledCode(int filled, int total, String code) {
    return 'Kunci jawaban: $filled dari $total jawaban diisi dari set contoh pusat belajar ($code).';
  }

  @override
  String get worksheetNoKeyCompose =>
      'Lembar ini tidak punya kunci jawaban: kalimat mengikuti urutan yang tertulis di lembar. Susun kata-katanya dalam urutan yang benar di bank soal.';

  @override
  String get worksheetNoKeyTypeHanzi =>
      'Lembar ini tidak punya kunci jawaban: tambahkan hanzi yang diterima untuk setiap soal di bank soal.';

  @override
  String get worksheetNoKeyDefault =>
      'Lembar ini tidak punya kunci jawaban: semua jawaban diatur ke A (pilihan pertama). Perbaiki di bank soal.';

  @override
  String get worksheetReviewTitle => 'Periksa hasil impor';

  @override
  String get worksheetDetectedFormat => 'Format terdeteksi';

  @override
  String worksheetSuggestedLevel(String level) {
    return 'Level yang disarankan: $level';
  }

  @override
  String get worksheetTypeNotSupported =>
      'Tipe latihan ini belum didukung sepenuhnya. Anda tetap bisa menyalin petunjuk atau mengubah teksnya.';

  @override
  String get worksheetInstructionsOnly => 'Hanya petunjuk';

  @override
  String worksheetImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Impor $count soal',
    );
    return '$_temp0';
  }

  @override
  String get worksheetImportQuestions => 'Impor soal';

  @override
  String get worksheetExerciseType => 'Tipe latihan';

  @override
  String get worksheetExtractedText => 'Teks hasil ekstraksi';

  @override
  String get worksheetEditIfMisread => 'Ubah jika OCR salah membaca…';

  @override
  String get worksheetReanalyze => 'Analisis ulang';

  @override
  String get worksheetSentencePreview => 'Pratinjau kalimat';

  @override
  String get worksheetQuestionPreview => 'Pratinjau soal';

  @override
  String get worksheetNoQuestionsDetected =>
      'Belum ada soal yang terdeteksi. Ubah teksnya lalu ketuk Analisis ulang.';

  @override
  String worksheetAndMore(int count) {
    return '…dan $count lagi';
  }

  @override
  String worksheetPreviewPinyin(String pinyin, String answers) {
    return 'pinyin: $pinyin → $answers';
  }

  @override
  String get worksheetPreviewTypeInEditor => '(tulis hanzi di editor)';

  @override
  String worksheetPreviewKeyword(String keyword) {
    return 'kata kunci: $keyword';
  }

  @override
  String get worksheetPreviewAddOptions => '(tambahkan pilihan)';

  @override
  String assignAssignedTo(int count, String removed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ditugaskan kepada $count murid',
    );
    return '$_temp0$removed.';
  }

  @override
  String assignRemovedFrom(int count) {
    return ', dihapus dari $count';
  }

  @override
  String assignCouldNot(String error) {
    return 'Tidak dapat menugaskan: $error';
  }

  @override
  String assignTitle(String title) {
    return 'Tugaskan \"$title\"';
  }

  @override
  String get assignOnlyTicked =>
      'Hanya murid yang Anda centang yang dapat membuka latihan ini.';

  @override
  String get assignSearchStudents => 'Cari murid';

  @override
  String assignSelectAllShown(int count) {
    return 'Pilih semua yang tampil ($count)';
  }

  @override
  String get assignClear => 'Bersihkan';

  @override
  String get assignNoDueDate => 'Tanpa jatuh tempo';

  @override
  String get assignNoStudentsTitle => 'Tidak ada murid yang cocok';

  @override
  String get assignNoStudentsSubtitle => 'Ubah level atau kata pencarian.';

  @override
  String get assignAlreadyAssigned => 'sudah ditugaskan';

  @override
  String get assignSaving => 'Menyimpan…';

  @override
  String assignSaveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Simpan ($count murid)',
    );
    return '$_temp0';
  }

  @override
  String get packageFormAddAtLeastOne =>
      'Tambahkan minimal satu lembar soal atau soal.';

  @override
  String get packageFormSaved => 'Latihan disimpan.';

  @override
  String get packageFormCreated => 'Latihan dibuat.';

  @override
  String get packageFormEditTitle => 'Ubah latihan';

  @override
  String get packageFormTitle => 'Judul';

  @override
  String get packageFormEnterTitle => 'Masukkan judul';

  @override
  String get packageFormSkillSection => 'Bagian keterampilan';

  @override
  String get packageFormInstructionsOptional => 'Petunjuk (opsional)';

  @override
  String get packageFormTimeLimit => 'Batas waktu dalam menit (opsional)';

  @override
  String get packageFormTimeLimitHelper =>
      'Kosongkan jika tanpa batas. Dengan batas waktu, hitungan mundur berjalan dan latihan terkumpul otomatis saat waktu habis.';

  @override
  String get packageFormEnterMinutes =>
      'Masukkan jumlah menit dalam bilangan bulat';

  @override
  String get packageFormPublishedSubtitle =>
      'Murid yang ditugaskan dapat membukanya. Draf tetap tersembunyi.';

  @override
  String packageFormContents(String questions) {
    return 'Isi · $questions';
  }

  @override
  String get packageFormAddFromBank => 'Tambah dari bank soal';

  @override
  String get packageFormNothingYet =>
      'Belum ada isi. Tambahkan lembar soal dari bank soal; murid mengerjakannya dalam urutan ini. Jika lembar soal diubah di bank soal nanti, latihan ini ikut berubah.';

  @override
  String get packageFormNotInBank => 'Sudah tidak ada di bank soal';

  @override
  String get packageFormQuestionRemoved => '(soal sudah dihapus)';

  @override
  String get packageFormSaveDraftOrPublish =>
      'Simpan sebagai draf atau terbitkan';

  @override
  String get packageFormSaveAndAssign => 'Simpan dan tugaskan';

  @override
  String get packageFormMoveUp => 'Pindah ke atas';

  @override
  String get packageFormMoveDown => 'Pindah ke bawah';

  @override
  String get packageFormRemove => 'Hapus';

  @override
  String get packageFormAddFromQuestionBank => 'Tambah dari bank soal';

  @override
  String packageFormDoneCount(int count) {
    return 'Selesai ($count)';
  }

  @override
  String get packageFormSearchHint => 'Cari lembar soal dan soal…';

  @override
  String get packageFormBankEmptyTitle => 'Bank soal masih kosong';

  @override
  String get packageFormNoMatchTitle => 'Tidak ada yang cocok di bank soal';

  @override
  String get packageFormBankEmptySubtitle =>
      'Pindai lembar soal untuk menambahkan yang pertama.';

  @override
  String get packageFormNoMatchSubtitle => 'Ubah kata pencarian atau filter.';

  @override
  String get packageFormOpenEditSheet => 'Buka dan ubah lembar soal ini';

  @override
  String get packageFormEditQuestion => 'Ubah soal ini';

  @override
  String get teacherExExercise => 'Latihan';

  @override
  String get teacherExContents => 'Isi';

  @override
  String get teacherExStudents => 'Murid';

  @override
  String get teacherExDone => 'Selesai';

  @override
  String get teacherExNextDue => 'Jatuh tempo berikutnya';

  @override
  String get teacherExStatus => 'Status';

  @override
  String get teacherExExportCsv => 'Ekspor CSV';

  @override
  String get teacherExSelected => 'dipilih';

  @override
  String teacherExBulkPublished(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count latihan diterbitkan.',
    );
    return '$_temp0';
  }

  @override
  String teacherExBulkDraft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count latihan dijadikan draf.',
    );
    return '$_temp0';
  }

  @override
  String teacherExDeleteCountTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hapus $count latihan?',
    );
    return '$_temp0';
  }

  @override
  String get teacherExDeleteBulkBody =>
      'Murid kehilangan tugas ini. Hasil mereka sebelumnya tetap tersimpan. Tindakan ini tidak dapat dibatalkan.';

  @override
  String teacherExBulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count latihan dihapus.',
    );
    return '$_temp0';
  }

  @override
  String get teacherExPublish => 'Terbitkan';

  @override
  String get teacherExSetToDraft => 'Jadikan draf';

  @override
  String get teacherExViewOnly => 'Hanya lihat';

  @override
  String get teacherExAdminRequired => 'Perlu akses admin';

  @override
  String get teacherExDeleteTitle => 'Hapus latihan?';

  @override
  String teacherExDeleteBody(String title) {
    return 'Hapus \"$title\"? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get teacherExDeleted => 'Latihan dihapus';

  @override
  String teacherExSingleQuestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal tunggal',
    );
    return '$_temp0';
  }

  @override
  String teacherExSentences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kalimat',
    );
    return '$_temp0';
  }

  @override
  String get teacherExSearchExercises => 'Cari latihan';

  @override
  String get teacherExNewExercise => 'Latihan baru';

  @override
  String get teacherExFromBank => 'Dari bank soal';

  @override
  String get teacherExOldFormat =>
      'Format lama, murid tidak dapat mengerjakannya';

  @override
  String get teacherExNone => 'Tidak ada';

  @override
  String teacherExStudentsFinished(int completed, int total) {
    return '$completed dari $total murid selesai';
  }

  @override
  String get teacherExDue => 'Jatuh tempo';

  @override
  String get teacherExNoExercisesTitle => 'Belum ada latihan';

  @override
  String get teacherExNoExercisesSubtitle =>
      'Latihan menggabungkan lembar soal dari bank soal; murid melihatnya setelah ditugaskan kepada mereka.';

  @override
  String get teacherExNoExercisesSubtitleReadOnly =>
      'Latihan menggabungkan lembar soal dari bank soal; murid melihatnya setelah ditugaskan kepada mereka. Admin membuat latihan lewat web.';

  @override
  String get teacherExPublished => 'Terbit';

  @override
  String get teacherExDraft => 'Draf';

  @override
  String get teacherExAssign => 'Tugaskan';

  @override
  String get teacherExDraftHidden => 'Draf — tidak terlihat oleh murid';

  @override
  String get teacherExNotAssigned => 'Belum ditugaskan';

  @override
  String teacherExStudentsDone(int completed, int total) {
    return '$completed/$total murid selesai';
  }

  @override
  String teacherExDueLower(String date) {
    return 'jatuh tempo $date';
  }

  @override
  String get routeTitleNewUser => 'Pengguna baru';

  @override
  String get routeTitleEditUser => 'Ubah pengguna';

  @override
  String get routeTitleStudent => 'Murid';

  @override
  String get routeTitleNewVoucher => 'Voucher baru';

  @override
  String get routeTitleEditVoucher => 'Ubah voucher';

  @override
  String get routeTitleNewExercise => 'Latihan baru';

  @override
  String get routeTitleEditExercise => 'Ubah latihan';

  @override
  String get routeTitleNewClass => 'Kelas baru';

  @override
  String get routeTitleEditClass => 'Ubah kelas';

  @override
  String get routeTitleClassDetails => 'Detail kelas';

  @override
  String get routeTitleQuestionBank => 'Bank soal';

  @override
  String get routeTitleLevels => 'Level';

  @override
  String get routeTitleNewLevel => 'Level baru';

  @override
  String get routeTitleEditLevel => 'Ubah level';

  @override
  String get routeTitleQuizzes => 'Kuis';

  @override
  String get routeTitleSettings => 'Pengaturan';

  @override
  String get routeTitlePriceList => 'Daftar harga';

  @override
  String get routeTitleAuditLogs => 'Log audit';

  @override
  String get routeTitleMaterials => 'Materi';

  @override
  String get routeTitleAdmin => 'Admin';

  @override
  String get routeTitleStudentProfile => 'Profil murid';

  @override
  String get routeTitleCalendar => 'Kalender';

  @override
  String get routeTitleGrades => 'Nilai';

  @override
  String get routeTitleTeacher => 'Guru';

  @override
  String get notificationsTitle => 'Notifikasi';

  @override
  String get notificationsEmpty => 'Belum ada notifikasi.';

  @override
  String get teacherExAuthoringUnsupported =>
      'Membuat dan mengubah latihan hanya tersedia di web. Buka Easy Study di browser desktop untuk mengelola latihan.';

  @override
  String get teacherExAuthoringAdminOnly =>
      'Membuat dan mengubah latihan hanya dapat dilakukan admin di web.';

  @override
  String get teacherExAuthoringReadOnly =>
      'Hanya lihat: telusuri latihan yang terbit dan tugaskan ke murid. Membuat dan mengubah latihan dilakukan admin di web.';

  @override
  String get worksheetUploadUnsupported =>
      'Unggah lembar soal hanya tersedia untuk admin di web. Buka Easy Study di browser desktop untuk mengimpor lembar soal.';

  @override
  String get worksheetStepPrepare => 'Siapkan berkas';

  @override
  String get worksheetStepRead => 'Baca berkas';

  @override
  String get worksheetStepDetect => 'Deteksi soal';

  @override
  String get worksheetStagePreparing => 'Menyiapkan berkas…';

  @override
  String get worksheetStageReading => 'Membaca lembar soal…';

  @override
  String get worksheetStageDetecting => 'Mendeteksi jenis soal…';

  @override
  String get worksheetStageDone => 'Selesai';

  @override
  String get cohortNoActivity => 'Belum ada aktivitas';

  @override
  String get cohortToday => 'Hari ini';

  @override
  String cohortDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String get cohortNoHomework => 'Belum ada PR';

  @override
  String cohortHomeworkOverdueOf(int done, int assigned, int overdue) {
    return '$done/$assigned · $overdue terlambat';
  }

  @override
  String cohortHomeworkDoneOf(int done, int assigned) {
    return '$done/$assigned selesai';
  }

  @override
  String attentionOverdue(String name) {
    return '$name punya latihan yang terlambat';
  }

  @override
  String attentionStale(String name, int count) {
    return '$name belum memulai latihan yang ditugaskan ($count hari)';
  }

  @override
  String attentionInactive(String name, int count) {
    return '$name tidak aktif $count+ hari';
  }

  @override
  String attentionNoSessions(String name) {
    return '$name tidak punya sisa sesi kelas';
  }

  @override
  String attentionSessionsLeft(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesi kelas',
    );
    return '$name punya $_temp0 tersisa';
  }

  @override
  String activityScored(String name, int score) {
    return '$name mendapat $score%';
  }

  @override
  String activitySubmitted(int score) {
    return 'Latihan dikirim · $score%';
  }

  @override
  String get activityExerciseFallback => 'Latihan';

  @override
  String activityLessonCompletedBy(String name) {
    return '$name menyelesaikan pelajaran';
  }

  @override
  String get activityLessonCompleted => 'Pelajaran selesai';

  @override
  String activityLessonFallback(String id) {
    return 'Pelajaran $id';
  }

  @override
  String activityAssignedTo(String name) {
    return 'Latihan ditugaskan ke $name';
  }

  @override
  String get activityAssigned => 'Latihan ditugaskan';

  @override
  String get activityStudentFallback => 'Murid';

  @override
  String activityJoined(String name) {
    return '$name bergabung ke kelas';
  }

  @override
  String activityAdded(String name) {
    return 'Anda menambahkan $name ke kelas';
  }

  @override
  String get activityClassConcluded => 'Kelas ditutup';

  @override
  String activityTermAddedFor(String name) {
    return 'Paket periode ditambahkan untuk $name';
  }

  @override
  String get activityTermAdded => 'Paket periode ditambahkan';

  @override
  String activityTermSubtitle(int count, String start, String end) {
    return '$count sesi · $start → $end';
  }

  @override
  String get commonNoHskLevel => 'Belum ada level HSK';

  @override
  String get exercisePlayExamIntroTitle => 'Sebelum mulai';

  @override
  String get exercisePlayOneAttempt =>
      'Anda hanya punya satu kesempatan. Setelah dikirim, tidak bisa diulang.';

  @override
  String exercisePlayTimeLimit(int minutes) {
    return 'Batas waktu: $minutes menit. Waktu terus berjalan walau halaman ditutup.';
  }

  @override
  String exercisePlayQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count soal',
    );
    return '$_temp0';
  }

  @override
  String get exercisePlayStart => 'Mulai';

  @override
  String get exercisePlayAttemptUsedTitle => 'Sudah dikirim';

  @override
  String get exercisePlayAttemptUsedSubtitle =>
      'Ujian ini hanya satu kesempatan. Skor Anda ada di Kemajuan.';

  @override
  String get exercisePlayLateSubtitle =>
      'Dikirim setelah batas waktu, jadi tidak dinilai.';

  @override
  String get resultLate => 'Terlambat';
}
