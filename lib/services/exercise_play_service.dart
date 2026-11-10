import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/exercise.dart';
import '../models/exercise_type.dart';
import 'firestore_service.dart';

/// One question as the student plays it: no answer key on board.
///
/// Legacy exercises (questions stored in the exercise doc) still carry the
/// key inside [ExerciseQuestion]; the play screen never reads it directly,
/// it asks [ExercisePlaySession.check] like it does for packages.
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

/// Outcome of one check, with the key for the feedback banner.
class AnswerCheck {
  const AnswerCheck({
    required this.correct,
    this.correctIndex,
    this.correctOrder = const [],
    this.accepted = const [],
    this.keyword = '',
  });

  final bool correct;
  final int? correctIndex;
  final List<String> correctOrder;
  final List<String> accepted;
  final String keyword;

  factory AnswerCheck.fromServer(Map<String, dynamic> m) {
    final key =
        Map<String, dynamic>.from(m['correctAnswer'] as Map? ?? const {});
    return AnswerCheck(
      correct: m['correct'] == true,
      correctIndex: (key['index'] as num?)?.toInt(),
      correctOrder: List<String>.from(key['order'] as List? ?? const []),
      accepted: List<String>.from(key['accepted'] as List? ?? const []),
      keyword: key['keyword'] as String? ?? '',
    );
  }
}

class PlayResult {
  const PlayResult(
      {required this.score, required this.correct, required this.total});
  final int score;
  final int correct;
  final int total;
}

/// A running attempt. Built by [ExercisePlayService.start]; the screen only
/// sees questions, checks and the final score.
abstract class ExercisePlaySession {
  Exercise get exercise;
  List<PlayQuestion> get questions;
  String get passage;

  Future<AnswerCheck> check(PlayQuestion question, PlayAnswer answer);

  /// Scores the attempt and records the result. Call once, at the end.
  Future<PlayResult> finish();
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

/// Package: questions and checks come from Cloud Functions.
class _ServerSession implements ExercisePlaySession {
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
  final Map<String, Map<String, dynamic>> _answers = {};

  @override
  Future<AnswerCheck> check(PlayQuestion question, PlayAnswer answer) async {
    _answers[question.id] = answer.toJson();
    final result = await _functions.httpsCallable('checkExerciseAnswer').call({
      'exerciseId': exercise.id,
      'questionId': question.id,
      'answer': answer.toJson(),
    });
    return AnswerCheck.fromServer(
        Map<String, dynamic>.from(result.data as Map));
  }

  @override
  Future<PlayResult> finish() async {
    final result = await _functions.httpsCallable('finishExercise').call({
      'exerciseId': exercise.id,
      'answers': _answers,
    });
    final m = Map<String, dynamic>.from(result.data as Map);
    return PlayResult(
      score: (m['score'] as num?)?.toInt() ?? 0,
      correct: (m['correct'] as num?)?.toInt() ?? 0,
      total: (m['total'] as num?)?.toInt() ?? questions.length,
    );
  }
}

/// Legacy exercise: questions and keys are in the exercise doc; the result is
/// written by the client as before.
class _LocalSession implements ExercisePlaySession {
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
  int _correct = 0;

  @override
  Future<AnswerCheck> check(PlayQuestion question, PlayAnswer answer) async {
    final i = questions.indexOf(question);
    final source = exercise.questions[i];
    final bool correct;
    if (question.isCompose) {
      correct = source.isCorrectComposeOrder(answer.order ?? const []);
    } else if (question.isTyped) {
      correct = source.isCorrectTypedAnswer(exercise.type, answer.text ?? '');
    } else {
      correct = answer.index == source.correctIndex;
    }
    if (correct) _correct++;
    return AnswerCheck(
      correct: correct,
      correctIndex: source.correctIndex,
      correctOrder: source.segments,
      accepted: source.acceptedAnswers,
      keyword: source.keyword,
    );
  }

  @override
  Future<PlayResult> finish() async {
    final total = questions.length;
    final score = total == 0 ? 0 : ((_correct / total) * 100).round();
    await _firestore.saveExerciseResult(
      studentId: _studentId,
      exerciseId: exercise.id,
      score: score,
    );
    return PlayResult(score: score, correct: _correct, total: total);
  }
}
