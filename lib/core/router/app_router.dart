import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/landing/landing_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/test_login_screen.dart';
import '../../features/auth/complete_profile_screen.dart';
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
import '../../features/teacher/worksheet_import_review_screen.dart';
import '../../features/teacher/exercise_level_editor_screen.dart';
import '../../features/teacher/quiz_editor_screen.dart';
import '../../features/teacher/teacher_dashboard_stat_detail_screen.dart';
import '../../features/teacher/teacher_grades_tab.dart';
import '../../features/teacher/teacher_shell.dart';
import '../../features/teacher/teacher_exercise_form_screen.dart';
import '../../features/teacher/student_detail_screen.dart';
import '../../features/teacher/teacher_session_detail_screen.dart';
import '../../features/teacher/teacher_session_form_screen.dart';
import '../../models/admin_dashboard_stat_kind.dart';
import '../../models/class_session.dart';
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

        if (!signedIn && !onPublic) return '/';
        if (signedIn && !hasProfile && !onComplete) {
          // Mid sign-in the auth user exists before the profile is loaded;
          // wait for AuthService to notify instead of redirecting.
          return auth.isProfileLoading ? null : '/complete-profile';
        }

        if (signedIn && hasProfile) {
          final user = auth.appUser!;
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

          if (onPublic || onComplete) {
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
          builder: (_, __) => const RegisterScreen(),
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
                  path: 'users/:id/edit',
                  builder: (_, state) => AdminEditUserScreen(
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
                    return TeacherExerciseFormScreen(
                      teacherId: AppConstants.contentTeacherId(user),
                      embedded: true,
                      initialImport: extra is WorksheetImportReviewResult
                          ? extra
                          : null,
                    );
                  },
                ),
                GoRoute(
                  path: 'exercise/:id/edit',
                  builder: (context, state) {
                    final user = auth.appUser!;
                    return TeacherExerciseFormScreen(
                      teacherId: AppConstants.contentTeacherId(user),
                      exercise: state.extra as Exercise?,
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
                  builder: (context, state) => TeacherSessionDetailScreen(
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
                  builder: (context, _) => TeacherExerciseFormScreen(
                    teacherId: auth.appUser!.uid,
                    embedded: true,
                  ),
                ),
                GoRoute(
                  path: 'exercise/:id/edit',
                  builder: (context, state) => TeacherExerciseFormScreen(
                    teacherId: auth.appUser!.uid,
                    exercise: state.extra as Exercise?,
                    embedded: true,
                  ),
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
                  builder: (context, state) => TeacherSessionDetailScreen(
                    sessionId: state.pathParameters['id']!,
                    embedded: true,
                  ),
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
