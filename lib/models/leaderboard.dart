import 'package:cloud_firestore/cloud_firestore.dart';

/// One row of a code's leaderboard (`leaderboards/{codeId}/entries/{uid}`,
/// written by the onTestResultWritten function, Build 2B). [name] is the
/// peer label; staff replace it with the staff label from `users`.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.studentId,
    required this.name,
    required this.parts,
    required this.total,
    required this.max,
    required this.passed,
    this.seconds,
    this.finishedAt,
    this.rank = 0,
  });

  final String studentId;
  final String name;
  final List<LeaderboardPart> parts;
  final int total;
  final int max;
  final bool passed;
  final int? seconds;
  final DateTime? finishedAt;
  final int rank;

  factory LeaderboardEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return LeaderboardEntry(
      studentId: doc.id,
      name: m['name'] as String? ?? '',
      parts: [
        for (final p in (m['parts'] as List? ?? const []))
          LeaderboardPart.fromMap(Map<String, dynamic>.from(p as Map)),
      ],
      total: (m['total'] as num?)?.round() ?? 0,
      max: (m['max'] as num?)?.round() ?? 0,
      passed: m['passed'] == true,
      seconds: (m['seconds'] as num?)?.round(),
      finishedAt: (m['finishedAt'] as Timestamp?)?.toDate(),
    );
  }

  LeaderboardEntry withRank(int r) => LeaderboardEntry(
        studentId: studentId,
        name: name,
        parts: parts,
        total: total,
        max: max,
        passed: passed,
        seconds: seconds,
        finishedAt: finishedAt,
        rank: r,
      );

  /// Board order (the same as functions/promotion.js): total high to low,
  /// then fewer seconds, then the earlier finish.
  static int compare(LeaderboardEntry a, LeaderboardEntry b) {
    if (a.total != b.total) return b.total.compareTo(a.total);
    final sa = a.seconds ?? 1 << 31, sb = b.seconds ?? 1 << 31;
    if (sa != sb) return sa.compareTo(sb);
    final fa = a.finishedAt?.millisecondsSinceEpoch ?? 1 << 50;
    final fb = b.finishedAt?.millisecondsSinceEpoch ?? 1 << 50;
    return fa.compareTo(fb);
  }

  /// Sorted with ranks; equal total and seconds share a rank.
  static List<LeaderboardEntry> ranked(Iterable<LeaderboardEntry> entries) {
    final sorted = [...entries]..sort(compare);
    var rank = 0;
    return [
      for (var i = 0; i < sorted.length; i++)
        sorted[i].withRank(i == 0 ||
                sorted[i - 1].total != sorted[i].total ||
                sorted[i - 1].seconds != sorted[i].seconds
            ? rank = i + 1
            : rank),
    ];
  }
}

class LeaderboardPart {
  const LeaderboardPart({required this.skill, required this.mark, required this.maxScore});

  final String skill;
  final int mark;
  final int maxScore;

  factory LeaderboardPart.fromMap(Map<String, dynamic> m) => LeaderboardPart(
        skill: m['skill'] as String? ?? '',
        mark: (m['mark'] as num?)?.round() ?? 0,
        maxScore: (m['maxScore'] as num?)?.round() ?? 0,
      );
}

/// HSK level groups (spec §2): Beginner (HSK 1-2), Intermediate (3-4),
/// Advance (5-6).
enum LevelGroup { beginner, intermediate, advance }

LevelGroup? levelGroupOf(String level) {
  final n = int.tryParse(RegExp(r'\d').firstMatch(level)?.group(0) ?? '');
  if (n == null) return null;
  if (n <= 2) return LevelGroup.beginner;
  if (n <= 4) return LevelGroup.intermediate;
  if (n <= 6) return LevelGroup.advance;
  return null;
}

/// A code passed toward promotion, with its marks.
class PromotionCode {
  const PromotionCode({required this.codeId, required this.code, required this.total, required this.max});

  final String codeId;
  final String code;
  final int total;
  final int max;

  factory PromotionCode.fromMap(Map<String, dynamic> m) => PromotionCode(
        codeId: m['codeId'] as String? ?? '',
        code: m['code'] as String? ?? m['codeId'] as String? ?? '',
        total: (m['total'] as num?)?.round() ?? 0,
        max: (m['max'] as num?)?.round() ?? 0,
      );
}

