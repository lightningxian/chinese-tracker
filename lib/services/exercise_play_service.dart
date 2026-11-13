import 'package:cloud_functions/cloud_functions.dart';

import '../models/exercise.dart';
import '../models/exercise_category.dart';
import '../models/exercise_type.dart';

/// Thrown by [ExercisePlayService.start] for an exercise made before the
/// question bank (questions and keys inside the exercise doc). Those are no
/// longer playable: the keys would be readable and the score would be
/// written by the client (closed 2026-11-12).
class LegacyExerciseException implements Exception {
  const LegacyExerciseException();
}

/// One question as the student plays it: no answer key on board. Questions
/// come from the `startExercise` function; the key and the explanation come
/// back only with the review from [ExercisePlaySession.finish].
class PlayQuestion {
  const PlayQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.segments = const [],
    this.keyword = '',
    this.imageUrl = '',
    this.audioUrl = '',
    this.blankNumber,
    this.optionImageUrls = const [],
    this.skill = '',
    this.section = '',
    this.sectionAudioUrl = '',
  });

  final String id;
  final ExerciseType type;
  final String prompt;

  /// Picture choices: one image per entry of [options] (HSK listening
  /// part 1). Empty for text choices.
  final List<String> optionImageUrls;

  /// Skill the question counts for (`listening`, `reading`, `typing`), as
  /// stored in the bank; used for the marks per part of an HSK paper.
  final String skill;

  /// Heading of the part of the paper (`一、听力 · 第一部分 · 第1-5题`),
  /// empty for plain worksheets.
  final String section;

  /// One recording for the whole listening part; the same URL on every
  /// question of that part.
  final String sectionAudioUrl;

  /// Choices (multiple choice, listening) or the shared word bank
  /// (matching, fill in the blank).
  final List<String> options;

  /// Compose sentences: the parts, already shuffled.
  final List<String> segments;

  /// Pinyin hint (type the hanzi) or the word to use (picture sentence).
  final String keyword;
  final String imageUrl;
  final String audioUrl;
  final int? blankNumber;

  bool get isTyped =>
      type == ExerciseType.typeHanzi || type == ExerciseType.pictureSentence;
  bool get usesWordBank =>
      type == ExerciseType.matching || type == ExerciseType.readingCloze;
  bool get isCompose => type == ExerciseType.composeSentences;
  bool get hasPictureOptions => optionImageUrls.isNotEmpty;

  factory PlayQuestion.fromServer(Map<String, dynamic> m) => PlayQuestion(
        id: m['id'] as String? ?? '',
        type: ExerciseType.fromValue(m['type'] as String?),
        prompt: m['prompt'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? const []),
        segments: List<String>.from(m['segments'] as List? ?? const []),
        keyword: m['keyword'] as String? ?? '',
        imageUrl: m['imageUrl'] as String? ?? '',
        audioUrl: m['audioUrl'] as String? ?? '',
        blankNumber: (m['blankNumber'] as num?)?.toInt(),
        optionImageUrls:
            List<String>.from(m['optionImageUrls'] as List? ?? const []),
        skill: m['skill'] as String? ?? '',
        section: m['section'] as String? ?? '',
        sectionAudioUrl: m['sectionAudioUrl'] as String? ?? '',
      );
}

/// What the student answered: exactly one of the three fields is set.
class PlayAnswer {
  const PlayAnswer.index(int this.index)
      : order = null,
        text = null;
  const PlayAnswer.order(List<String> this.order)
      : index = null,
        text = null;
  const PlayAnswer.text(String this.text)
      : index = null,
        order = null;

  final int? index;
  final List<String>? order;
  final String? text;

  Map<String, dynamic> toJson() => {
        if (index != null) 'index': index,
        if (order != null) 'order': order,
        if (text != null) 'text': text,
      };
}

/// Outcome of one question in the review, with the key for the result page.
class AnswerCheck {
  const AnswerCheck({
    required this.correct,
    this.answered = true,
    this.correctIndex,
    this.correctOrder = const [],
    this.accepted = const [],
    this.keyword = '',
    this.explanation = '',
  });

