import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/build_flags.dart';
import 'l10n/l10n.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/worksheet_import_service.dart';
import 'services/saved_accounts_service.dart';
import 'services/student_report_service.dart';
import 'services/cohort_report_service.dart';
import 'services/admin_report_export_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/push_service.dart';
import 'services/materials_storage_service.dart';
import 'services/question_bank_media_service.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';

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
  late final PushService _pushService;
  late final MaterialsStorageService _materialsStorageService;
  late final QuestionBankMediaService _questionBankMediaService;
  late final LocaleController _localeController;
  late final ThemeController _themeController;

  /// Lets a push message that arrives while the app is in front show as a
  /// SnackBar from outside the widget tree.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _showForegroundPush() {
    final notification = _pushService.foregroundMessage.value?.notification;
    if (notification == null) return;
    final title = notification.title ?? '';
    final body = notification.body ?? '';
    final text = [title, body].where((s) => s.trim().isNotEmpty).join('\n');
    if (text.isEmpty) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
  }

  @override
  void dispose() {
    _pushService.foregroundMessage.removeListener(_showForegroundPush);
    super.dispose();
  }

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
    _notificationService = NotificationService(firestore: _firestoreService);
    _paymentService = PaymentService();
    _pushService = PushService();
    _pushService.foregroundMessage.addListener(_showForegroundPush);
    _pushService.init();
    _materialsStorageService = MaterialsStorageService();
    _questionBankMediaService = QuestionBankMediaService();
    _localeController = LocaleController();
    _themeController = ThemeController();
    _authService.init();
    _savedAccountsService.load();
    _localeController.load();
    _themeController.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<SavedAccountsService>.value(
          value: _savedAccountsService,
        ),
        ChangeNotifierProvider<LocaleController>.value(
          value: _localeController,
        ),
        ChangeNotifierProvider<ThemeController>.value(
          value: _themeController,
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
        ChangeNotifierProvider<PushService>.value(value: _pushService),
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
          // Only the app rebuilds on a language or theme change; the router
          // (and so the current page) is kept.
          return Consumer2<LocaleController, ThemeController>(
            builder: (context, localeController, themeController, _) =>
                MaterialApp.router(
              title: AppConstants.appName,
              scaffoldMessengerKey: _messengerKey,
              // Light / Dark / Device (ThemeController). The palette behind
              // `AppColors` is swapped by the controller before this rebuild.
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeController.mode,
              // UI language: ID | EN toggle (LocaleController). Student, parent
              // and sign-in screens are translated; admin/teacher stay English.
              locale: localeController.locale,
              supportedLocales: LocaleController.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final scaled = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler:
                        TextScaler.linear(themeController.textSize.scale),
                  ),
                  // Screens read their colours through `AppColors`, not
                  // through Theme.of, so a mode change does not reach them
                  // by itself. A new key remounts the page tree in the new
                  // colours; the router keeps the current route.
                  child: KeyedSubtree(
                    key: ValueKey('theme-${themeController.brightness.name}'),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
                if (BuildFlags.useEmulators) {
                  // Loud reminder that this build talks to local emulators, so
                  // a stale production bundle is never mistaken for it.
                  return Banner(
                    message: 'EMULATOR',
                    location: BannerLocation.topStart,
                    color: const Color(0xFFB53A3A),
                    child: scaled,
                  );
                }
                // The opposite mistake: a live bundle served from a local dev
                // server (flutter run, or build/web rebuilt by the deploy
                // script under a running web-server) talks to the LIVE
                // database. Say so.
                final host = Uri.base.host;
                if (host == 'localhost' || host == '127.0.0.1') {
                  return Banner(
                    message: 'LIVE DATA',
                    location: BannerLocation.topStart,
                    color: const Color(0xFF8A5A12),
                    child: scaled,
                  );
                }
                return scaled;
              },
            ),
          );
        },
      ),
    );
  }
}