/// A promotion recommendation (`level_promotions/{uid_level}`).
class LevelPromotion {
  const LevelPromotion({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentNameChinese,
    required this.fromLevel,
    required this.toLevel,
    required this.codes,
    required this.status,
    this.minCodes = 3,
    this.createdAt,
    this.declineReason = '',
    this.kind = 'promotion',
    this.passed = false,
  });

  /// Build 3: `placement` for a placement result's recommendation
  /// (`{uid}_placement`), else `promotion`.
  final String kind;

  /// Placement: whether the paper was passed.
  final bool passed;

  bool get isPlacement => kind == 'placement';

  final String id;
  final String studentId;
  final String studentName;
  final String studentNameChinese;
  final String fromLevel;
  final String toLevel;
  final List<PromotionCode> codes;

  /// `waiting`, `approved`, `declined`, `withdrawn`.
  final String status;
  final int minCodes;
  final DateTime? createdAt;
  final String declineReason;

  bool get isWaiting => status == 'waiting';

  factory LevelPromotion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    return LevelPromotion(
      id: doc.id,
      studentId: m['studentId'] as String? ?? '',
      studentName: m['studentName'] as String? ?? '',
      studentNameChinese: m['studentNameChinese'] as String? ?? '',
      fromLevel: m['fromLevel'] as String? ?? '',
      toLevel: m['toLevel'] as String? ?? '',
      codes: [
        for (final c in (m['codes'] as List? ?? const []))
          PromotionCode.fromMap(Map<String, dynamic>.from(c as Map)),
      ],
      status: m['status'] as String? ?? '',
      minCodes: (m['minCodes'] as num?)?.round() ?? 3,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      declineReason: m['declineReason'] as String? ?? '',
      kind: m['kind'] as String? ?? 'promotion',
      passed: m['passed'] == true,
    );
  }
}

/// "2 of 3 codes passed" (`promotion_progress/{uid}`).
class PromotionProgress {
  const PromotionProgress({
    required this.level,
    required this.next,
    required this.count,
    required this.minCodes,
    required this.codes,
    this.decision = '',
    this.mode = 'codes',
    this.done = 0,
    this.total = 0,
    this.items = const [],
  });

  /// Owner 2026-11-24: `path` when the level has a checklist (it replaces
  /// the code count), else `codes`.
  final String mode;
  final int done;
  final int total;
  final List<PathProgressItem> items;
  bool get usesPath => mode == 'path';

  final String level;
  final String next;
  final int count;
  final int minCodes;
  final List<PromotionCode> codes;

  /// What happened to the recommendation at this level: '' (none yet),
  /// 'waiting' or 'declined' (written by the functions).
  final String decision;

  bool get declined => decision == 'declined';

  factory PromotionProgress.fromMap(Map<String, dynamic> m) => PromotionProgress(
        level: m['level'] as String? ?? '',
        next: m['next'] as String? ?? '',
        count: (m['count'] as num?)?.round() ?? 0,
        minCodes: (m['minCodes'] as num?)?.round() ?? 3,
        codes: [
          for (final c in (m['codes'] as List? ?? const []))
            PromotionCode.fromMap(Map<String, dynamic>.from(c as Map)),
        ],
        decision: m['decision'] as String? ?? '',
        mode: m['mode'] as String? ?? 'codes',
        done: (m['done'] as num?)?.round() ?? 0,
        total: (m['total'] as num?)?.round() ?? 0,
        items: [
          for (final i in (m['items'] as List? ?? const []))
            PathProgressItem.fromMap(Map<String, dynamic>.from(i as Map)),
        ],
      );
}

/// One line of a student's level checklist (written by the functions).
class PathProgressItem {
  const PathProgressItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.done,
    this.minScore = 0,
    this.best,
  });

  final String kind;
  final String id;
  final String title;
  final bool done;
  final int minScore;
  final int? best;

  factory PathProgressItem.fromMap(Map<String, dynamic> m) => PathProgressItem(
        kind: m['kind'] as String? ?? 'exercise',
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        done: m['done'] == true,
        minScore: (m['minScore'] as num?)?.round() ?? 0,
        best: (m['best'] as num?)?.round(),
      );
}
