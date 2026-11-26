import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/constants/app_constants.dart';
import '../core/paging/date_range.dart';
import '../core/paging/paged_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/class_session.dart';
import '../models/exercise.dart';
import '../models/exercise_assignment.dart';
import '../models/exercise_result.dart';
import '../models/student_class_term.dart';
import '../models/student_progress.dart';
import '../models/teacher_activity_event.dart';
import '../models/cohort_report_models.dart';
import '../models/lesson.dart';
import '../models/question_bank_item.dart';
import '../models/roster_row.dart';
import 'firestore_service.dart';

/// Build 9 part 2 (supervisor 2026-11-25): the page sources of the heavy
/// lists — the teacher's Students tab, the dashboard drill-downs, the
/// packages, the question bank, the History timeline, Grades, the
/// transcript and the Timetable follow-up. Every source reads one page (or
/// a bounded range); counts and averages come from count / sum
/// aggregations or from the documents the functions keep
/// (`progress_summary.roster`, `bank_sheets`, the assignment stamps).
class ListPagesService {
  ListPagesService(this._fs, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirestoreService _fs;
  final FirebaseFirestore _db;

  static const summaryCollection = 'progress_summary';

  // ------------------------------------------------------------ students

  /// The `progress_summary` documents of [ids] (missing ones are absent).
  Future<Map<String, Map<String, dynamic>>> progressSummaries(
      List<String> ids) async {
    final out = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, (i + 30).clamp(0, ids.length));
      final snap = await _db
          .collection(summaryCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        out[d.id] = d.data();
      }
    }
    return out;
  }

  /// The Students tab: active students by name a page at a time (the
  /// Users search index), each page joined with its 25 summaries.
  PageSource<StudentRosterSummary> studentRosterSource({
    String search = '',
    String? level,
    AppLocalizations? l,
    Map<String, List<Lesson>> lessonsByOwnerId = const {},
  }) {
    final users = _fs.userSource(_fs.userListQuery(
      role: AppConstants.roleStudent,
      active: true,
      search: search,
      level: level,
    ));
    return MappedPageSource<AppUser, StudentRosterSummary>(users,
        (page) async {
      final sums = await progressSummaries([for (final u in page) u.uid]);
      return [
        for (final u in page)
          RosterRow.fromSummary(u.uid, sums[u.uid], student: u)
              .toSummary(l: l, lessonsByOwnerId: lessonsByOwnerId),
      ];
    });
  }

  /// Students listed on the summaries (active and approved).
  Query<Map<String, dynamic>> get _listedSummaries =>
      _db.collection(summaryCollection).where('listed', isEqualTo: true);

  /// How many listed students need attention (few sessions or late work).
  Future<int?> rosterAttentionCount() async {
    try {
      final agg = await _listedSummaries
          .where('roster.needsAttention', isEqualTo: true)
          .count()
          .get();
      return agg.count;
    } catch (_) {
      return null;
    }
  }

  /// A drill-down over the summaries, ordered by [orderBy] (a roster field
  /// or `nameLower`), optionally from [minMs] on (activity).
  PageSource<RosterRow> summarySource({
    String orderBy = 'nameLower',
    bool descending = false,
    bool notNull = false,
    bool attentionOnly = false,
    int? minMs,
  }) {
    var q = _listedSummaries;
    if (attentionOnly) q = q.where('roster.hasAttention', isEqualTo: true);
    if (minMs != null) q = q.where(orderBy, isGreaterThanOrEqualTo: minMs);
    if (notNull && minMs == null) q = q.where(orderBy, isNotEqualTo: null);
    q = q.orderBy(orderBy, descending: descending);
    if (orderBy != 'nameLower') q = q.orderBy('nameLower');
    return FirestorePageSource(
        q, (d) => RosterRow.fromSummary(d.id, d.data()));
  }

  /// Lessons of each content owner of [rows], read once per owner and
  /// kept in [cache] (the "This term" column; libraries are small).
  Future<Map<String, List<Lesson>>> lessonsFor(
      Iterable<AppUser> students, Map<String, List<Lesson>> cache) async {
    for (final s in students) {
      final owner = AppConstants.contentOwnerFor(s);
      if (owner.isEmpty || cache.containsKey(owner)) continue;
      try {
        cache[owner] = await _fs.watchLessons(owner).first;
      } catch (_) {
        cache[owner] = const [];
      }
    }
    return cache;
  }

  // ------------------------------------------------------------ joins

  /// Accounts by id (for the names on one page).
  Future<Map<String, AppUser>> usersById(Iterable<String> ids) async {
    final list = ids.where((id) => id.isNotEmpty).toSet().toList();
    final out = <String, AppUser>{};
    for (var i = 0; i < list.length; i += 30) {
      final snap = await _db
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId,
              whereIn: list.sublist(i, (i + 30).clamp(0, list.length)))
          .get();
      for (final d in snap.docs) {
        out[d.id] = AppUser.fromFirestore(d);
      }
    }
    return out;
  }

  /// Exercises by id (titles on one page).
  Future<Map<String, Exercise>> exercisesById(Iterable<String> ids) async {
    final list = ids.where((id) => id.isNotEmpty).toSet().toList();
    final out = <String, Exercise>{};
    for (var i = 0; i < list.length; i += 30) {
      final snap = await _db
          .collection(AppConstants.exercisesCollection)
          .where(FieldPath.documentId,
              whereIn: list.sublist(i, (i + 30).clamp(0, list.length)))
          .get();
      for (final d in snap.docs) {
        out[d.id] = Exercise.fromFirestore(d);
      }
    }
    return out;
  }

  // ------------------------------------------------------------ homework

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _db.collection(AppConstants.exerciseAssignmentsCollection);

  /// Start of today (device day, as `ExerciseAssignment.isOverdue`).
  static DateTime get _todayStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Assignments for the homework drill-downs, a page at a time. The
  /// `done` / `bestScore` stamps are written by the summary refresh
  /// (functions), so "done" and "overdue" are queries.
  PageSource<HomeworkOverviewRow> homeworkSource(HomeworkView view) {
    Query<Map<String, dynamic>> q = _assignments;
    switch (view) {
      case HomeworkView.all:
        q = q.orderBy('assignedAt', descending: true);
      case HomeworkView.done:
        q = q
            .where('done', isEqualTo: true)
            .orderBy('assignedAt', descending: true);
      case HomeworkView.overdue:
        q = q
            .where('done', isEqualTo: false)
            .where('dueDate', isLessThan: Timestamp.fromDate(_todayStart))
            .orderBy('dueDate');
    }
    final raw = FirestorePageSource<ExerciseAssignment>(
        q, ExerciseAssignment.fromFirestore);
    return MappedPageSource<ExerciseAssignment, HomeworkOverviewRow>(raw,
        (page) async {
      final users = await usersById(page.map((a) => a.studentId));
      final exercises = await exercisesById(page.map((a) => a.exerciseId));
      return [
        for (final a in page)
          HomeworkOverviewRow(
            studentId: a.studentId,
            studentName: users[a.studentId]?.staffLabel ?? '—',
            exerciseId: a.exerciseId,
            exerciseTitle: exercises[a.exerciseId]?.title ?? '—',
            bestScore: a.bestScore,
            isOverdue: a.done != true && a.isOverdue,
            dueDate: a.dueDate,
          ),
      ];
    });
  }

  // ------------------------------------------------------------ packages

  /// Exercise packages, newest first, a page at a time. Filters and search
  /// are queries on the list fields the `onExerciseListIndex` function
  /// keeps (`listAt`, `listCategory`, `listSkill`, `searchPrefixes`).
  // ------------------------------------------------------------ bank

  static const bankSheetsCollection = 'bank_sheets';

  /// The question bank, one row per worksheet or stand-alone question,
  /// newest first, a page at a time (`bank_sheets`, kept by functions).
  PageSource<BankSheetRow> bankSource(
    DateRangeSel range, {
    String? category,
    String? type,
    String? level,
    String search = '',
  }) {
    Query<Map<String, dynamic>> q = _db.collection(bankSheetsCollection);
    if (category != null) q = q.where('category', isEqualTo: category);
    if (type != null) q = q.where('type', isEqualTo: type);
    if (level != null) q = q.where('level', isEqualTo: level);
    final term = UserSearch.normalize(search);
    if (term.isNotEmpty) q = q.where('searchPrefixes', arrayContains: term);
    return FirestorePageSource(
        newestFirst(q, 'createdAt', range), BankSheetRow.fromFirestore);
  }

  /// Questions the worksheet index does not cover yet (before an admin
  /// presses Rebuild list indexes once): bank size minus indexed count.
  Future<int> bankNotIndexed() async {
    try {
      final r = await Future.wait([
        _db.collection(AppConstants.questionBankCollection).count().get(),
        _db
            .collection(bankSheetsCollection)
            .aggregate(sum('count'))
            .get(),
      ]);
      final all = r[0].count ?? 0;
      final indexed =
          (r[1].getSum('count') ?? 0).round();
      return all - indexed;
    } catch (_) {
      return 0;
    }
  }

  /// The questions of one worksheet (its code field, or the code as the
  /// first tag on older questions), read when the worksheet is opened.
  Future<List<QuestionBankItem>> sheetQuestions(String key) async {
    final col = _db.collection(AppConstants.questionBankCollection);
    final r = await Future.wait([
      col.where('sheetCode', isEqualTo: key).get(),
      col.where('tags', arrayContains: key).get(),
    ]);
    final byId = <String, QuestionBankItem>{};
    for (final d in [...r[0].docs, ...r[1].docs]) {
      final item = QuestionBankItem.fromFirestore(d);
      if (item.sheetKey == key) byId[d.id] = item;
    }
    return byId.values.toList();
  }

  /// The questions of one worksheet, live (the worksheet screen follows
  /// its own edits): the code-field query and the old tag query merged.
  Stream<List<QuestionBankItem>> watchSheet(String key) {
    final col = _db.collection(AppConstants.questionBankCollection);
    final byCode = col.where('sheetCode', isEqualTo: key).snapshots();
    final byTag = col.where('tags', arrayContains: key).snapshots();
    late final StreamController<List<QuestionBankItem>> out;
    List<QuerySnapshot<Map<String, dynamic>>?> last = [null, null];
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    void emit() {
      if (last.any((s) => s == null)) return;
      final byId = <String, QuestionBankItem>{};
      for (final snap in last) {
        for (final d in snap!.docs) {
          final item = QuestionBankItem.fromFirestore(d);
          if (item.sheetKey == key) byId[d.id] = item;
        }
      }
      out.add(byId.values.toList());
    }

    out = StreamController<List<QuestionBankItem>>(
      onListen: () {
        subs.add(byCode.listen((s) {
          last[0] = s;
          emit();
        }, onError: out.addError));
        subs.add(byTag.listen((s) {
          last[1] = s;
          emit();
        }, onError: out.addError));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  /// One bank question (a stand-alone row opened in the editor).
  Future<QuestionBankItem?> bankItem(String id) async {
    final d = await _db
        .collection(AppConstants.questionBankCollection)
        .doc(id)
        .get();
    return d.exists ? QuestionBankItem.fromFirestore(d) : null;
  }

  Query<Map<String, dynamic>> packageQuery(
    DateRangeSel range, {
    String? level,
    String? skill,
    String? category,
    String search = '',
  }) {
    Query<Map<String, dynamic>> q =
        _db.collection(AppConstants.exercisesCollection);
    if (level != null) q = q.where('level', isEqualTo: level);
    if (skill != null) q = q.where('listSkill', isEqualTo: skill);
    if (category != null) q = q.where('listCategory', isEqualTo: category);
    final term = UserSearch.normalize(search);
    if (term.isNotEmpty) q = q.where('searchPrefixes', arrayContains: term);
    return newestFirst(q, 'listAt', range);
  }

  /// The assignments of the packages on one page (bounded by the students
  /// they are assigned to), by exercise id.
  Future<Map<String, List<ExerciseAssignment>>> assignmentsFor(
      List<String> exerciseIds) async {
    final out = <String, List<ExerciseAssignment>>{
      for (final id in exerciseIds) id: [],
    };
    for (var i = 0; i < exerciseIds.length; i += 30) {
      final snap = await _assignments
          .where('exerciseId',
              whereIn:
                  exerciseIds.sublist(i, (i + 30).clamp(0, exerciseIds.length)))
          .get();
      for (final d in snap.docs) {
        final a = ExerciseAssignment.fromFirestore(d);
        out.putIfAbsent(a.exerciseId, () => []).add(a);
      }
    }
    return out;
  }

  /// Exercises without the list fields yet (before an admin presses
  /// Rebuild list indexes once).
  Future<int> packagesNotIndexed() async {
    final col = _db.collection(AppConstants.exercisesCollection);
    final r = await Future.wait([
      col.count().get(),
      col.where('listAt', isNotEqualTo: null).count().get(),
    ]);
    return (r[0].count ?? 0) - (r[1].count ?? 0);
  }

  /// Results of one exercise (read when its progress dialog is opened).
  Future<List<ExerciseResult>> resultsOfExercise(String exerciseId) async {
    final snap = await _db
        .collection(AppConstants.exerciseResultsCollection)
        .where('exerciseId', isEqualTo: exerciseId)
        .get();
    return snap.docs.map(ExerciseResult.fromFirestore).toList();
  }

  /// Admin: builds the worksheet index and the package list fields.
  Future<Map<String, dynamic>> rebuildListIndexes() async {
    final r = await FirebaseFunctions.instance
        .httpsCallable('rebuildListIndexes',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 9)))
        .call<dynamic>({});
    return Map<String, dynamic>.from(r.data as Map? ?? const {});
  }

  /// Homework totals by count aggregation.
  Future<({int total, int done, int overdue})> homeworkCounts() async {
    final r = await Future.wait([
      _assignments.count().get(),
      _assignments.where('done', isEqualTo: true).count().get(),
      _assignments
          .where('done', isEqualTo: false)
          .where('dueDate', isLessThan: Timestamp.fromDate(_todayStart))
          .count()
          .get(),
    ]);
    return (
      total: r[0].count ?? 0,
      done: r[1].count ?? 0,
      overdue: r[2].count ?? 0,
    );
  }

  // ------------------------------------------------------------ weekly

  /// Lessons finished and practice handed in per day for the last [days]
  /// days, by count aggregation (two per day).
  Future<List<WeeklyActivityDay>> weeklyActivity({int days = 7}) async {
    final today = _todayStart;
    final out = <WeeklyActivityDay>[];
    for (var i = days - 1; i >= 0; i--) {
      final from = today.subtract(Duration(days: i));
      final to = from.add(const Duration(days: 1));
      final r = await Future.wait([
        _db
            .collection(AppConstants.exerciseResultsCollection)
            .where('submittedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .where('submittedAt', isLessThan: Timestamp.fromDate(to))
            .count()
            .get(),
        _db
            .collection(AppConstants.progressCollection)
            .where('completed', isEqualTo: true)
            .where('completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(from))
            .where('completedAt', isLessThan: Timestamp.fromDate(to))
            .count()
            .get(),
      ]);
      out.add(WeeklyActivityDay(
          day: from, count: (r[0].count ?? 0) + (r[1].count ?? 0)));
    }
    return out;
  }

  /// The last 7 days of activity as one timeline (practice, lessons,
  /// assignments, class visits, classes closed, vouchers), a page at a
  /// time over six bounded sources. [teacherUid] limits the closed
  /// classes to the teacher's own, as before.
  PageSource<TeacherActivityEvent> weeklyFeedSource(AppLocalizations l,
      {String? teacherUid}) {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)));
    Query<Map<String, dynamic>> recent(String col, String field) => _db
        .collection(col)
        .where(field, isGreaterThanOrEqualTo: since)
        .orderBy(field, descending: true);
    Query<Map<String, dynamic>> closed = _db
        .collection(AppConstants.classSessionsCollection);
    if (teacherUid != null) {
      closed = closed.where('teacherId', isEqualTo: teacherUid);
    }
    closed = closed
        .where('concludedAt', isGreaterThanOrEqualTo: since)
        .orderBy('concludedAt', descending: true);

    // Raw events carry the student id; names are joined per page.
    final sources = <PageSource<_RawEvent>>[
      FirestorePageSource(
          recent(AppConstants.exerciseResultsCollection, 'submittedAt'), (d) {
        final r = ExerciseResult.fromFirestore(d);
        return _RawEvent(TeacherActivityType.exerciseSubmitted,
            r.submittedAt, r.studentId,
            exerciseId: r.exerciseId, score: r.score, text: r.exerciseTitle);
      }),
      FilteredPageSource(
          FirestorePageSource(
              recent(AppConstants.progressCollection, 'completedAt'), (d) {
            final p = StudentProgress.fromFirestore(d);
            return _RawEvent(TeacherActivityType.lessonCompleted,
                p.completed ? p.completedAt : null, p.studentId,
                text: p.lessonId);
          }),
          (e) => e.at != null),
      FirestorePageSource(
          recent(AppConstants.exerciseAssignmentsCollection, 'assignedAt'),
          (d) {
        final a = ExerciseAssignment.fromFirestore(d);
        return _RawEvent(TeacherActivityType.homeworkAssigned, a.assignedAt,
            a.studentId,
            exerciseId: a.exerciseId);
      }),
      FilteredPageSource(
          FirestorePageSource(
              recent(AppConstants.attendanceCollection, 'joinedAt'), (d) {
            final r = AttendanceRecord.fromFirestore(d);
            return _RawEvent(
                r.joinedByStudent
                    ? TeacherActivityType.sessionJoined
                    : TeacherActivityType.sessionAdded,
                r.attended ? r.joinedAt : null,
                r.studentId,
                text: r.sessionTitle.isNotEmpty
                    ? '${r.sessionDate} · ${r.sessionTitle}'
                    : r.sessionDate,
                name: r.studentName);
          }),
          (e) => e.at != null),
      FirestorePageSource(closed, (d) {
        final s = ClassSession.fromFirestore(d);
        return _RawEvent(TeacherActivityType.classConcluded, s.concludedAt, '',
            text: s.sessionTitle.isNotEmpty
                ? '${s.sessionDate} · ${s.sessionTitle}'
                : s.sessionDate);
      }),
      FirestorePageSource(
          recent(AppConstants.studentClassTermsCollection, 'createdAt'), (d) {
        final t = StudentClassTerm.fromFirestore(d);
        return _RawEvent(TeacherActivityType.termCreated, t.createdAt,
            t.studentId,
            text: '${t.packageSize}|${t.startDate}|${t.deadlineDate}');
      }),
    ];
    final merged = MergedPageSource<_RawEvent>(sources,
        newer: (a, b) =>
            (a.at ?? DateTime(1970)).isAfter(b.at ?? DateTime(1970)));
    return MappedPageSource<_RawEvent, TeacherActivityEvent>(merged,
        (page) async {
      final users = await usersById(page.map((e) => e.studentId));
      final exercises = await exercisesById(
          page.map((e) => e.exerciseId ?? '').where((id) => id.isNotEmpty));
      return [for (final e in page) e.toEvent(l, users, exercises)];
    });
  }

  // ------------------------------------------------------------ classes

  /// The classes of the current calendar week (Monday first), by date.
  PageSource<ClassSession> classesThisWeekSource({String? teacherUid}) {
    final today = _todayStart;
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final range = DateRangeSel.custom(
        monday, monday.add(const Duration(days: 6)));
    Query<Map<String, dynamic>> q =
        _db.collection(AppConstants.classSessionsCollection);
    if (teacherUid != null) q = q.where('teacherId', isEqualTo: teacherUid);
    return FirestorePageSource(
        applyDateRange(q.orderBy('sessionDate'), 'sessionDate', range,
            kind: DateFieldKind.isoDay),
        ClassSession.fromFirestore);
  }

  // ---------------------------------------------------------------- helpers

  /// Applies [range] to a query ordered by [field] (newest first).
  static Query<Map<String, dynamic>> newestFirst(
    Query<Map<String, dynamic>> q,
    String field,
    DateRangeSel range, {
    DateFieldKind kind = DateFieldKind.timestamp,
  }) =>
      applyDateRange(q.orderBy(field, descending: true), field, range,
          kind: kind);
}

