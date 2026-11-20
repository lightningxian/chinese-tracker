import 'app_user.dart';

/// Build 3: what a placement result code shows (the register form, the
/// Approval card). Never the visitor's name or number.
class PlacementSummary {
  const PlacementSummary({
    required this.resultCode,
    required this.level,
    required this.total,
    required this.max,
    required this.passed,
    required this.recommendedLevel,
    required this.claimed,
    this.code = '',
    this.claimedBy = '',
  });

  final String resultCode;
  final String code;
  final String level;
  final int total;
  final int max;
  final bool passed;
  final String recommendedLevel;
  final bool claimed;

  /// Only on the admin's Approval card (`registrationPlacement`).
  final String claimedBy;

  factory PlacementSummary.fromMap(Map<String, dynamic> m) => PlacementSummary(
        resultCode: m['resultCode'] as String? ?? '',
        code: m['code'] as String? ?? '',
        level: m['level'] as String? ?? '',
        total: (m['total'] as num?)?.toInt() ?? 0,
        max: (m['max'] as num?)?.toInt() ?? 0,
        passed: m['passed'] == true,
        recommendedLevel: m['recommendedLevel'] as String? ?? '',
        claimed: m['claimed'] == true,
        claimedBy: m['claimedBy'] as String? ?? '',
      );

  /// Claimed by someone other than [uid].
  bool claimedByOther(String uid) =>
      claimed && claimedBy.isNotEmpty && claimedBy != uid;
}

/// Why a registration choice cannot be sent yet.
enum RegistrationChoiceIssue {
  /// "Ikut tes penempatan" without a target level.
  targetMissing,

  /// A result code that is not 6 letters/digits from the code alphabet.
  resultCodeInvalid,

  /// A result code typed but not checked (or changed since the check).
  resultCodeUnchecked,

  /// The checked code is already used by another student.
  resultCodeClaimed,
}

/// The start-level choice of the register form (Build 3, Must 1): start at
/// HSK 1, or ask for a placement test with a target level HSK 2-6, plus an
/// optional result code of a public placement test.
class RegistrationChoice {
  const RegistrationChoice({
    this.choice = AppUser.choiceHsk1,
    this.target = '',
    this.resultCode = '',
    this.checked,
  });

  final String choice;
  final String target;
  final String resultCode;

  /// The resolved summary of [resultCode], when it was checked.
  final PlacementSummary? checked;

  static const targets = ['HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'];
  static const codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  bool get wantsTest => choice == AppUser.choiceTest;

  /// Upper case without spaces and dashes; "" when it cannot be a code.
  static String normalizeCode(String raw) {
    final v = raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (v.length != 6) return '';
    for (final ch in v.split('')) {
      if (!codeAlphabet.contains(ch)) return '';
    }
    return v;
  }

  RegistrationChoice copyWith({
    String? choice,
    String? target,
    String? resultCode,
    PlacementSummary? checked,
    bool clearChecked = false,
  }) =>
      RegistrationChoice(
        choice: choice ?? this.choice,
        target: target ?? this.target,
        resultCode: resultCode ?? this.resultCode,
        checked: clearChecked ? null : (checked ?? this.checked),
      );

  /// The first thing that stops the form, or null when it can be sent.
  RegistrationChoiceIssue? get issue {
    if (wantsTest && !targets.contains(target)) {
      return RegistrationChoiceIssue.targetMissing;
    }
    final raw = resultCode.trim();
    if (raw.isEmpty) return null;
    final code = normalizeCode(raw);
    if (code.isEmpty) return RegistrationChoiceIssue.resultCodeInvalid;
    final c = checked;
    if (c == null || c.resultCode != code) {
      return RegistrationChoiceIssue.resultCodeUnchecked;
    }
    if (c.claimed) return RegistrationChoiceIssue.resultCodeClaimed;
    return null;
  }

  /// Fields stored on the new `users` doc (the rules require all three).
  Map<String, String> toFields() => {
        'placementChoice': choice,
        'placementTarget': wantsTest ? target : '',
        'placementResultCode': normalizeCode(resultCode.trim()),
      };
}

/// A placement code in the public menu (`placementMenu`).
class PlacementMenuEntry {
  const PlacementMenuEntry({
    required this.codeId,
    required this.level,
    required this.title,
    required this.minutes,
    required this.parts,
  });

  final String codeId;
  final String level;
  final String title;
  final int minutes;
  final List<({String skill, int minutes, int questions})> parts;

  int get questions => parts.fold(0, (s, p) => s + p.questions);

  factory PlacementMenuEntry.fromMap(Map<String, dynamic> m) =>
      PlacementMenuEntry(
        codeId: m['codeId'] as String? ?? '',
        level: m['level'] as String? ?? '',
        title: m['title'] as String? ?? '',
        minutes: (m['minutes'] as num?)?.toInt() ?? 0,
        parts: [
          for (final p in (m['parts'] as List? ?? const []))
            (
              skill: (p as Map)['skill'] as String? ?? '',
              minutes: (p['minutes'] as num?)?.toInt() ?? 0,
              questions: (p['questions'] as num?)?.toInt() ?? 0,
            ),
        ],
      );
}

/// What the visitor's result page shows.
class VisitorResult {
  const VisitorResult({
    required this.level,
    required this.parts,
    required this.total,
    required this.max,
    required this.passed,
    required this.recommendedLevel,
    required this.resultCode,
  });

  final String level;
  final List<({String skill, int mark, int maxScore})> parts;
  final int total;
  final int max;
  final bool passed;
  final String recommendedLevel;
  final String resultCode;

  factory VisitorResult.fromMap(Map<String, dynamic> m) => VisitorResult(
        level: m['level'] as String? ?? '',
        parts: [
          for (final p in (m['parts'] as List? ?? const []))
            (
              skill: (p as Map)['skill'] as String? ?? '',
              mark: (p['mark'] as num?)?.toInt() ?? 0,
              maxScore: (p['maxScore'] as num?)?.toInt() ?? 0,
            ),
        ],
        total: (m['total'] as num?)?.toInt() ?? 0,
        max: (m['max'] as num?)?.toInt() ?? 0,
        passed: m['passed'] == true,
        recommendedLevel: m['recommendedLevel'] as String? ?? '',
        resultCode: m['resultCode'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'level': level,
        'parts': [
          for (final p in parts)
            {'skill': p.skill, 'mark': p.mark, 'maxScore': p.maxScore},
        ],
        'total': total,
        'max': max,
        'passed': passed,
        'recommendedLevel': recommendedLevel,
        'resultCode': resultCode,
      };
}
