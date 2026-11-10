import '../core/constants/app_constants.dart';
import '../core/utils/level_utils.dart';
import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/exercise_skill_category.dart';
import '../models/student_class_term.dart';

class MonthlyCount {
  const MonthlyCount({required this.label, required this.count});

  final String label;
  final int count;
}

class HskBandCount {
  const HskBandCount({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

class WorksheetSkillCount {
  const WorksheetSkillCount({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

class WorksheetInventoryRow {
  const WorksheetInventoryRow({
    required this.hskLevel,
    required this.total,
    required this.published,
    required this.draft,
    required this.skills,
  });

  final String hskLevel;
  final int total;
  final int published;
  final int draft;
  final List<WorksheetSkillCount> skills;

  String get skillSummary => skills
      .where((skill) => skill.count > 0)
      .map((skill) => '${skill.count} ${skill.label}')
      .join(' · ');
}

class AdminReportData {
  const AdminReportData({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalTeachers,
    required this.totalMurid,
    required this.activeStudents,
    required this.inactiveUsers,
    required this.totalExercises,
    required this.totalWorksheets,
    required this.lowVouchers,
    required this.newStudentsByMonth,
    required this.hskBands,
    required this.vouchersIssuedByMonth,
    required this.worksheetInventory,
  });

  final int totalUsers;
  final int totalAdmins;
  final int totalTeachers;
  final int totalMurid;
  final int activeStudents;
  final int inactiveUsers;
  final int totalExercises;
  final int totalWorksheets;
  final int lowVouchers;
  final List<MonthlyCount> newStudentsByMonth;
  final List<HskBandCount> hskBands;
  final List<MonthlyCount> vouchersIssuedByMonth;
  final List<WorksheetInventoryRow> worksheetInventory;
}

abstract final class AdminReportService {
  static AdminReportData build({
    required List<AppUser> users,
    required List<Exercise> exercises,
    required List<StudentClassTerm> classTerms,
  }) {
    final allStudents = users.where((u) => u.isStudent).toList();
    final activeStudents = allStudents.where((u) => u.active).toList();
    final teachers = users.where((u) => u.isTeacher).toList();
    final admins = users.where((u) => u.isAdmin).toList();
    final lowVouchers = classTerms
        .where(
          (t) => t.sessionsRemaining > 0 && t.sessionsRemaining <= 2,
        )
        .length;
    final worksheetInventory = _worksheetInventory(exercises);

    return AdminReportData(
      totalUsers: users.length,
      totalAdmins: admins.length,
      totalTeachers: teachers.length,
      totalMurid: allStudents.length,
      activeStudents: activeStudents.length,
      inactiveUsers: users.where((u) => !u.active).length,
      totalExercises: exercises.where((e) => e.isPublished).length,
      totalWorksheets: exercises.length,
      lowVouchers: lowVouchers,
      newStudentsByMonth: _newStudentsByMonth(allStudents),
      hskBands: _hskBands(activeStudents),
      vouchersIssuedByMonth: _vouchersIssuedByMonth(classTerms),
      worksheetInventory: worksheetInventory,
    );
  }

  static List<WorksheetInventoryRow> _worksheetInventory(
    List<Exercise> exercises,
  ) {
    final buckets = <String, List<Exercise>>{
      for (final level in AppConstants.hskLevels) level: <Exercise>[],
      'Unassigned': <Exercise>[],
    };

    for (final exercise in exercises) {
      final normalized = LevelUtils.normalizeHskLevel(exercise.level);
      final level =
          normalized != null && AppConstants.hskLevels.contains(normalized)
              ? normalized
              : 'Unassigned';
      buckets[level]!.add(exercise);
    }

    final rows = <WorksheetInventoryRow>[];
    for (final level in [...AppConstants.hskLevels, 'Unassigned']) {
      final items = buckets[level]!;
      if (items.isEmpty) continue;

      final skillCounts = {
        for (final category in ExerciseSkillCategory.values) category: 0,
      };
      var published = 0;
      for (final exercise in items) {
        skillCounts[exercise.skillCategory] =
            skillCounts[exercise.skillCategory]! + 1;
        if (exercise.isPublished) published++;
      }

      rows.add(
        WorksheetInventoryRow(
          hskLevel: level,
          total: items.length,
          published: published,
          draft: items.length - published,
          skills: [
            for (final category in ExerciseSkillCategory.values)
              WorksheetSkillCount(
                label: category.label,
                count: skillCounts[category]!,
              ),
          ],
        ),
      );
    }
    return rows;
  }

  static List<MonthlyCount> _newStudentsByMonth(List<AppUser> students) {
    return _countsByMonth(
      students,
      dateFor: (student) => student.createdAt,
    );
  }

  static List<MonthlyCount> _vouchersIssuedByMonth(
    List<StudentClassTerm> terms,
  ) {
    return _countsByMonth(
      terms,
      dateFor: (term) {
        final parsed = DateTime.tryParse(term.startDate);
        return parsed ?? term.createdAt;
      },
    );
  }

  static List<MonthlyCount> _countsByMonth<T>(
    List<T> items, {
    required DateTime? Function(T item) dateFor,
  }) {
    final now = DateTime.now();
    final months = <MonthlyCount>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final label = _monthLabel(month);
      final count = items.where((item) {
        final date = dateFor(item);
        if (date == null) return false;
        return date.year == month.year && date.month == month.month;
      }).length;
      months.add(MonthlyCount(label: label, count: count));
    }
    return months;
  }

  static String _monthLabel(DateTime month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  static List<HskBandCount> _hskBands(List<AppUser> students) {
    int band(int min, int max) {
      return students.where((s) {
        final level = s.level ?? '';
        final match = RegExp(r'HSK (\d+)').firstMatch(level);
        if (match == null) return false;
        final n = int.tryParse(match.group(1) ?? '') ?? 0;
        return n >= min && n <= max;
      }).length;
    }

    return [
      HskBandCount(label: 'Beginner (HSK 1–2)', count: band(1, 2)),
      HskBandCount(label: 'Intermediate (HSK 3–4)', count: band(3, 4)),
      HskBandCount(label: 'Advanced (HSK 5–6)', count: band(5, 6)),
    ];
  }
}
