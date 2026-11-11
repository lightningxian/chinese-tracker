import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/exercise.dart';
import '../models/exercise_type.dart';
import 'firestore_service.dart';

/// One question as the student plays it: no answer key on board.
///
/// Legacy exercises (questions stored in the exercise doc) still carry the
/// key inside [ExerciseQuestion]; the play screen never reads it directly,
/// it gets the review from [ExercisePlaySession.finish] like it does for
/// packages.
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
  });

  final String id;
  final ExerciseType type;
  final String prompt;

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
  });

  final bool correct;

  /// False when the student skipped the question (counted as wrong).
  final bool answered;
  final int? correctIndex;
  final List<String> correctOrder;
  final List<String> accepted;
  final String keyword;

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
    );
  }
}

class PlayResult {
  const PlayResult({
    required this.score,
    required this.correct,
    required this.total,
    this.durationSeconds,
    this.review = const {},
  });

  final int score;
  final int correct;
  final int total;
  final int? durationSeconds;

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

  /// Answers given so far, by question id (read-only view).
  Map<String, PlayAnswer> get answers;

  /// Records the student's answer to [question]; null clears it.
  void answer(PlayQuestion question, PlayAnswer? answer);

  /// Scores the whole attempt and records the result. Call once, at the end;
  /// [durationSeconds] is the time the student took.
  Future<PlayResult> finish({required int durationSeconds});
}

class ExercisePlayService {
  ExercisePlayService({
    required FirestoreService firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirestoreService _firestore;
  final FirebaseFunctions _functions;

  /// Null when the exercise does not exist or is not assigned to the student.
  Future<ExercisePlaySession?> start(
      Exercise exercise, String studentId) async {
    if (exercise.isPackage) {
      final result = await _functions
          .httpsCallable('startExercise')
          .call({'exerciseId': exercise.id});
      final data = Map<String, dynamic>.from(result.data as Map);
      final questions = (data['questions'] as List? ?? const [])
          .map((q) =>
              PlayQuestion.fromServer(Map<String, dynamic>.from(q as Map)))
          .toList();
      return _ServerSession(
        exercise: exercise,
        questions: questions,
        functions: _functions,
      );
    }
    return _LocalSession(
      exercise: exercise,
      studentId: studentId,
      firestore: _firestore,
    );
  }
}

/// Answer store shared by both kinds of session.
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
    required FirebaseFunctions functions,
  }) : _functions = functions;

  @override
  final Exercise exercise;
  @override
  final List<PlayQuestion> questions;
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
    return PlayResult(
      score: (m['score'] as num?)?.toInt() ?? 0,
      correct: (m['correct'] as num?)?.toInt() ?? 0,
      total: (m['total'] as num?)?.toInt() ?? questions.length,
      durationSeconds: durationSeconds,
      review: review,
    );
  }
}

/// Legacy exercise: questions and keys are in the exercise doc; the attempt
/// is checked here and the result is written by the client as before.
class _LocalSession extends _AnswerStore {
  _LocalSession({
    required this.exercise,
    required String studentId,
    required FirestoreService firestore,
  })  : _studentId = studentId,
        _firestore = firestore,
        questions = [
          for (final (i, q) in exercise.questions.indexed)
            PlayQuestion(
              id: 'q$i',
              type: exercise.type,
              prompt: q.prompt,
              options: exercise.type == ExerciseType.matching ||
                      exercise.type == ExerciseType.readingCloze
                  ? exercise.matchingOptions
                  : q.options,
              segments: exercise.type == ExerciseType.composeSentences
                  ? (List<String>.from(q.segments)..shuffle(Random(i)))
                  : const [],
              keyword: q.keyword,
              imageUrl: q.imageUrl,
              audioUrl: q.audioUrl,
              blankNumber: q.blankNumber,
            ),
        ];

  @override
  final Exercise exercise;
  @override
  final List<PlayQuestion> questions;
  @override
  String get passage => exercise.passage;

  final String _studentId;
  final FirestoreService _firestore;

  AnswerCheck _check(int index, PlayAnswer? answer) {
    final question = questions[index];
    final source = exercise.questions[index];
    final bool correct;
    if (answer == null) {
      correct = false;
    } else if (question.isCompose) {
      correct = source.isCorrectComposeOrder(answer.order ?? const []);
    } else if (question.isTyped) {
      correct = source.isCorrectTypedAnswer(exercise.type, answer.text ?? '');
    } else {
      correct = answer.index == source.correctIndex;
    }
    return AnswerCheck(
      correct: correct,
      answered: answer != null,
      correctIndex: source.correctIndex,
      correctOrder: source.segments,
      accepted: source.acceptedAnswers,
      keyword: source.keyword,
    );
  }

  @override
  Future<PlayResult> finish({required int durationSeconds}) async {
    final review = <String, AnswerCheck>{
      for (final (i, q) in questions.indexed) q.id: _check(i, _answers[q.id]),
    };
    final correct = review.values.where((c) => c.correct).length;
    final total = questions.length;
    final score = total == 0 ? 0 : ((correct / total) * 100).round();
    await _firestore.saveExerciseResult(
      studentId: _studentId,
      exerciseId: exercise.id,
      score: score,
      correct: correct,
      total: total,
      durationSeconds: durationSeconds,
      exerciseTitle: exercise.title,
    );
    return PlayResult(
      score: score,
      correct: correct,
      total: total,
      durationSeconds: durationSeconds,
      review: review,
    );
  }
}
