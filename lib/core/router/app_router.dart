import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/landing/landing_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/test_login_screen.dart';
import '../../features/auth/complete_profile_screen.dart';
import '../../features/auth/waiting_approval_screen.dart';
import '../../features/legal/privacy_policy_page.dart';
import '../../features/admin/registration_approval_view.dart';
import '../../features/placement/placement_pages.dart';
import '../../features/progress/student_progress_report_screen.dart';
import '../../features/timetable/admin_timetable_screen.dart';
import '../../features/teaching/teacher_schedule_screen.dart';
import '../../models/placement.dart';
import '../../features/student/exercise_screen.dart';
import '../../features/student/lesson_detail_screen.dart';
import '../../models/quiz.dart';
import '../../features/student/quiz_screen.dart';
import '../../features/student/student_class_detail_screen.dart';
import '../../features/student/student_shell.dart';
import '../../features/admin/admin_dashboard_stat_detail_screen.dart';
import '../../features/admin/admin_create_user_screen.dart';
import '../../features/admin/admin_edit_user_screen.dart';
import '../../features/admin/admin_voucher_form_screen.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/admin/audit_logs_screen.dart';
import '../../features/admin/admin_price_list_screen.dart';
import '../../features/admin/org_settings_screen.dart';
import '../../features/calendar/class_calendar_screen.dart';
import '../../features/grades/transcript_view.dart';
import '../../features/materials/materials_screen.dart';
import '../../features/parent/parent_shell.dart';
import '../../features/question_bank/question_bank_screen.dart';
import '../../features/teacher/exercise_levels_screen.dart';
import '../../features/teacher/exercise_level_editor_screen.dart';
import '../../features/teacher/quiz_editor_screen.dart';
import '../../features/teacher/teacher_dashboard_stat_detail_screen.dart';
import '../../features/teacher/teacher_grades_tab.dart';
import '../../features/teacher/teacher_shell.dart';
import '../../features/teacher/exercise_package_form_screen.dart';
import '../../features/teacher/teacher_exercise_form_screen.dart';
import '../../features/teacher/student_detail_screen.dart';
import '../../features/teaching/class_detail_page.dart';
import '../../features/admin/user_profile_pages.dart';
import '../../features/teacher/teacher_session_form_screen.dart';
import '../../features/tests/leaderboard_screen.dart';
import '../../features/tests/marking_screen.dart';
import '../../features/tests/promotion_screen.dart';
import '../../features/tests/test_codes_screen.dart';
import '../../features/tests/test_formats_screen.dart';
import '../../features/tests/test_player_screen.dart';
import '../../features/tests/test_results_screen.dart';
import '../../features/tests/test_review_screen.dart';
import '../../features/tests/test_supervision_screen.dart';
import '../../models/admin_dashboard_stat_kind.dart';
import '../../models/class_session.dart';
import '../../models/app_user.dart';
import '../../features/progress/progress_attention_list.dart';
import '../../l10n/l10n.dart';
import '../widgets/shell_nested_page.dart';
import '../../models/dashboard_stat_routes.dart';
import '../../models/exercise.dart';
import '../../models/teacher_dashboard_stat_kind.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';

