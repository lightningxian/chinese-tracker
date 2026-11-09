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
  String get languageRowLabel => 'Bahasa / Language';

  @override
  String get languageToggleIndonesian => 'Bahasa Indonesia';

  @override
  String get languageToggleEnglish => 'English';

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
  String get studentNavMyClasses => 'Kelas Saya';

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
}
