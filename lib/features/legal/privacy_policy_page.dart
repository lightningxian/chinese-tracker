import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../landing/landing_brand.dart';

/// Owner 2026-11-24 (App Store): the public privacy policy at `/privacy`
/// (App Store Connect and Google Play ask for its address). The text is
/// kept here in both languages, as a legal page, instead of in the arb
/// files; the page follows the app language and has its own switch.
/// Keep it true to what the app does: change it with the features.
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool? _indonesian;

  @override
  Widget build(BuildContext context) {
    final id =
        _indonesian ?? Localizations.localeOf(context).languageCode == 'id';
    final sections = id ? _id : _en;
    // Always light, like the landing page, whatever the app theme.
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: LandingBrand.teal,
        textTheme: Theme.of(context)
            .textTheme
            .apply(bodyColor: LandingBrand.ink, displayColor: LandingBrand.ink),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: LandingBrand.ink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          title: Text(id ? 'Kebijakan Privasi' : 'Privacy Policy'),
          actions: [
            TextButton(
              onPressed: () => setState(() => _indonesian = !id),
              child: Text(id ? 'English' : 'Bahasa Indonesia'),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              children: [
                Text(
                    id
                        ? 'Kebijakan Privasi Easy Study'
                        : 'Easy Study Privacy Policy',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: LandingBrand.ink)),
                const SizedBox(height: 4),
                Text(
                    id
                        ? 'Berlaku sejak 24 November 2026'
                        : 'Effective 24 November 2026',
                    style: const TextStyle(color: Colors.black54)),
                for (final s in sections) ...[
                  const SizedBox(height: 22),
                  Text(s.$1,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: LandingBrand.ink)),
                  const SizedBox(height: 6),
                  Text(s.$2,
                      style: const TextStyle(
                          fontSize: 15, height: 1.55, color: LandingBrand.ink)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _contact = 'Easy Study (易华文教中心), Jl. Manyar Tirtomoyo 7/11, Surabaya. '
    'WhatsApp / phone 0823-3383-6362. Instagram @easystudy.sby.';

const _en = <(String, String)>[
  (
    'Who we are',
    'Easy Study is the app of Easy Study (易华文教中心), a Mandarin education centre in '
        'Surabaya, Indonesia. The centre is responsible for the data in the app. '
        'Contact: $_contact'
  ),
  (
    'What we collect',
    '• Account: name (Latin and Chinese), email address, WhatsApp number, the name and '
        'phone of a parent or guardian when given, role (student, parent, teacher, admin), '
        'HSK level, and the teacher code used to register.\n'
        '• Learning: class bookings, attendance, exercise and test answers and scores, '
        'teachers\' marks and notes, level history and progress reports.\n'
        '• Payments: invoices and vouchers (package, amount, status). Card or bank details '
        'are entered on Midtrans\'s payment page and are never stored by Easy Study.\n'
        '• Parents: the link between a parent account and a child.\n'
        '• Placement test visitors without an account: name, WhatsApp number and marks.\n'
        '• Device: a notification token when you allow notifications, and app settings '
        '(language, theme) kept on your device.'
  ),
  (
    'How we use it',
    'To run classes and bookings, mark exercises and tests, show progress to the student, '
        'their parent and their teacher, handle payments, and send notices about classes, '
        'results and the centre. We do not sell data, show advertising or use tracking '
        'or analytics tools.'
  ),
  (
    'Who can see it',
    'Admins of the centre see all data. Teachers see their own students. A parent sees '
        'their linked child. Other students see only your Chinese name on a test '
        'leaderboard. Staff may export a leaderboard (rank, name, marks, finish time) as a '
        'CSV or PDF file for the centre’s own records; a student may share their own result '
        'card, which shows no other student. The data is stored with Google Firebase (Google Cloud), with a backup copy on the '
        'centre’s own storage device, and payments '
        'are processed by Midtrans (PT Midtrans). Tools that read papers or recordings '
        'run on the computer of the person using them and send nothing elsewhere.'
  ),
  (
    'How long we keep it',
    'Your account is kept until you or the centre delete it. Invoices, test results and '
        'attendance are kept as the centre\'s records. Placement details of visitors who '
        'never register are cleared after 180 days. Backups are kept for 7 days.'
  ),
  (
    'Your choices',
    'You can change your profile and password in the app. Students and parents can delete '
        'their account in the app (Profile → Delete my account); this removes the sign-in '
        'and the profile for good. To get a copy of your data or to correct it, contact '
        'the centre.'
  ),
  (
    'Children',
    'Many students are children. A parent may link a parent account to follow their '
        'child. If you are a parent and want your child\'s account removed, contact the '
        'centre.'
  ),
  (
    'Changes',
    'We update this page when the app changes. The date at the top shows the latest '
        'version.'
  ),
];

const _id = <(String, String)>[
  (
    'Siapa kami',
    'Easy Study adalah aplikasi milik Easy Study (易华文教中心), pusat pendidikan Mandarin di '
        'Surabaya, Indonesia. Centre bertanggung jawab atas data di aplikasi ini. '
        'Kontak: $_contact'
  ),
  (
    'Data yang kami kumpulkan',
    '• Akun: nama (Latin dan Mandarin), alamat email, nomor WhatsApp, nama dan telepon '
        'orang tua atau wali bila diisi, peran (murid, orang tua, guru, admin), level HSK, '
        'dan kode guru yang dipakai saat mendaftar.\n'
        '• Belajar: pemesanan kelas, kehadiran, jawaban dan nilai latihan serta tes, '
        'nilai dan catatan guru, riwayat level, dan laporan perkembangan.\n'
        '• Pembayaran: tagihan dan voucher (paket, jumlah, status). Data kartu atau bank '
        'diisi di halaman pembayaran Midtrans dan tidak pernah disimpan oleh Easy Study.\n'
        '• Orang tua: hubungan antara akun orang tua dan anak.\n'
        '• Pengunjung tes penempatan tanpa akun: nama, nomor WhatsApp, dan nilai.\n'
        '• Perangkat: token notifikasi bila Anda mengizinkan notifikasi, dan pengaturan '
        'aplikasi (bahasa, tema) yang tersimpan di perangkat Anda.'
  ),
  (
    'Cara kami memakainya',
    'Untuk menjalankan kelas dan pemesanan, menilai latihan dan tes, menampilkan '
        'perkembangan kepada murid, orang tuanya, dan gurunya, mengurus pembayaran, serta '
        'mengirim pemberitahuan tentang kelas, hasil, dan centre. Kami tidak menjual data, '
        'tidak menampilkan iklan, dan tidak memakai alat pelacak atau analitik.'
  ),
  (
    'Siapa yang dapat melihatnya',
    'Admin centre melihat semua data. Guru melihat murid mereka sendiri. Orang tua '
        'melihat anak yang terhubung. Murid lain hanya melihat nama Mandarin Anda di papan '
        'peringkat tes. Staf dapat mengekspor papan peringkat (peringkat, nama, nilai, waktu '
        'selesai) sebagai berkas CSV atau PDF untuk catatan centre sendiri; murid dapat '
        'membagikan kartu hasilnya sendiri, yang tidak menampilkan murid lain. Data disimpan di Google Firebase (Google Cloud), dengan salinan cadangan di '
        'perangkat penyimpanan milik centre sendiri, dan pembayaran '
        'diproses oleh Midtrans (PT Midtrans). Alat pembaca kertas soal dan rekaman berjalan '
        'di komputer pemakainya dan tidak mengirim apa pun ke tempat lain.'
  ),
  (
    'Berapa lama kami menyimpannya',
    'Akun Anda disimpan sampai Anda atau centre menghapusnya. Tagihan, hasil tes, dan '
        'kehadiran disimpan sebagai catatan centre. Data tes penempatan pengunjung yang '
        'tidak pernah mendaftar dihapus setelah 180 hari. Cadangan data disimpan 7 hari.'
  ),
  (
    'Pilihan Anda',
    'Anda dapat mengubah profil dan kata sandi di aplikasi. Murid dan orang tua dapat '
        'menghapus akun mereka di aplikasi (Profil → Hapus akun saya); ini menghapus akses '
        'masuk dan profil untuk selamanya. Untuk meminta salinan data atau memperbaikinya, '
        'hubungi centre.'
  ),
  (
    'Anak-anak',
    'Banyak murid masih anak-anak. Orang tua dapat menghubungkan akun orang tua untuk '
        'mengikuti perkembangan anaknya. Bila Anda orang tua dan ingin akun anak Anda '
        'dihapus, hubungi centre.'
  ),
  (
    'Perubahan',
    'Kami memperbarui halaman ini bila aplikasi berubah. Tanggal di atas menunjukkan '
        'versi terbaru.'
  ),
];
