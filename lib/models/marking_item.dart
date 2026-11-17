import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_type.dart';

/// Why an answer waits for a teacher (Build 2A).
enum MarkingReason {
  /// Typed hanzi one character off: half credit for now.
  oneCharacter('one_character'),

  /// Typed pinyin with the right letters and a wrong or missing tone.
  tone('tone'),

  /// Free writing: never scored by the machine, marked with the rubric.
  freeWriting('free_writing');

  const MarkingReason(this.value);
  final String value;

  static MarkingReason fromValue(String? v) => MarkingReason.values
      .firstWhere((r) => r.value == v, orElse: () => MarkingReason.freeWriting);
}

/// Rubric for free writing (thesis spec section 7): grammar 40,
/// vocabulary 30, content 30.
abstract final class MarkingRubric {
  static const grammar = 40;
  static const vocabulary = 30;
  static const content = 30;
}

/// One answer in a teacher's marking queue (`marking_items`, written by the
/// scoring functions; students never read it because it carries the keys).
class MarkingItem {
  const MarkingItem({
    required this.id,
    required this.source,
    required this.resultId,
    required this.title,
    required this.studentId,
    required this.studentName,
    required this.questionId,
    required this.type,
    required this.prompt,
    required this.answerText,
    required this.characterCount,
    required this.accepted,
    required this.keywords,
    required this.reason,
    required this.machinePoints,
    required this.maxPoints,
    required this.status,
    this.imageUrl = '',
    this.partIndex,
    this.mark,
    this.markedByName = '',
    this.createdAt,
  });

  final String id;

  /// `test` (a test code) or `package` (a practice package).
  final String source;
  final String resultId;
  final String title;
  final String studentId;
  final String studentName;
  final String questionId;
  final ExerciseType type;
  final String prompt;
  final String imageUrl;
  final String answerText;
  final int characterCount;
  final List<String> accepted;
  final List<String> keywords;
  final MarkingReason reason;
  final double machinePoints;
  final double maxPoints;

  /// `open` or `marked`.
  final String status;
  final int? partIndex;
  final double? mark;
  final String markedByName;
  final DateTime? createdAt;

  bool get isOpen => status == 'open';
  bool get isFreeWriting => reason == MarkingReason.freeWriting;

  /// Required words the answer uses and the ones it misses.
  ({List<String> found, List<String> missing}) get keywordCheck {
    final found = <String>[];
    final missing = <String>[];
    for (final k in keywords) {
      (answerText.contains(k) ? found : missing).add(k);
    }
    return (found: found, missing: missing);
  }

  factory MarkingItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const <String, dynamic>{};
    double num0(Object? v) => (v as num?)?.toDouble() ?? 0;
    return MarkingItem(
      id: doc.id,
      source: m['source'] as String? ?? '',
      resultId: m['resultId'] as String? ?? '',
      title: m['title'] as String? ?? '',
      studentId: m['studentId'] as String? ?? '',
      studentName: m['studentName'] as String? ?? '',
      questionId: m['questionId'] as String? ?? '',
      type: ExerciseType.fromValue(m['type'] as String?),
      prompt: m['prompt'] as String? ?? '',
      imageUrl: m['imageUrl'] as String? ?? '',
      answerText: m['answerText'] as String? ?? '',
      characterCount: (m['characterCount'] as num?)?.toInt() ?? 0,
      accepted: List<String>.from(m['accepted'] as List? ?? const []),
      keywords: List<String>.from(m['keywords'] as List? ?? const []),
      reason: MarkingReason.fromValue(m['reason'] as String?),
      machinePoints: num0(m['machinePoints']),
      maxPoints: num0(m['maxPoints']),
      status: m['status'] as String? ?? 'open',
      partIndex: (m['partIndex'] as num?)?.toInt(),
      mark: (m['mark'] as num?)?.toDouble(),
      markedByName: m['markedByName'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
