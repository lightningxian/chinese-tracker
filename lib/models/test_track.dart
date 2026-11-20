import 'package:cloud_firestore/cloud_firestore.dart';

/// Supervised test track (docs/PLAN.md §3, Build 1): formats, test codes,
/// sessions, attempts and results. Formats and codes are written by admins
/// from the app; sessions, attempts and results only by Cloud Functions.

/// Test families of §3.
enum TestFamily {
  hsk('hsk', 'HSK'),
  hsk3('hsk3', 'HSK 3.0'),
  yct('yct', 'YCT'),
  hskk('hskk', 'HSKK'),
  yctOral('yct_oral', 'YCT oral');

  const TestFamily(this.value, this.label);

  final String value;
  final String label;

  static TestFamily fromValue(String? value) => TestFamily.values.firstWhere(
        (f) => f.value == value,
        orElse: () => TestFamily.hsk,
      );
}

/// Skill of a part. `writing` is stored as `typing` on bank questions.
enum TestSkill {
  listening('listening', '听力'),
  reading('reading', '阅读'),
  writing('writing', '书写'),
  speaking('speaking', '口语');

  const TestSkill(this.value, this.chinese);

  final String value;

  /// Column label on the result card.
  final String chinese;

  static TestSkill fromValue(String? value) => TestSkill.values.firstWhere(
        (s) => s.value == value,
        orElse: () => TestSkill.reading,
      );
}

/// One part of a paper: its skill, how many questions, its clock and the
/// mark it is worth.
class TestPart {
  const TestPart({
    required this.skill,
    required this.questions,
    required this.minutes,
    required this.maxScore,
  });

  final TestSkill skill;
  final int questions;
  final int minutes;
  final int maxScore;