class AppRouter {
  static GoRouter create(BuildContext context) {
    final auth = context.read<AuthService>();

    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final location = state.matchedLocation;
        // Hold on the splash while the profile loads, remembering where the
        // user was headed so deep links and browser refreshes land there.
        if (auth.isInitializing) {
          if (location == '/splash') return null;
          return Uri(
            path: '/splash',
            queryParameters: {'from': state.uri.toString()},
          ).toString();
        }
        if (location == '/splash') {
          final from = state.uri.queryParameters['from'];
          final safe = from != null &&
              from.startsWith('/') &&
              !from.startsWith('//') &&
              !from.startsWith('/splash');
          return safe ? from : '/';
        }

        final signedIn = auth.firebaseUser != null;
        final hasProfile = auth.appUser != null;
        final onPublic = location == '/' ||
            location == '/login' ||
            location == '/register' ||
            location == '/splash' ||
            (kDebugMode && location == '/dev-login');
        final onComplete = location == '/complete-profile';
        // Build 3: the public placement test works signed in or not.
        final onPlacement =
            location == '/placement' || location.startsWith('/placement/');
        if (onPlacement) return null;
        // Owner 2026-11-24: the privacy policy is public (App Store).
        if (location == '/privacy') return null;
        final onWaiting = location == '/waiting';

        if (!signedIn && !onPublic) return '/';
        if (signedIn && !hasProfile && !onComplete) {
          // Mid sign-in the auth user exists before the profile is loaded;
          // wait for AuthService to notify instead of redirecting.
          return auth.isProfileLoading ? null : '/complete-profile';
        }

        if (signedIn && hasProfile) {
          final user = auth.appUser!;
          // Build 3: a pending or rejected student sees only the waiting
          // page (the rules refuse everything else too).
          if (user.awaitsApproval) return onWaiting ? null : '/waiting';
          if (onWaiting) return null; // falls to home below
          String homeFor(dynamic u) {
            if (u.isAdmin) return '/admin';
            if (u.isTeacher) return '/teacher';
            if (u.isParent) return '/parent';
            return '/student';
          }

          final home = homeFor(user);
          // Keep each role within its own section.
          final inOtherSection = (location.startsWith('/admin') ||
                  location.startsWith('/teacher') ||
                  location.startsWith('/student') ||
                  location.startsWith('/parent')) &&
              !location.startsWith(home);
          if (inOtherSection) return home;

          if (onPublic || onComplete || onWaiting) {
            return home;
          }

          final authoringRedirect =
              ExerciseAuthoringPlatform.redirectFromAuthoringRoute(
            location,
            user,
          );
          if (authoringRedirect != null) return authoringRedirect;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const LandingScreen(),
        ),
        GoRoute(
          path: '/splash',
          builder: (_, __) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, state) => RegisterScreen(
            initialResultCode: state.uri.queryParameters['placement'],
          ),
        ),
        GoRoute(
          path: '/waiting',
          builder: (_, __) => const WaitingApprovalScreen(),
        ),
        GoRoute(
          path: '/privacy',
          builder: (_, __) => const PrivacyPolicyPage(),
        ),
        // Build 3: the public placement test (no account).
        GoRoute(
          path: '/placement',
          builder: (_, state) => PlacementHomePage(
            initialToken: state.uri.queryParameters['token'],
          ),
        ),
        GoRoute(
          path: '/placement/test',
          builder: (_, state) => PlacementTestPage(
            start: state.extra is PlacementStart
                ? state.extra! as PlacementStart
                : null,
          ),
        ),
        GoRoute(
          path: '/placement/result',
          builder: (_, state) => PlacementResultPage(
            result: state.extra is VisitorResult
                ? state.extra! as VisitorResult
                : null,
          ),
        ),
        if (kDebugMode)
          GoRoute(
            path: '/dev-login',
            builder: (_, __) => const TestLoginScreen(),
          ),
        GoRoute(
          path: '/complete-profile',
          builder: (_, __) => const CompleteProfileScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (_, __) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: 'dashboard/stat/:kind',
                  builder: (_, state) {
                    final slug = state.pathParameters['kind']!;
                    final adminKind =
                        AdminDashboardStatKind.fromRouteSlug(slug);
                    if (adminKind != null) {
                      return AdminDashboardStatDetailScreen(
                        kind: adminKind,
                        embedded: true,
                      );
                    }
                    final centreKind =
                        TeacherDashboardStatKind.fromRouteSlug(slug);
                    if (centreKind != null) {
                      return TeacherDashboardStatDetailScreen(
                        kind: centreKind,
                        embedded: true,
                        routes: DashboardStatRoutes.admin,
                      );
                    }
                    return const Scaffold(
                      body: Center(child: Text('Unknown dashboard stat')),
                    );
                  },
                ),
                GoRoute(
                  path: 'users/new',
                  builder: (_, __) =>
                      const AdminCreateUserScreen(embedded: true),
                ),
                GoRoute(
                  path: 'timetable',
                  builder: (_, state) => AdminTimetableScreen(
                    embedded: true,
                    initialView:
                        state.uri.queryParameters['view'] == 'followup' ? 3 : 0,
                  ),
                ),
                GoRoute(
                  path: 'attention',
                  builder: (context, _) => ShellNestedPage(
                    embedded: true,
                    title: context.l10n.dutyAttention,
                    child: StreamBuilder<List<AppUser>>(
                      stream: context.read<FirestoreService>().watchAllTeachers(),
                      builder: (context, t) => ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ProgressAttentionList(teachers: t.data ?? const []),
                        ],
                      ),
                    ),
                  ),
                ),
                GoRoute(
                  path: 'users/approval',
                  builder: (_, __) =>
                      const RegistrationApprovalPage(embedded: true),
                ),
                GoRoute(
                  path: 'users/:id/edit',
                  builder: (_, state) => AdminEditUserScreen(
                    userId: state.pathParameters['id']!,
                    embedded: true,
                  ),
                ),
                // One page per student: profile, vouchers, payments,
                // attendance, evaluations, practice results, progress.
                GoRoute(
                  path: 'users/:id/progress',
                  builder: (_, state) => StudentProgressReportScreen(
                    studentId: state.pathParameters['id']!,
                    embedded: true,
                    page: true,
                  ),
                ),
                GoRoute(
                  path: 'users/:id',
                  builder: (_, state) => UserProfileRoute(
                    userId: state.pathParameters['id']!,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'vouchers/new',
                  builder: (_, __) =>
                      const AdminVoucherFormScreen(embedded: true),
                ),
                GoRoute(
                  path: 'vouchers/:id/edit',
                  builder: (_, state) => AdminVoucherFormScreen(
                    termId: state.pathParameters['id'],
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'exercise/new',
                  builder: (context, state) {
                    final user = auth.appUser!;
                    final extra = state.extra;
                    // New exercises are packages built from the bank. A
                    // worksheet just scanned arrives as its sheet codes.
                    return ExercisePackageFormScreen(
                      teacherId: AppConstants.contentTeacherId(user),
                      embedded: true,
                      initialSheets:
                          extra is List<String> ? extra : const <String>[],
                    );
                  },
                ),
                GoRoute(
                  path: 'exercise/:id/edit',
                  builder: (context, state) {
                    final user = auth.appUser!;
                    final exercise = state.extra as Exercise?;
                    if (exercise != null && exercise.isPackage) {
                      return ExercisePackageFormScreen(
                        teacherId: AppConstants.contentTeacherId(user),
                        exercise: exercise,
                        embedded: true,
                      );
                    }
                    // Older exercises keep their questions inside the
                    // document and the original editor.
                    return TeacherExerciseFormScreen(
                      teacherId: AppConstants.contentTeacherId(user),
                      exercise: exercise,
                      embedded: true,
                    );
                  },
                ),
                GoRoute(
                  path: 'session/new',
                  builder: (context, state) {
                    final user = auth.appUser!;
                    return TeacherSessionFormScreen(
                      teacherId: AppConstants.contentTeacherId(user),
                      initialDate: DateTime.tryParse(
                        state.uri.queryParameters['date'] ?? '',
                      ),
                      embedded: true,
                    );
                  },
                ),
                GoRoute(
                  path: 'session/:id',
                  builder: (context, state) => ClassDetailPage(
                    sessionId: state.pathParameters['id']!,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'question-bank',
                  builder: (_, __) => const QuestionBankScreen(embedded: true),
                ),
                GoRoute(
                  path: 'levels',
                  builder: (_, __) =>
                      const ExerciseLevelsScreen(embedded: true),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) =>
                          const ExerciseLevelEditorScreen(embedded: true),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (_, state) => ExerciseLevelEditorScreen(
                        embedded: true,
                        levelId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'quizzes',
                  builder: (_, __) => const QuizListScreen(embedded: true),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) =>
                          const QuizEditorScreen(embedded: true),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (_, state) => QuizEditorScreen(
                        embedded: true,
                        existing: state.extra as Quiz?,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'settings',
                  builder: (_, __) => const OrgSettingsScreen(embedded: true),
                ),
                GoRoute(
                  path: 'price-list',
                  builder: (_, __) =>
                      const AdminPriceListScreen(embedded: true),
                ),
                GoRoute(
                  path: 'audit-logs',
                  builder: (_, __) => const AuditLogsScreen(embedded: true),
                ),
                // Supervised tests (Build 1).
                GoRoute(
                  path: 'tests/formats',
                  builder: (_, __) =>
                      const TestFormatsScreen(embedded: true),
                ),
                GoRoute(
                  path: 'tests/codes',
                  builder: (_, __) => const TestCodesScreen(embedded: true),
                ),
                GoRoute(
                  path: 'tests/codes/new',
                  builder: (_, state) => TestCodeFormScreen(
                    initialSheet: state.uri.queryParameters['sheet'],
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/codes/:id/edit',
                  builder: (_, state) => TestCodeFormScreen(
                    editId: state.pathParameters['id']!,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/supervise/:id',
                  builder: (_, state) => TestSupervisionScreen(
                    sessionId: state.pathParameters['id']!,
                    basePath: '/admin/tests',
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/marking',
                  builder: (context, _) =>
                      MarkingScreen(user: auth.appUser!, embedded: true),
                ),
                // Build 2B: promotion recommendations and leaderboards.
                GoRoute(
                  path: 'tests/promotion',
                  builder: (_, __) => const PromotionScreen(embedded: true),
                ),
                GoRoute(
                  path: 'tests/leaderboard/:codeId',
                  builder: (_, state) => LeaderboardScreen(
                    codeId: state.pathParameters['codeId']!,
                    staff: true,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/results',
                  builder: (_, state) => TestResultsScreen(
                    basePath: '/admin/tests',
                    codeId: state.uri.queryParameters['code'],
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/result/:id',
                  builder: (_, state) => TestResultScreen(
                    resultId: state.pathParameters['id']!,
                    staff: true,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'materials',
                  builder: (context, _) {
                    final user = auth.appUser!;
                    return MaterialsScreen(
                      ownerId: AppConstants.contentOwnerFor(user),
                      embedded: true,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => TeacherShell(child: child),
          routes: [
            GoRoute(
              path: '/teacher',
              builder: (_, __) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: 'student/:id/progress',
                  builder: (_, state) => StudentProgressReportScreen(
                    studentId: state.pathParameters['id']!,
                    embedded: true,
                    page: true,
                  ),
                ),
                GoRoute(
                  path: 'student/:id',
                  builder: (_, state) => StudentDetailScreen(
                    studentId: state.pathParameters['id']!,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'dashboard/stat/:kind',
                  builder: (_, state) {
                    final kind = TeacherDashboardStatKind.fromRouteSlug(
                      state.pathParameters['kind']!,
                    );
                    if (kind == null) {
                      return const Scaffold(
                        body: Center(child: Text('Unknown dashboard stat')),
                      );
                    }
                    return TeacherDashboardStatDetailScreen(
                      kind: kind,
                      embedded: true,
                    );
                  },
                ),
                GoRoute(
                  path: 'exercise/new',
                  builder: (context, _) => ExercisePackageFormScreen(
                    teacherId: auth.appUser!.uid,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'exercise/:id/edit',
                  builder: (context, state) {
                    final exercise = state.extra as Exercise?;
                    if (exercise != null && exercise.isPackage) {
                      return ExercisePackageFormScreen(
                        teacherId: auth.appUser!.uid,
                        exercise: exercise,
                        embedded: true,
                      );
                    }
                    return TeacherExerciseFormScreen(
                      teacherId: auth.appUser!.uid,
                      exercise: exercise,
                      embedded: true,
                    );
                  },
                ),
                GoRoute(
                  path: 'session/new',
                  builder: (context, state) => TeacherSessionFormScreen(
                    teacherId: auth.appUser!.uid,
                    initialDate: DateTime.tryParse(
                      state.uri.queryParameters['date'] ?? '',
                    ),
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'session/:id/edit',
                  builder: (context, state) => TeacherSessionFormScreen(
                    teacherId: auth.appUser!.uid,
                    session: state.extra as ClassSession?,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'session/:id',
                  builder: (context, state) => ClassDetailPage(
                    sessionId: state.pathParameters['id']!,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'schedule',
                  builder: (_, __) => const TeacherScheduleScreen(),
                ),
                GoRoute(
                  path: 'calendar',
                  builder: (context, _) {
                    final user = auth.appUser!;
                    final firestore = context.read<FirestoreService>();
                    return ClassCalendarScreen(
                      title: 'Calendar',
                      showAppBar: false,
                      sessions: firestore.watchTeacherSessions(user.uid),
                      onTapSession: (s) =>
                          context.push('/teacher/session/${s.id}'),
                    );
                  },
                ),
                GoRoute(
                  path: 'grades',
                  builder: (_, __) => const TeacherGradesTab(),
                ),
                GoRoute(
                  path: 'question-bank',
                  builder: (_, __) => const QuestionBankScreen(embedded: true),
                ),
                GoRoute(
                  path: 'levels',
                  builder: (_, __) =>
                      const ExerciseLevelsScreen(embedded: true),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) =>
                          const ExerciseLevelEditorScreen(embedded: true),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (_, state) => ExerciseLevelEditorScreen(
                        embedded: true,
                        levelId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'quizzes',
                  builder: (_, __) => const QuizListScreen(embedded: true),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) =>
                          const QuizEditorScreen(embedded: true),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (_, state) => QuizEditorScreen(
                        embedded: true,
                        existing: state.extra as Quiz?,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'materials',
                  builder: (context, _) {
                    final user = auth.appUser!;
                    return MaterialsScreen(
                      ownerId: AppConstants.contentOwnerFor(user),
                      embedded: true,
                    );
                  },
                ),
                // Supervised tests (Build 1).
                GoRoute(
                  path: 'tests/supervise/:id',
                  builder: (_, state) => TestSupervisionScreen(
                    sessionId: state.pathParameters['id']!,
                    basePath: '/teacher/tests',
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/marking',
                  builder: (context, _) =>
                      MarkingScreen(user: auth.appUser!, embedded: true),
                ),
                GoRoute(
                  path: 'tests/leaderboard/:codeId',
                  builder: (_, state) => LeaderboardScreen(
                    codeId: state.pathParameters['codeId']!,
                    staff: true,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/results',
                  builder: (_, state) => TestResultsScreen(
                    basePath: '/teacher/tests',
                    codeId: state.uri.queryParameters['code'],
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'tests/result/:id',
                  builder: (_, state) => TestResultScreen(
                    resultId: state.pathParameters['id']!,
                    staff: true,
                    embedded: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/student',
          builder: (_, __) => const StudentShell(),
          routes: [
            GoRoute(
              path: 'class/:sessionId',
              builder: (context, state) => StudentClassDetailScreen(
                sessionId: state.pathParameters['sessionId']!,
                student: auth.appUser!,
              ),
            ),
            GoRoute(
              path: 'exercise/:id',
              builder: (_, state) => ExerciseScreen(
                exerciseId: state.pathParameters['id']!,
              ),
            ),
            // Supervised tests (Build 1).
            GoRoute(
              path: 'test',
              builder: (_, state) => TestPlayerScreen(
                token: state.uri.queryParameters['token'],
                codeId: state.uri.queryParameters['code'],
              ),
            ),
            GoRoute(
              path: 'test-result/:id',
              builder: (_, state) => TestResultScreen(
                resultId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'test-leaderboard/:codeId',
              builder: (_, state) => LeaderboardScreen(
                codeId: state.pathParameters['codeId']!,
              ),
            ),
            GoRoute(
              path: 'test-review/:codeId',
              builder: (_, state) => TestReviewScreen(
                codeId: state.pathParameters['codeId']!,
              ),
            ),
            GoRoute(
              path: 'lesson/:id',
              builder: (_, state) => LessonDetailScreen(
                lessonId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: 'quiz/:lessonId',
              builder: (_, state) => QuizScreen(
                lessonId: state.pathParameters['lessonId']!,
              ),
            ),
            GoRoute(
              path: 'calendar',
              builder: (context, _) {
                final user = auth.appUser!;
                final firestore = context.read<FirestoreService>();
                final ownerId = AppConstants.contentOwnerFor(user);
                return ClassCalendarScreen(
                  title: 'Calendar',
                  sessions: firestore.watchTeacherSessions(ownerId),
                  onTapSession: (s) => context.push('/student/class/${s.id}'),
                );
              },
            ),
            GoRoute(
              path: 'grades',
              builder: (_, __) => Scaffold(
                backgroundColor: AppColors.surface,
                appBar: AppBar(
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.navy,
                  elevation: 0,
                  title: const Text(
                    'Grades',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                body: TranscriptView(studentId: auth.appUser!.uid),
              ),
            ),
            GoRoute(
              path: 'materials',
              builder: (context, _) {
                final user = auth.appUser!;
                return MaterialsScreen(
                  ownerId: AppConstants.contentOwnerFor(user),
                  readOnly: true,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/parent',
          builder: (_, __) => const ParentShell(),
          routes: [
            GoRoute(
              path: 'calendar/:childId',
              builder: (context, state) {
                final firestore = context.read<FirestoreService>();
                final parent = auth.appUser!;
                final childId = state.pathParameters['childId'];
                // A parent may only open a calendar for a linked child.
                if (childId == null || !parent.studentIds.contains(childId)) {
                  return ClassCalendarScreen(
                    title: 'Calendar',
                    sessions: Stream.value(const []),
                  );
                }
                return ClassCalendarScreen(
                  title: 'Calendar',
                  sessions: _parentChildSessions(context, firestore, childId),
                );
              },
            ),
            GoRoute(
              path: 'grades/:childId',
              builder: (context, state) {
                final parent = auth.appUser!;
                final childId = state.pathParameters['childId'];
                // A parent may only open a transcript for a linked child.
                if (childId == null || !parent.studentIds.contains(childId)) {
                  return const Scaffold(
                    body: Center(child: Text('Not available.')),
                  );
                }
                return Scaffold(
                  backgroundColor: AppColors.surface,
                  appBar: AppBar(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.navy,
                    elevation: 0,
                    title: const Text(
                      'Grades',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  body: TranscriptView(studentId: childId),
                );
              },
            ),
            GoRoute(
              path: 'materials/:childId',
              builder: (context, state) {
                final firestore = context.read<FirestoreService>();
                final parent = auth.appUser!;
                final childId = state.pathParameters['childId'];
                if (childId == null || !parent.studentIds.contains(childId)) {
                  return const Scaffold(
                    body: Center(child: Text('Not available.')),
                  );
                }
                return FutureBuilder(
                  future: firestore.getUser(childId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final child = snap.data;
                    if (child == null) {
                      return const Scaffold(
                        body: Center(child: Text('Not available.')),
                      );
                    }
                    return MaterialsScreen(
                      ownerId: AppConstants.contentOwnerFor(child),
                      readOnly: true,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  static Stream<List<ClassSession>> _parentChildSessions(
    BuildContext context,
    FirestoreService firestore,
    String? childId,
  ) {
    if (childId == null || childId.isEmpty) return Stream.value(const []);
    // Resolve the child's teacher, then stream that teacher's sessions.
    return firestore
        .watchUsersByIds([childId])
        .map((users) => users.isNotEmpty ? users.first : null)
        .asyncExpand((child) {
          if (child == null) return Stream.value(<ClassSession>[]);
          return firestore
              .watchTeacherSessions(AppConstants.contentOwnerFor(child));
        });
  }
}