  final bool correct;

  /// False when the student skipped the question (counted as wrong).
  final bool answered;
  final int? correctIndex;
  final List<String> correctOrder;
  final List<String> accepted;
  final String keyword;

  /// The teacher's note on why the key is right; empty when none.
  final String explanation;

  factory AnswerCheck.fromServer(Map<String, dynamic> m) {
    final key =
        Map<String, dynamic>.from(m['correctAnswer'] as Map? ?? const {});
    return AnswerCheck(
      correct: m['correct'] == true,
      answered: m['answered'] != false,
      correctIndex: (key['index'] as num?)?.toInt(),
      correctOrder: List<String>.from(key['order'] as List? ?? const []),
      accepted: List<String>.from(key['accepted'] as List? ?? const []),
      keyword: key['keyword'] as String? ?? '',
      explanation: m['explanation'] as String? ?? '',
    );
  }
}

/// What the player knows before fetching the questions (`startExercise`
/// with `peek`): exams and HSK simulations allow one attempt and show a
/// start screen first.
class ExercisePeek {
  const ExercisePeek({
    required this.category,
    required this.oneAttempt,
    required this.questionCount,
    this.timeLimitMinutes,
    this.started = false,
    this.finished = false,
    this.remainingSeconds,
  });

  final ExerciseCategory category;
  final bool oneAttempt;
  final int questionCount;
  final int? timeLimitMinutes;

  /// One-attempt only: the clock already runs (reload) / the attempt is over.
  final bool started;
  final bool finished;
  final int? remainingSeconds;

  factory ExercisePeek.fromServer(Map<String, dynamic> m) => ExercisePeek(
        category: ExerciseCategory.fromValue(m['category'] as String?),
        oneAttempt: m['oneAttempt'] == true,
        questionCount: (m['questionCount'] as num?)?.toInt() ?? 0,
        timeLimitMinutes: (m['timeLimitMinutes'] as num?)?.toInt(),
        started: m['started'] == true,
        finished: m['finished'] == true,
        remainingSeconds: (m['remainingSeconds'] as num?)?.toInt(),
      );
}

/// Right answers out of the questions of one skill (HSK part).
class SkillScore {
  const SkillScore({required this.correct, required this.total});
  final int correct;
  final int total;

  /// 0–100, the way HSK reports each part.
  int get scaled => total == 0 ? 0 : ((correct / total) * 100).round();
}

class PlayResult {
  const PlayResult({
    required this.score,
    required this.correct,
    required this.total,
    this.durationSeconds,
    this.review = const {},
    this.late = false,
    this.bySkill = const {},
  });

  /// Marks per skill (`listening`, `reading`, `typing`…), when the server
  /// sent them.
  final Map<String, SkillScore> bySkill;

  final int score;
  final int correct;
  final int total;
  final int? durationSeconds;

  /// One-attempt exam submitted after the server clock ran out: not scored.
  final bool late;

  /// Review by question id, in no particular order: the screen walks its
  /// own question list.
  final Map<String, AnswerCheck> review;
}

/// A running attempt. Built by [ExercisePlayService.start]; the screen only
/// sees questions, stores answers, and gets the review with the final score.
abstract class ExercisePlaySession {
  Exercise get exercise;
  List<PlayQuestion> get questions;
  String get passage;

  /// Type of exercise of the package (its first worksheet's).
  ExerciseCategory get category;

  /// Seconds left on the server clock of a one-attempt exam, else null (the
  /// player then uses the package's own time limit from the start).
  int? get remainingSeconds;

  /// Answers given so far, by question id (read-only view).
  Map<String, PlayAnswer> get answers;

  /// Records the student's answer to [question]; null clears it.
  void answer(PlayQuestion question, PlayAnswer? answer);

  /// Scores the whole attempt and records the result. Call once, at the end;
  /// [durationSeconds] is the time the student took.
  Future<PlayResult> finish({required int durationSeconds});
}