  factory TestPart.fromMap(Map<String, dynamic> m) => TestPart(
        skill: TestSkill.fromValue(m['skill'] as String?),
        questions: (m['questions'] as num?)?.toInt() ?? 0,
        minutes: (m['minutes'] as num?)?.toInt() ?? 0,
        maxScore: (m['maxScore'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'skill': skill.value,
        'questions': questions,
        'minutes': minutes,
        'maxScore': maxScore,
      };

  TestPart copyWith({
    TestSkill? skill,
    int? questions,
    int? minutes,
    int? maxScore,
  }) =>
      TestPart(
        skill: skill ?? this.skill,
        questions: questions ?? this.questions,
        minutes: minutes ?? this.minutes,
        maxScore: maxScore ?? this.maxScore,
      );
}

int _sumMax(List<TestPart> parts) =>
    parts.fold<int>(0, (n, p) => n + p.maxScore);

int _sumMinutes(List<TestPart> parts) =>
    parts.fold<int>(0, (n, p) => n + p.minutes);

/// A format (`test_formats/{id}`): the shape of a paper of one level.
class TestFormat {
  const TestFormat({
    required this.id,
    required this.family,
    required this.level,
    required this.levelKey,
    required this.parts,
    required this.passMark,
    this.provisional = false,
    this.order = 0,
    this.updatedAt,
  });

  final String id;
  final TestFamily family;

  /// Label, e.g. `HSK 3`.
  final String level;

  /// Level inside the family: `1`…`6`, `7-9`, `basic`…
  final String levelKey;
  final List<TestPart> parts;
  final int passMark;

  /// Timings or marks not confirmed from a real paper yet (YCT minutes,
  /// HSKK, HSK 3.0): shown with a "draft" badge, fixed by the admin.
  final bool provisional;
  final int order;
  final DateTime? updatedAt;

  int get maxTotal => _sumMax(parts);
  int get totalMinutes => _sumMinutes(parts);
  bool get isSpeaking =>
      parts.isNotEmpty && parts.every((p) => p.skill == TestSkill.speaking);

  factory TestFormat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      TestFormat.fromMap(doc.id, doc.data() ?? const {});

  factory TestFormat.fromMap(String id, Map<String, dynamic> m) => TestFormat(
        id: id,
        family: TestFamily.fromValue(m['family'] as String?),
        level: m['level'] as String? ?? id,
        levelKey: m['levelKey'] as String? ?? '',
        parts: (m['parts'] as List? ?? const [])
            .map((p) => TestPart.fromMap(Map<String, dynamic>.from(p as Map)))
            .toList(),
        passMark: (m['passMark'] as num?)?.toInt() ?? 0,
        provisional: m['provisional'] == true,
        order: (m['order'] as num?)?.toInt() ?? 0,
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'family': family.value,
        'level': level,
        'levelKey': levelKey,
        'parts': parts.map((p) => p.toMap()).toList(),
        'passMark': passMark,
        'provisional': provisional,
        'order': order,
      };

  TestFormat copyWith({
    List<TestPart>? parts,
    int? passMark,
    bool? provisional,
  }) =>
      TestFormat(
        id: id,
        family: family,
        level: level,
        levelKey: levelKey,
        parts: parts ?? this.parts,
        passMark: passMark ?? this.passMark,
        provisional: provisional ?? this.provisional,
        order: order,
        updatedAt: updatedAt,
      );
}

/// Chinese name of a level for the result card's 考试类型, e.g. `HSK 三级`.
String chineseExamType(TestFamily family, String levelKey) {
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  String level(String key) {
    if (key == '7-9') return '七至九级';
    final n = int.tryParse(key);
    if (n != null && n >= 0 && n < digits.length) return '${digits[n]}级';
    return switch (key) {
      'basic' => '初级',
      'intermediate' => '中级',
      'advanced' => '高级',
      _ => key,
    };
  }

  return switch (family) {
    TestFamily.hsk => 'HSK ${level(levelKey)}',
    TestFamily.hsk3 => 'HSK 3.0 ${level(levelKey)}',
    TestFamily.yct => 'YCT ${level(levelKey)}',
    TestFamily.hskk => 'HSKK ${level(levelKey)}',
    TestFamily.yctOral => 'YCT 口试 ${level(levelKey)}',
  };
}

/// The standard formats of PLAN.md §3, loaded by **Load standard formats**
/// (adds the missing ones, never overwrites an existing one). Listening
/// minutes include the paper's answer-sheet minutes. YCT part minutes,
/// HSKK timings and every HSK 3.0 number are drafts (`provisional`).
List<TestFormat> standardTestFormats() {
  TestPart l(int q, int m, [int max = 100]) => TestPart(
      skill: TestSkill.listening, questions: q, minutes: m, maxScore: max);
  TestPart r(int q, int m, [int max = 100]) => TestPart(
      skill: TestSkill.reading, questions: q, minutes: m, maxScore: max);
  TestPart w(int q, int m, [int max = 100]) => TestPart(
      skill: TestSkill.writing, questions: q, minutes: m, maxScore: max);
  TestPart s(int q, int m, [int max = 100]) => TestPart(
      skill: TestSkill.speaking, questions: q, minutes: m, maxScore: max);

  var order = 0;
  TestFormat f(
    TestFamily family,
    String key,
    String label,
    List<TestPart> parts,
    int pass, {
    bool provisional = false,
  }) {
    order += 1;
    return TestFormat(
      id: '${family.value}-$key',
      family: family,
      level: label,
      levelKey: key,
      parts: parts,
      passMark: pass,
      provisional: provisional,
      order: order,
    );
  }

  return [
    f(TestFamily.hsk, '1', 'HSK 1', [l(20, 18), r(20, 17)], 120),
    f(TestFamily.hsk, '2', 'HSK 2', [l(35, 28), r(25, 22)], 120),
    f(TestFamily.hsk, '3', 'HSK 3', [l(40, 40), r(30, 30), w(10, 15)], 180),
    f(TestFamily.hsk, '4', 'HSK 4', [l(45, 35), r(40, 40), w(15, 25)], 180),
    f(TestFamily.hsk, '5', 'HSK 5', [l(45, 35), r(45, 45), w(10, 40)], 180),
    f(TestFamily.hsk, '6', 'HSK 6', [l(50, 40), r(50, 50), w(1, 45)], 180),
    f(TestFamily.yct, '1', 'YCT 1', [l(20, 15), r(15, 15)], 120,
        provisional: true),
    f(TestFamily.yct, '2', 'YCT 2', [l(20, 20), r(20, 25)], 120,
        provisional: true),
    f(TestFamily.yct, '3', 'YCT 3', [l(35, 25), r(25, 30)], 120,
        provisional: true),
    f(TestFamily.yct, '4', 'YCT 4', [l(40, 25), r(30, 30), w(10, 25)], 180,
        provisional: true),
    // HSKK basic from the owner's paper (H726119Z): 听后重复 15 items 6′,
    // 听后回答 10 items 4′, 回答问题 2 items 3′ (+7′ preparation, ~20′ in
    // all), 100 marks, pass 60. The paper prints no marks per part: the
    // 30 / 30 / 40 split is a draft.
    f(TestFamily.hskk, 'basic', 'HSKK Basic',
        [s(15, 6, 30), s(10, 4, 30), s(2, 3, 40)], 60,
        provisional: true),
    f(TestFamily.hskk, 'intermediate', 'HSKK Intermediate', [s(14, 23)], 60,
        provisional: true),
    f(TestFamily.hskk, 'advanced', 'HSKK Advanced', [s(6, 25)], 60,
        provisional: true),
    f(TestFamily.yctOral, 'basic', 'YCT oral Basic', [s(0, 15)], 60,
        provisional: true),
    f(TestFamily.yctOral, 'intermediate', 'YCT oral Intermediate', [s(0, 20)],
        60,
        provisional: true),
    // HSK 3.0 from the owner's papers (levels 1–4; 5, 6 and 7–9 stay empty
    // drafts). The papers print no marks: 100 per part and a pass mark of
    // 60% of the total, all provisional.
    for (final (key, parts) in <(String, List<TestPart>)>[
      ('1', [l(20, 15), r(20, 20)]),
      ('2', [l(25, 20), r(25, 25), w(10, 10)]),
      ('3', [l(30, 28), r(30, 30), w(10, 20)]),
      ('4', [l(32, 25), r(32, 30), w(6, 25)]),
      ('5', <TestPart>[]),
      ('6', <TestPart>[]),
      ('7-9', <TestPart>[]),
    ])
      f(TestFamily.hsk3, key, 'HSK 3.0 $key', parts,
          (_sumMax(parts) * 0.6).round(),
          provisional: true),
  ];
}

/// A test code (`test_codes/{CODE}`): one bank worksheet plus a copy of a
/// format, editable per code because every paper prints its own timing.
class TestCode {
  const TestCode({
    required this.id,
    required this.code,
    required this.family,
    required this.level,
    required this.levelKey,
    required this.sheetKey,
    required this.parts,
    required this.passMark,
    this.formatId = '',
    this.releaseYear,
    this.active = true,
    this.countsForPromotion = true,
    this.placement = false,
    this.createdAt,
  });

  final String id;
  final String code;
  final TestFamily family;
  final String level;
  final String levelKey;
  final String sheetKey;
  final String formatId;
  final List<TestPart> parts;
  final int passMark;
  final int? releaseYear;
  final bool active;
  final bool countsForPromotion;

  /// Build 3: a placement code. Visitors may sit it from the landing page;
  /// its results never reach a board or the promotion count.
  final bool placement;
  final DateTime? createdAt;

  int get maxTotal => _sumMax(parts);
  int get totalMinutes => _sumMinutes(parts);
  String get examTypeChinese => chineseExamType(family, levelKey);

  /// Upper case, no spaces: the doc id and what people type.
  static String normalize(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  factory TestCode.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    final format = Map<String, dynamic>.from(m['format'] as Map? ?? const {});
    return TestCode(
      id: doc.id,
      code: m['code'] as String? ?? doc.id,
      family: TestFamily.fromValue(m['family'] as String?),
      level: m['level'] as String? ?? '',
      levelKey: m['levelKey'] as String? ?? '',
      sheetKey: m['sheetKey'] as String? ?? '',
      formatId: m['formatId'] as String? ?? '',
      parts: (format['parts'] as List? ?? const [])
          .map((p) => TestPart.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
      passMark: (format['passMark'] as num?)?.toInt() ?? 0,
      releaseYear: (m['releaseYear'] as num?)?.toInt(),
      active: m['active'] != false,
      countsForPromotion: m['countsForPromotion'] != false,
      placement: m['placement'] == true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'family': family.value,
        'level': level,
        'levelKey': levelKey,
        'sheetKey': sheetKey,
        'formatId': formatId,
        'format': {
          'parts': parts.map((p) => p.toMap()).toList(),
          'passMark': passMark,
        },
        'releaseYear': releaseYear,
        'active': active,
        // A placement code never counts toward promotion.
        'countsForPromotion': placement ? false : countsForPromotion,
        'placement': placement,
      };
}

/// A supervised session (`test_sessions/{id}`), written by functions.
class TestSession {
  const TestSession({
    required this.id,
    required this.codeId,
    required this.code,
    required this.level,
    required this.token,
    required this.joinUntil,
    required this.openedBy,
    required this.openedByName,
    required this.status,
    this.partClocks = true,
    this.placement = false,
    this.visitorsAllowed = false,
    this.createdAt,
  });

  /// A placement code's session: visitors join from `/placement`.
  final bool visitorsAllowed;

  final String id;
  final String codeId;
  final String code;
  final String level;
  final String token;
  final DateTime? joinUntil;
  final String openedBy;
  final String openedByName;
  final String status;

  /// true: a clock per part (the supervised test as planned). false: one
  /// clock for the whole paper, free movement between parts, one submit.
  final bool partClocks;

  /// Build 3: results stay off the leaderboard and the count; visitors may
  /// join when the code is a placement code.
  final bool placement;
  final DateTime? createdAt;

  bool get isOpen => status == 'open';

  factory TestSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return TestSession(
      id: doc.id,
      codeId: m['codeId'] as String? ?? '',
      code: m['code'] as String? ?? '',
      level: m['level'] as String? ?? '',
      token: m['token'] as String? ?? '',
      joinUntil: (m['joinUntil'] as Timestamp?)?.toDate(),
      openedBy: m['openedBy'] as String? ?? '',
      openedByName: m['openedByName'] as String? ?? '',
      status: m['status'] as String? ?? 'open',
      partClocks: m['partClocks'] != false,
      placement: m['placement'] == true,
      visitorsAllowed: m['visitorsAllowed'] == true,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// One left-page / came-back event of an attempt.
class TestEvent {
  const TestEvent({required this.type, required this.at, this.part});

  final String type;
  final DateTime at;
  final int? part;
}

/// A student's attempt (`test_attempts/{codeId_uid}`), written by functions.
class TestAttempt {
  const TestAttempt({
    required this.id,
    required this.codeId,
    required this.studentId,
    required this.studentName,
    required this.studentNameChinese,
    required this.sessionId,
    required this.partIndex,
    required this.partCount,
    this.partEndsAt,
    this.leftCount = 0,
    this.events = const [],
    this.finishedAt,
    this.startedAt,
    this.partClocks = true,
    this.submitRequested = false,
    this.visitor = false,
    this.visitorWhatsapp = '',
  });

  /// Build 3: a visitor with no account (public placement test).
  final bool visitor;
  final String visitorWhatsapp;

  /// Build 2A: the teacher pressed "End test for everyone"; the player
  /// sends the open part at once so typed answers are kept.
  final bool submitRequested;

  final String id;
  final String codeId;
  final String studentId;
  final String studentName;
  final String studentNameChinese;
  final String sessionId;
  final int partIndex;
  final int partCount;
  final DateTime? partEndsAt;
  final int leftCount;
  final List<TestEvent> events;
  final DateTime? finishedAt;
  final DateTime? startedAt;
  final bool partClocks;

  bool get finished => finishedAt != null;

  factory TestAttempt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return TestAttempt(
      id: doc.id,
      codeId: m['codeId'] as String? ?? '',
      studentId: m['studentId'] as String? ?? '',
      studentName: m['studentName'] as String? ?? '',
      studentNameChinese: m['studentNameChinese'] as String? ?? '',
      sessionId: m['sessionId'] as String? ?? '',
      partIndex: (m['partIndex'] as num?)?.toInt() ?? 0,
      partCount: (m['partCount'] as num?)?.toInt() ?? 0,
      partEndsAt: (m['partEndsAt'] as Timestamp?)?.toDate(),
      leftCount: (m['leftCount'] as num?)?.toInt() ?? 0,
      events: (m['events'] as List? ?? const []).map((e) {
        final em = Map<String, dynamic>.from(e as Map);
        return TestEvent(
          type: em['type'] as String? ?? 'left',
          at: DateTime.fromMillisecondsSinceEpoch(
              (em['at'] as num?)?.toInt() ?? 0),
          part: (em['part'] as num?)?.toInt(),
        );
      }).toList(),
      finishedAt: (m['finishedAt'] as Timestamp?)?.toDate(),
      startedAt: (m['startedAt'] as Timestamp?)?.toDate(),
      partClocks: m['partClocks'] != false,
      submitRequested: m['submitRequested'] == true,
      visitor: m['visitor'] == true,
      visitorWhatsapp: m['visitorWhatsapp'] as String? ?? '',
    );
  }
}

/// Marks of one part on a result.
class TestResultPart {
  const TestResultPart({
    required this.skill,
    required this.mark,
    required this.maxScore,
    required this.correct,
    required this.total,
  });

  final TestSkill skill;
  final int mark;
  final int maxScore;
  final int correct;
  final int total;

  factory TestResultPart.fromMap(Map<String, dynamic> m) => TestResultPart(
        skill: TestSkill.fromValue(m['skill'] as String?),
        mark: (m['mark'] as num?)?.toInt() ?? 0,
        maxScore: (m['maxScore'] as num?)?.toInt() ?? 0,
        correct: (m['correct'] as num?)?.toInt() ?? 0,
        total: (m['total'] as num?)?.toInt() ?? 0,
      );
}

/// A result (`test_results/{codeId_uid}`), written by functions.
class TestResult {
  const TestResult({
    required this.id,
    required this.codeId,
    required this.code,
    required this.family,
    required this.level,
    required this.levelKey,
    required this.studentId,
    required this.studentName,
    required this.studentNameChinese,
    required this.sessionId,
    required this.openedBy,
    required this.supervisorName,
    required this.parts,
    required this.total,
    required this.max,
    required this.passMark,
    required this.passed,
    required this.valid,
    required this.invalidReason,
    required this.status,
    required this.resultNumber,
    this.releaseYear,
    this.leftCount = 0,
    this.finishedAt,
    this.placement = false,
  });

  /// Build 3: sat in a placement session (off the board and the count).
  final bool placement;

  final String id;
  final String codeId;
  final String code;
  final TestFamily family;
  final String level;
  final String levelKey;
  final String studentId;
  final String studentName;
  final String studentNameChinese;
  final String sessionId;
  final String openedBy;
  final String supervisorName;
  final List<TestResultPart> parts;
  final int total;
  final int max;
  final int passMark;
  final bool passed;
  final bool valid;
  final String invalidReason;
  final String status;
  final String resultNumber;
  final int? releaseYear;
  final int leftCount;
  final DateTime? finishedAt;

  String get examTypeChinese => chineseExamType(family, levelKey);

  /// Build 2A: an answer waits for a teacher (free writing, half-credit
  /// typing); there is no pass or fail yet.
  bool get isPendingMarking => status == 'pending_marking';

  factory TestResult.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    return TestResult(
      id: doc.id,
      codeId: m['codeId'] as String? ?? '',
      code: m['code'] as String? ?? '',
      family: TestFamily.fromValue(m['family'] as String?),
      level: m['level'] as String? ?? '',
      levelKey: m['levelKey'] as String? ?? '',
      studentId: m['studentId'] as String? ?? '',
      studentName: m['studentName'] as String? ?? '',
      studentNameChinese: m['studentNameChinese'] as String? ?? '',
      sessionId: m['sessionId'] as String? ?? '',
      openedBy: m['openedBy'] as String? ?? '',
      supervisorName: m['supervisorName'] as String? ?? '',
      parts: (m['parts'] as List? ?? const [])
          .map((p) =>
              TestResultPart.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
      total: (m['total'] as num?)?.toInt() ?? 0,
      max: (m['max'] as num?)?.toInt() ?? 0,
      passMark: (m['passMark'] as num?)?.toInt() ?? 0,
      passed: m['passed'] == true,
      valid: m['valid'] != false,
      invalidReason: m['invalidReason'] as String? ?? '',
      status: m['status'] as String? ?? 'final',
      resultNumber: m['resultNumber'] as String? ?? '',
      releaseYear: (m['releaseYear'] as num?)?.toInt(),
      leftCount: (m['leftCount'] as num?)?.toInt() ?? 0,
      finishedAt: (m['finishedAt'] as Timestamp?)?.toDate(),
      placement: m['placement'] == true,
    );
  }
}
