import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/paging/paged_controller.dart';
import '../../core/widgets/cohort_stats_widgets.dart';
import '../../l10n/l10n.dart';
import '../../models/cohort_report_models.dart';
import '../../models/lesson.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/list_pages_service.dart';

/// The teacher's Students tab. Build 9 part 2: active students by name, a
/// page at a time (the Users search index, so the search finds a student
/// who is not on the page); each row's numbers come from the student's
/// `progress_summary` (written by the functions) instead of six whole
/// collections streamed into the browser.
class TeacherStudentsTab extends StatefulWidget {
  const TeacherStudentsTab({super.key});

  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  late final FirestoreService _fs = context.read<FirestoreService>();
  late final ListPagesService _lists = ListPagesService(_fs);
  String _search = '';
  String? _level;
  Timer? _debounce;
  int? _attention;

  /// The viewer's own lesson library (small) for the "This term" column.
  Map<String, List<Lesson>> _lessons = const {};

  late final PagedController<StudentRosterSummary> _pages =
      PagedController<StudentRosterSummary>(
    autoLoad: false,
    build: (_) => _lists.studentRosterSource(
      search: _search,
      level: _level,
      l: context.l10n,
      lessonsByOwnerId: _lessons,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final user = context.read<AuthService>().appUser;
    final owner = user == null ? '' : AppConstants.contentOwnerFor(user);
    if (owner.isNotEmpty) {
      try {
        final lessons = await _fs.watchLessons(owner).first;
        _lessons = {owner: lessons};
      } catch (_) {
        // The lesson column is best-effort; the list still loads.
      }
    }
    if (!mounted) return;
    unawaited(_pages.reload());
    final n = await _lists.rosterAttentionCount();
    if (mounted) setState(() => _attention = n);
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_search == q.trim()) return;
      _search = q.trim();
      _pages.reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _pages,
      builder: (context, _) => StudentRosterList(
        controller: _pages,
        header: StudentRosterToolbar(
          levels: AppConstants.hskLevels,
          selectedLevel: _level,
          onLevel: (lv) {
            setState(() => _level = lv);
            _pages.reload();
          },
          onQuery: _onQuery,
          total: _pages.total,
          attention: _attention,
        ),
      ),
    );
  }
}