/// Which assignments a homework drill-down lists.
enum HomeworkView { all, done, overdue }

/// One event of the weekly feed before the names are joined.
class _RawEvent {
  const _RawEvent(this.type, this.at, this.studentId,
      {this.exerciseId, this.score, this.text, this.name});

  final TeacherActivityType type;
  final DateTime? at;
  final String studentId;
  final String? exerciseId;
  final int? score;
  final String? text;
  final String? name;

  TeacherActivityEvent toEvent(AppLocalizations l, Map<String, AppUser> users,
      Map<String, Exercise> exercises) {
    final student = users[studentId];
    final label = student?.staffLabel;
    final exerciseTitle = exercises[exerciseId ?? '']?.title ??
        (text?.isNotEmpty == true ? text : null) ??
        l.activityExerciseFallback;
    final at = this.at ?? DateTime(1970);
    final sid = studentId.isEmpty ? null : studentId;
    switch (type) {
      case TeacherActivityType.exerciseSubmitted:
        return TeacherActivityEvent(
          type: type,
          occurredAt: at,
          studentId: sid,
          studentName: label,
          title: label != null
              ? l.activityScored(label, score ?? 0)
              : l.activitySubmitted(score ?? 0),
          subtitle: exerciseTitle,
        );
      case TeacherActivityType.lessonCompleted:
        return TeacherActivityEvent(
          type: type,
          occurredAt: at,
          studentId: sid,
          studentName: label,
          title: label != null
              ? l.activityLessonCompletedBy(label)
              : l.activityLessonCompleted,
          subtitle: l.activityLessonFallback(text ?? ''),
        );
      case TeacherActivityType.homeworkAssigned:
        return TeacherActivityEvent(
          type: type,
          occurredAt: at,
          studentId: sid,
          studentName: label,
          title: label != null
              ? l.activityAssignedTo(label)
              : l.activityAssigned,
          subtitle: exerciseTitle,
        );
      case TeacherActivityType.sessionJoined:
      case TeacherActivityType.sessionAdded:
        final n = label ?? name ?? l.activityStudentFallback;
        return TeacherActivityEvent(
          type: type,
          occurredAt: at,
          studentId: sid,
          studentName: n,
          title: type == TeacherActivityType.sessionJoined
              ? l.activityJoined(n)
              : l.activityAdded(n),
          subtitle: text,
        );
      case TeacherActivityType.classConcluded:
        return TeacherActivityEvent(
          type: type,
          occurredAt: at,
          title: l.activityClassConcluded,
          subtitle: text,
        );
      case TeacherActivityType.termCreated:
        final parts = (text ?? '||').split('|');
        return TeacherActivityEvent(
          type: type,
          occurredAt: at,
          studentId: sid,
          studentName: label,
          title: label != null
              ? l.activityTermAddedFor(label)
              : l.activityTermAdded,
          subtitle: l.activityTermSubtitle(
              int.tryParse(parts[0]) ?? 0,
              parts.length > 1 ? parts[1] : '',
              parts.length > 2 ? parts[2] : ''),
        );
    }
  }
}
