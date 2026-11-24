import 'package:chinese_tracker/core/utils/notification_routes.dart';
import 'package:chinese_tracker/features/announcements/announcements.dart';
import 'package:chinese_tracker/features/student/widgets/question_answer_view.dart';
import 'package:chinese_tracker/models/hsk_paper_draft.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_draft_service.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_image_ops.dart';
import 'package:chinese_tracker/models/app_notification.dart';
import 'package:chinese_tracker/models/exercise_category.dart';
import 'package:chinese_tracker/models/exercise_skill_category.dart';
import 'package:chinese_tracker/models/invoice.dart';
import 'package:chinese_tracker/models/exercise.dart';
import 'package:chinese_tracker/models/exercise_type.dart';
import 'package:chinese_tracker/models/question_bank_item.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(String role) => AppNotification(
      id: 'ann_x_$role',
      kind: NotificationKind.fromValue('announcement'),
      title: 'Parent meeting',
      body: '',
      forRole: role,
      userId: '',
      targetRoute: '/$role',
    );

void main() {
  group('Owner 2026-11-24 (third round)', () {
    test('a News notice is an announcement, not a class session', () {
      expect(NotificationKind.fromValue('announcement'), NotificationKind.announcement);
    });

    test('a News notice opens the home tab of every role', () {
      for (final role in ['student', 'teacher', 'parent', 'admin']) {
        expect(NotificationRoutes.tabFor(_n(role), role: role), 0, reason: role);
      }
    });
  });

  group('Owner 2026-11-24 (fourth round)', () {
    test('Mixed is a skill of exercises, never of a single question', () {
      expect(ExerciseSkillCategory.fromValue('mixed'), ExerciseSkillCategory.mixed);
      expect(ExerciseSkillCategory.forQuestions, isNot(contains(ExerciseSkillCategory.mixed)));
      expect(ExerciseSkillCategory.forQuestions.length, ExerciseSkillCategory.values.length - 1);
    });

    test('an announcement without an end date stays and says so', () {
      const a = Announcement(
          id: 'a', title: 'T', body: '', audience: 'all', kind: 'info', date: '',
          toDate: Announcement.noEnd);
      expect(a.hasEnd, isFalse);
      expect(a.activeOn('2099-12-31'), isTrue);
      const o = Announcement(
          id: 'o', title: 'T', body: '', audience: 'all', kind: 'opened', date: '2026-12-25',
          toDate: '2026-12-25');
      expect(o.isOpened, isTrue);
      expect(o.isClosure, isFalse);
    });

    test('a discarded invoice is read back as discarded and is not payable', () {
      expect(InvoiceStatus.fromValue('discarded'), InvoiceStatus.discarded);
      expect(InvoiceStatus.discarded.isFinal, isTrue);
    });
  });

  group('Owner 2026-11-24 (fifth round)', () {
    test('a scanned question with its right answer survives a draft', () {
      final slot = HskSlot(
        number: 41,
        skill: 'reading',
        section: '二、阅读 · 第一部分 · 第41-45题',
        form: HskForm.matching,
        page: 8,
        prompt: '最近真是越来越冷了。（ ）',
        options: ['我也不知道', '是啊', '街道两边'],
        pictures: [const PixelBox(1, 2, 30, 40)],
        correctIndex: 1,
      )..checked = true;
      final back = PaperDraftService.slotFromMap(PaperDraftService.slotToMap(slot));
      expect(back.number, 41);
      expect(back.form, HskForm.matching);
      expect(back.options, slot.options);
      expect(back.correctIndex, 1);
      expect(back.checked, isTrue);
      expect(back.pictures.single.x1, 30);
      expect(back.hasChoiceAnswer, isTrue);
    });

    test('a scanned answer reaches the saved question', () {
      final draft = HskPaperDraft(slots: [
        HskSlot(number: 1, skill: 'reading', form: HskForm.choice, page: 1,
            prompt: 'Q', options: ['a', 'b', 'c'], correctIndex: 2),
      ]);
      final w = draft.toAiWorksheet({1: (1000, 1400)});
      expect(w.sections.single.questions.single.correctIndex, 2);
    });

    test('shuffled choices: every choice once, the same order each time', () {
      final a = QuestionAnswerViewOrders.order('q-1', 4);
      expect([...a]..sort(), [0, 1, 2, 3]);
      expect(QuestionAnswerViewOrders.order('q-1', 4), a);
    });
  });

  group('Owner 2026-11-24 (sixth round)', () {
    test('word order and character answers are kept and saved', () {
      final order = HskSlot(number: 71, skill: 'writing', form: HskForm.reorder, page: 15,
          segments: ['弟弟', '被', '雨伞', '拿走', '了']);
      expect(order.answered, isFalse);
      order
        ..segments = ['雨伞', '被', '弟弟', '拿走', '了']
        ..orderSet = true;
      final char = HskSlot(number: 76, skill: 'writing', form: HskForm.pinyinChar, page: 16,
          prompt: '她的头发又黑又（ ）。', keyword: 'cháng', accepted: ['长']);
      expect(char.answered, isTrue);
      final back = PaperDraftService.slotFromMap(PaperDraftService.slotToMap(order));
      expect(back.orderSet, isTrue);
      expect(back.segments.join(), '雨伞被弟弟拿走了');
      final w = HskPaperDraft(slots: [order, char]).toAiWorksheet({15: (1000, 1400), 16: (1000, 1400)});
      final qs = w.sections.expand((x) => x.questions).toList();
      expect(qs[0].segments.join(), '雨伞被弟弟拿走了');
      expect(qs[1].accepted, ['长']);
    });

    test('HSK Standard Course is a worksheet type of its own', () {
      expect(ExerciseCategory.fromValue('hsk_standard_course'), ExerciseCategory.standardCourse);
    });
  });

  group('Owner 2026-11-24 (seventh round)', () {
    QuestionBankSheet sheet(ExerciseCategory c, {String? audio}) => QuestionBankSheet(key: 'K', items: [
          QuestionBankItem(
            id: 'q1',
            ownerId: 'a',
            type: ExerciseType.listening,
            question: const ExerciseQuestion(prompt: '', options: ['A', 'B']),
            category: c,
            sheetCode: 'K',
            sheetIndex: 0,
            sectionAudioUrl: audio,
          ),
        ]);

    test('Exam is no longer offered, but an Exam sheet keeps it', () {
      expect(ExerciseCategory.choices(), isNot(contains(ExerciseCategory.exam)));
      expect(ExerciseCategory.choices(ExerciseCategory.exam), contains(ExerciseCategory.exam));
      expect(ExerciseCategory.standardCourse.label, 'Standard Course');
    });

    test('HSK and Standard Course sheets show the paper kind as question type', () {
      expect(sheet(ExerciseCategory.hskSimulation).typeLabel, 'HSK');
      expect(sheet(ExerciseCategory.standardCourse).typeLabel, 'Standard Course');
      expect(sheet(ExerciseCategory.exercise).typeLabel, ExerciseType.listening.label);
    });

    test('HSK and Standard Course sheets need their recording', () {
      expect(sheet(ExerciseCategory.hskSimulation).missingRecording, isTrue);
      expect(sheet(ExerciseCategory.standardCourse).missingRecording, isTrue);
      expect(sheet(ExerciseCategory.hskSimulation, audio: 'https://a/x.mp3').missingRecording, isFalse);
      expect(sheet(ExerciseCategory.exercise).missingRecording, isFalse);
    });
  });
}
