/// What the AI reader returns for one scanned paper (see
/// `WorksheetAiImportService`): the paper's parts in printed order, each
/// question typed the way the bank stores it, plus the boxes of any
/// pictures to cut out of the page images.
class AiBox {
  const AiBox({
    required this.page,
    required this.ymin,
    required this.xmin,
    required this.ymax,
    required this.xmax,
  });

  /// 1-based page of the file (1 for an image).
  final int page;

  /// 0–1000 fractions of the page, the way Gemini reports boxes.
  final int ymin;
  final int xmin;
  final int ymax;
  final int xmax;

  bool get isValid =>
      page >= 1 && ymax > ymin && xmax > xmin && ymin >= 0 && xmin >= 0;

  /// Same box on the same page → same picture (a group of questions shares
  /// its pictures).
  String get key => 'p$page-$ymin-$xmin-$ymax-$xmax';

  static AiBox? fromJson(Object? raw, {required int page}) {
    if (raw is! List || raw.length != 4) return null;
    final v = raw.map((n) => (n as num?)?.round() ?? -1).toList();
    final box = AiBox(page: page, ymin: v[0], xmin: v[1], ymax: v[2], xmax: v[3]);
    return box.isValid ? box : null;
  }
}

class AiQuestion {
  const AiQuestion({
    required this.number,
    required this.type,
    required this.page,
    this.prompt = '',
    this.options = const [],
    this.correctIndex,
    this.segments = const [],
    this.keyword = '',
    this.accepted = const [],
    this.imageBox,
    this.optionImageBoxes = const [],
  });

  /// Printed number (1-based).
  final int number;

  /// One of `picture_choice`, `true_false`, `choice`, `matching`, `cloze`,
  /// `reorder`, `write_hanzi`, `sentence_with_word`.
  final String type;
  final int page;
  final String prompt;
  final List<String> options;

  /// 0-based index of the right choice; null when the paper has no key and
  /// the reader could not work it out (listening without a transcript).
  final int? correctIndex;
  final List<String> segments;
  final String keyword;
  final List<String> accepted;

  /// A picture that belongs to the question itself.
  final AiBox? imageBox;

  /// Picture choices, in letter order.
  final List<AiBox> optionImageBoxes;

  factory AiQuestion.fromJson(Map<String, dynamic> m) {
    final page = (m['page'] as num?)?.toInt() ?? 1;
    final index = (m['correctIndex'] as num?)?.toInt();
    return AiQuestion(
      number: (m['number'] as num?)?.toInt() ?? 0,
      type: (m['type'] as String? ?? 'choice').trim(),
      page: page < 1 ? 1 : page,
      prompt: (m['prompt'] as String? ?? '').trim(),
      options: _strings(m['options']),
      correctIndex: index == null || index < 0 ? null : index,
      segments: _strings(m['segments']),
      keyword: (m['keyword'] as String? ?? '').trim(),
      accepted: _strings(m['accepted']),
      imageBox: AiBox.fromJson(m['imageBox'], page: page),
      optionImageBoxes: [
        for (final raw in m['optionImageBoxes'] as List? ?? const [])
          if (AiBox.fromJson(raw, page: page) case final box?) box,
      ],
    );
  }
}

class AiSection {
  const AiSection({
    required this.title,
    required this.skill,
    this.instructions = '',
    this.questions = const [],
  });

  /// Printed heading, e.g. `一、听力 · 第一部分 · 第1-5题`.
  final String title;

  /// `listening`, `reading` or `writing`.
  final String skill;
  final String instructions;
  final List<AiQuestion> questions;

  factory AiSection.fromJson(Map<String, dynamic> m) => AiSection(
        title: (m['title'] as String? ?? '').trim(),
        skill: (m['skill'] as String? ?? 'reading').trim(),
        instructions: (m['instructions'] as String? ?? '').trim(),
        questions: [
          for (final raw in m['questions'] as List? ?? const [])
            if (raw is Map)
              AiQuestion.fromJson(Map<String, dynamic>.from(raw)),
        ],
      );
}

class AiWorksheet {
  const AiWorksheet({
    this.title = '',
    this.code = '',
    this.hskLevel,
    this.category = '',
    this.sections = const [],
  });

  final String title;

  /// Code printed on the paper (`H326202Z`), empty when none.
  final String code;

  /// 1–6, null when the paper does not say.
  final int? hskLevel;

  /// `exercise`, `quiz`, `exam` or `hsk_simulation`.
  final String category;
  final List<AiSection> sections;

  List<AiQuestion> get questions => [
        for (final s in sections) ...s.questions,
      ];

  /// Every distinct picture to cut out, by [AiBox.key].
  Map<String, AiBox> get boxes => {
        for (final q in questions) ...{
          if (q.imageBox case final box?) box.key: box,
          for (final box in q.optionImageBoxes) box.key: box,
        },
      };

  factory AiWorksheet.fromJson(Map<String, dynamic> m) {
    final level = (m['hskLevel'] as num?)?.toInt();
    return AiWorksheet(
      title: (m['title'] as String? ?? '').trim(),
      code: (m['code'] as String? ?? '').trim(),
      hskLevel: level == null || level < 1 || level > 6 ? null : level,
      category: (m['category'] as String? ?? '').trim(),
      sections: [
        for (final raw in m['sections'] as List? ?? const [])
          if (raw is Map) AiSection.fromJson(Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

List<String> _strings(Object? raw) => [
      for (final v in raw as List? ?? const [])
        if (v != null && '$v'.trim().isNotEmpty) '$v'.trim(),
    ];