class ExercisePlayService {
  ExercisePlayService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// What the exercise is, without fetching the questions or starting the
  /// clock of a one-attempt exam.
  Future<ExercisePeek> peek(Exercise exercise) async {
    if (!exercise.isPackage) throw const LegacyExerciseException();
    final result = await _functions
        .httpsCallable('startExercise')
        .call({'exerciseId': exercise.id, 'peek': true});
    return ExercisePeek.fromServer(
        Map<String, dynamic>.from(result.data as Map));
  }

  /// Asks `startExercise` for the questions (and starts the server clock of
  /// a one-attempt exam). Throws [FirebaseFunctionsException]
  /// (`permission-denied` when the exercise is not assigned to the student,
  /// `failed-precondition` with details `reason: already-attempted`) or
  /// [LegacyExerciseException].
  Future<ExercisePlaySession> start(Exercise exercise) async {
    if (!exercise.isPackage) throw const LegacyExerciseException();
    final result = await _functions
        .httpsCallable('startExercise')
        .call({'exerciseId': exercise.id});
    final data = Map<String, dynamic>.from(result.data as Map);
    final questions = (data['questions'] as List? ?? const [])
        .map(
            (q) => PlayQuestion.fromServer(Map<String, dynamic>.from(q as Map)))
        .toList();
    return _ServerSession(
      exercise: exercise,
      questions: questions,
      remainingSeconds: (data['remainingSeconds'] as num?)?.toInt(),
      category: ExerciseCategory.fromValue(data['category'] as String?),
      functions: _functions,
    );
  }
}

/// Keeps the student's answers until the attempt is submitted.
abstract class _AnswerStore implements ExercisePlaySession {
  final Map<String, PlayAnswer> _answers = {};

  @override
  Map<String, PlayAnswer> get answers => Map.unmodifiable(_answers);

  @override
  void answer(PlayQuestion question, PlayAnswer? answer) {
    if (answer == null) {
      _answers.remove(question.id);
    } else {
      _answers[question.id] = answer;
    }
  }
}

/// Package: questions come from Cloud Functions, and `finishExercise` checks
/// every answer at once, writes the result and returns the review.
class _ServerSession extends _AnswerStore {
  _ServerSession({
    required this.exercise,
    required this.questions,
    required this.remainingSeconds,
    required this.category,
    required FirebaseFunctions functions,
  }) : _functions = functions;

  @override
  final Exercise exercise;
  @override
  final List<PlayQuestion> questions;
  @override
  final int? remainingSeconds;
  @override
  final ExerciseCategory category;
  @override
  String get passage => exercise.passage;

  final FirebaseFunctions _functions;

  @override
  Future<PlayResult> finish({required int durationSeconds}) async {
    final result = await _functions.httpsCallable('finishExercise').call({
      'exerciseId': exercise.id,
      'answers': {
        for (final entry in _answers.entries) entry.key: entry.value.toJson(),
      },
      'durationSeconds': durationSeconds,
    });
    final m = Map<String, dynamic>.from(result.data as Map);
    final review = <String, AnswerCheck>{};
    for (final item in m['review'] as List? ?? const []) {
      final entry = Map<String, dynamic>.from(item as Map);
      final id = entry['questionId'] as String? ?? '';
      if (id.isNotEmpty) review[id] = AnswerCheck.fromServer(entry);
    }
    final bySkill = <String, SkillScore>{};
    final rawSkills = m['bySkill'];
    if (rawSkills is Map) {
      for (final entry in rawSkills.entries) {
        final v = entry.value;
        if (v is Map) {
          bySkill['${entry.key}'] = SkillScore(
            correct: (v['correct'] as num?)?.toInt() ?? 0,
            total: (v['total'] as num?)?.toInt() ?? 0,
          );
        }
      }
    }
    return PlayResult(
      score: (m['score'] as num?)?.toInt() ?? 0,
      correct: (m['correct'] as num?)?.toInt() ?? 0,
      total: (m['total'] as num?)?.toInt() ?? questions.length,
      durationSeconds: durationSeconds,
      review: review,
      late: m['late'] == true,
      bySkill: bySkill,
    );
  }
}
