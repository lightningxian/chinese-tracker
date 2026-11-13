import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise.dart';
import 'exercise_category.dart';
import 'exercise_skill_category.dart';
import 'exercise_type.dart';

/// A reusable question in the shared question bank. Wraps an
/// [ExerciseQuestion] (using the same serialization) so a bank question drops
/// straight into an exercise/quiz. Ownership mirrors lessons/exercises via
/// [ownerId] (`AppConstants.contentTeacherId`).
///
/// Questions scanned from one of the centre's worksheets remember the sheet
/// ([sheetCode], [sheetTitle], [sheetIndex]) so the bank can show the sheet as
/// one entry and the exercise form can add it whole.
class QuestionBankItem {
  const QuestionBankItem({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.question,
    this.skillCategory,
    this.level,
    this.category = ExerciseCategory.exercise,
    this.tags = const [],
    this.sheetCode,
    this.sheetTitle,
    this.sheetIndex,
    this.section,
    this.sectionAudioUrl,
    this.usageCount = 0,
    this.lastUsedAt,
    this.updatedAt,
    this.sourceExerciseId,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final ExerciseType type;
  final ExerciseQuestion question;
  final ExerciseSkillCategory? skillCategory;
  final String? level;

  /// Exercise, quiz, exam or HSK simulation: the same on every question of
  /// a worksheet.
  final ExerciseCategory category;
  final List<String> tags;

  /// Worksheet code printed on the sheet, e.g. `310001-RDG`.
  final String? sheetCode;

  /// Title printed on the sheet, e.g. `Soal Latihan HSK 3 A`.
  final String? sheetTitle;

  /// Position of the question on the sheet (0-based), keeps the sheet order.
  final int? sheetIndex;

  /// Heading of the part of the paper this question belongs to, e.g.
  /// `一、听力 · 第一部分 · 第1-5题` on an HSK paper. The player shows it
  /// above the first question of each part. Null for plain worksheets.
  final String? section;

  /// Audio of the listening part (one recording for the whole part, as the
  /// real HSK plays it). Stored on every listening question of the sheet;
  /// the player shows one player while those questions are open.
  final String? sectionAudioUrl;

  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime? updatedAt;
  final String? sourceExerciseId;
  final String? createdBy;
  final DateTime? createdAt;

  /// The centre's sheet codes: six or seven digits, a dash and the form
  /// letters (`310001-RDG`, `300001-KLM`).
  static final sheetCodePattern = RegExp(r'^\d{6,7}-(RDG|KLM|WRT|CRT|KK)$');

  /// The worksheet this question belongs to, or null for a question typed or
  /// pasted on its own. Questions imported before [sheetCode] existed carry
  /// the code as their first tag, so that counts too.
  String? get sheetKey {
    if (sheetCode != null && sheetCode!.isNotEmpty) return sheetCode;
    for (final tag in tags) {
      if (sheetCodePattern.hasMatch(tag)) return tag;
    }
    return null;
  }

  String get prompt => question.prompt;

  /// What identifies the question when shown in a list: the prompt, or for a
  /// compose item its sentence, or the keyword of a picture / hanzi item.
  String get displayText {
    if (prompt.trim().isNotEmpty) return prompt;
    if (question.segments.isNotEmpty) return question.segments.join(' / ');
    if (question.keyword.isNotEmpty) return question.keyword;
    return '';
  }

  /// Dedupe key: same content + type = already in bank. Built from
  /// [displayText], so compose items (which have no prompt) stay distinct.
  String get dedupeKey => '${type.value}::${displayText.trim().toLowerCase()}';

  factory QuestionBankItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final type = ExerciseType.fromValue(data['type'] as String?);
    return QuestionBankItem(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      type: type,
      question: ExerciseQuestion.fromMap(
        Map<String, dynamic>.from(data['question'] as Map? ?? data),
        exerciseType: type,
      ),
      skillCategory: data['skillCategory'] == null
          ? null
          : ExerciseSkillCategory.fromValue(data['skillCategory'] as String?),
      level: data['level'] as String?,
      category: ExerciseCategory.fromValue(data['category'] as String?),
      tags: List<String>.from(data['tags'] as List? ?? const []),
      sheetCode: data['sheetCode'] as String?,
      sheetTitle: data['sheetTitle'] as String?,
      sheetIndex: (data['sheetIndex'] as num?)?.toInt(),
      section: data['section'] as String?,
      sectionAudioUrl: data['sectionAudioUrl'] as String?,
      usageCount: data['usageCount'] as int? ?? 0,
      lastUsedAt: (data['lastUsedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      sourceExerciseId: data['sourceExerciseId'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'type': type.value,
        'prompt': question.prompt,
        'question': question.toMap(type),
        if (skillCategory != null) 'skillCategory': skillCategory!.value,
        if (level != null && level!.isNotEmpty) 'level': level,
        'category': category.value,
        'tags': tags,
        if (sheetCode != null && sheetCode!.isNotEmpty) 'sheetCode': sheetCode,
        if (sheetTitle != null && sheetTitle!.isNotEmpty)
          'sheetTitle': sheetTitle,
        if (sheetIndex != null) 'sheetIndex': sheetIndex,
        if (section != null && section!.isNotEmpty) 'section': section,
        if (sectionAudioUrl != null && sectionAudioUrl!.isNotEmpty)
          'sectionAudioUrl': sectionAudioUrl,
        'usageCount': usageCount,
        if (sourceExerciseId != null && sourceExerciseId!.isNotEmpty)
          'sourceExerciseId': sourceExerciseId,
      };

  QuestionBankItem copyWith({
    String? id,
    String? ownerId,
    ExerciseType? type,
    ExerciseQuestion? question,
    ExerciseSkillCategory? skillCategory,
    String? level,
    ExerciseCategory? category,
    List<String>? tags,
    String? sheetCode,
    String? sheetTitle,
    int? sheetIndex,
    String? section,
    String? sectionAudioUrl,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? updatedAt,
    String? sourceExerciseId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return QuestionBankItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      question: question ?? this.question,
      skillCategory: skillCategory ?? this.skillCategory,
      level: level ?? this.level,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      sheetCode: sheetCode ?? this.sheetCode,
      sheetTitle: sheetTitle ?? this.sheetTitle,
      sheetIndex: sheetIndex ?? this.sheetIndex,
      section: section ?? this.section,
      sectionAudioUrl: sectionAudioUrl ?? this.sectionAudioUrl,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceExerciseId: sourceExerciseId ?? this.sourceExerciseId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// The questions of one worksheet (or one question on its own), as the bank
/// lists them. Built by [QuestionBankSheet.group] from a flat bank.
class QuestionBankSheet {
  const QuestionBankSheet({required this.key, required this.items});

  /// [QuestionBankItem.sheetKey], or null for a stand-alone question.
  final String? key;

  /// In sheet order.
  final List<QuestionBankItem> items;

  bool get isSheet => key != null;
  QuestionBankItem get first => items.first;
  int get count => items.length;
  int get usageCount => items.fold(0, (total, item) => total + item.usageCount);

  /// Sheet code, or the single question's text.
  String get code => key ?? first.displayText;

  /// What the row shows: the printed title when known, else the code.
  String get title {
    if (!isSheet) {
      return first.displayText.isEmpty ? '(no prompt)' : first.displayText;
    }
    for (final item in items) {
      final t = item.sheetTitle;
      if (t != null && t.trim().isNotEmpty) return t.trim();
    }
    return key!;
  }

  ExerciseType get type => first.type;
  String? get level => first.level;
  ExerciseCategory get category => first.category;

  /// Part headings in sheet order, without repeats.
  List<String> get sections => [
        for (final item in items)
          if (item.section != null && item.section!.trim().isNotEmpty)
            item.section!.trim(),
      ].fold<List<String>>([], (acc, s) => acc.contains(s) ? acc : (acc..add(s)));

  /// The questions a listening recording belongs to: the listening-skill
  /// ones, or every question when the sheet has no skill split.
  List<QuestionBankItem> get listeningItems {
    final listening = items
        .where((i) => i.skillCategory == ExerciseSkillCategory.listening)
        .toList();
    return listening.isEmpty ? items : listening;
  }

  /// The listening recording attached to the sheet, if any.
  String? get sectionAudioUrl {
    for (final item in items) {
      final url = item.sectionAudioUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  /// Tags shared by the sheet, without the code itself.
  List<String> get tags => {
        for (final item in items)
          for (final t in item.tags)
            if (t != key) t,
      }.toList();

  /// Groups a flat bank into sheets and stand-alone questions. Sheets keep
  /// the order of [items] (newest first in the bank stream); inside a sheet
  /// the questions follow [QuestionBankItem.sheetIndex], else creation order.
  static List<QuestionBankSheet> group(Iterable<QuestionBankItem> items) {
    final bySheet = <String, List<QuestionBankItem>>{};
    final out = <QuestionBankSheet>[];
    for (final item in items) {
      final key = item.sheetKey;
      if (key == null) {
        out.add(QuestionBankSheet(key: null, items: [item]));
        continue;
      }
      final list = bySheet[key];
      if (list == null) {
        final fresh = [item];
        bySheet[key] = fresh;
        out.add(QuestionBankSheet(key: key, items: fresh));
      } else {
        list.add(item);
      }
    }
    for (final list in bySheet.values) {
      list.sort(_bySheetOrder);
    }
    return out;
  }

  static int _bySheetOrder(QuestionBankItem a, QuestionBankItem b) {
    final ai = a.sheetIndex, bi = b.sheetIndex;
    if (ai != null && bi != null) return ai.compareTo(bi);
    if (ai != null) return -1;
    if (bi != null) return 1;
    final ac = a.createdAt, bc = b.createdAt;
    if (ac != null && bc != null) return ac.compareTo(bc);
    return 0;
  }
}
