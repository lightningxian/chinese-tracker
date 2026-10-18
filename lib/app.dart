import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/build_flags.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/worksheet_import_service.dart';
import 'services/saved_accounts_service.dart';
import 'services/student_report_service.dart';
import 'services/cohort_report_service.dart';
import 'services/admin_report_export_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/materials_storage_service.dart';
import 'services/question_bank_media_service.dart';

class ChineseTrackerApp extends StatefulWidget {
  const ChineseTrackerApp({super.key});

  @override
  State<ChineseTrackerApp> createState() => _ChineseTrackerAppState();
}

class _ChineseTrackerAppState extends State<ChineseTrackerApp> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final SavedAccountsService _savedAccountsService;
  late final WorksheetImportService _worksheetImportService;
  late final StudentReportService _studentReportService;
  late final CohortReportService _cohortReportService;
  late final AdminReportExportService _adminReportExportService;
  late final NotificationService _notificationService;
  late final PaymentService _paymentService;
  late final MaterialsStorageService _materialsStorageService;
  late final QuestionBankMediaService _questionBankMediaService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _firestoreService = FirestoreService();
    _savedAccountsService = SavedAccountsService();
    _worksheetImportService = WorksheetImportService();
    _studentReportService = StudentReportService(firestore: _firestoreService);
    _cohortReportService = CohortReportService(firestore: _firestoreService);
    _adminReportExportService =
        AdminReportExportService(firestore: _firestoreService);
    _notificationService =
        NotificationService(firestore: _firestoreService);
    _paymentService = PaymentService();
    _materialsStorageService = MaterialsStorageService();
    _questionBankMediaService = QuestionBankMediaService();
    _authService.init();
    _savedAccountsService.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<SavedAccountsService>.value(
          value: _savedAccountsService,
        ),
        Provider<FirestoreService>.value(value: _firestoreService),
        Provider<WorksheetImportService>.value(value: _worksheetImportService),
        Provider<StudentReportService>.value(value: _studentReportService),
        Provider<CohortReportService>.value(value: _cohortReportService),
        Provider<AdminReportExportService>.value(
          value: _adminReportExportService,
        ),
        Provider<NotificationService>.value(value: _notificationService),
        Provider<PaymentService>.value(value: _paymentService),
        Provider<MaterialsStorageService>.value(
          value: _materialsStorageService,
        ),
        Provider<QuestionBankMediaService>.value(
          value: _questionBankMediaService,
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.create(context);
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.light(),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final scaled = MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.12),
                ),
                child: child ?? const SizedBox.shrink(),
              );
              if (!BuildFlags.useEmulators) return scaled;
              // Loud reminder that this build talks to local emulators, so a
              // stale production bundle is never mistaken for it.
              return Banner(
                message: 'EMULATOR',
                location: BannerLocation.topStart,
                color: const Color(0xFFB53A3A),
                child: scaled,
              );
            },
          );
        },
      ),
    );
  }
}
