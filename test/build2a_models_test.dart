import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/services/exercise_play_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 2A: typed pinyin (T1) and free writing (T5) in the models the
// editor and the players use.
void main() {
  test('essay questions keep their words, source text and minutes', () {
    const q = ExerciseQuestion(
      prompt: '写一写你的周末。',
      keywords: ['周末', '公园'],
      sourceText: '原文',
      sourceSeconds: 600,
    );
    final map = q.toMap(ExerciseType.essay);
    expect(map['keywords'], ['周末', '公园']);
    expect(map['sourceSeconds'], 600);
    final back = ExerciseQuestion.fromMap(map, exerciseType: ExerciseType.essay);
    expect(back.keywords, ['周末', '公园']);
    expect(back.sourceText, '原文');
    expect(back.sourceSeconds, 600);
  });

  test('typed pinyin keeps its accepted keys', () {
    const q = ExerciseQuestion(prompt: '你好', options: ['nǐ hǎo']);
    final back = ExerciseQuestion.fromMap(q.toMap(ExerciseType.typePinyin),
        exerciseType: ExerciseType.typePinyin);
    expect(back.acceptedAnswers, ['nǐ hǎo']);
  });

  test('the new types are typed answers; only free writing is teacher-marked', () {
    expect(ExerciseType.typePinyin.isTyped, isTrue);
    expect(ExerciseType.essay.isTyped, isTrue);
    expect(ExerciseType.essay.isTeacherMarked, isTrue);
    expect(ExerciseType.pictureSentence.isTeacherMarked, isTrue);
    expect(ExerciseType.typePinyin.isTeacherMarked, isFalse);
    expect(ExerciseType.fromValue('type_pinyin'), ExerciseType.typePinyin);
  });

  test('the review reads half credit and the teacher\'s mark', () {
    final half = AnswerCheck.fromServer({
      'correct': false,
      'credit': 0.5,
      'needsMarking': true,
      'maxPoints': 1,
      'correctAnswer': {'accepted': ['我很喜欢喝茶']},
    });
    expect(half.isHalf, isTrue);
    expect(half.needsMarking, isTrue);
    final marked = AnswerCheck.fromServer({
      'correct': false,
      'credit': 0,
      'needsMarking': true,
      'maxPoints': 10,
      'marking': {'status': 'marked', 'points': 8},
      'correctAnswer': {'keywords': ['周末']},
    });
    expect(marked.needsMarking, isFalse, reason: 'marked: no longer waiting');
    expect(marked.markedPoints, 8);
    expect(marked.keywords, ['周末']);
  });

  test('an essay from the server carries its words, never a key', () {
    final q = PlayQuestion.fromServer({
      'id': 'e1',
      'type': 'essay',
      'prompt': '写',
      'keywords': ['周末'],
      'sourceText': '原文',
      'sourceSeconds': 60,
    });
    expect(q.isTyped, isTrue);
    expect(q.keywords, ['周末']);
    expect(q.sourceSeconds, 60);
  });
}
