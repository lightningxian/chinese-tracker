import 'package:chinese_tracker/core/utils/notification_routes.dart';
import 'package:chinese_tracker/features/announcements/announcements.dart';
import 'package:chinese_tracker/features/student/widgets/question_answer_view.dart';
import 'package:chinese_tracker/models/hsk_paper_draft.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_draft_service.dart';
import 'package:chinese_tracker/services/hsk_paper/paper_image_ops.dart';
import 'package:chinese_tracker/models/app_notification.dart';
import 'package:chinese_tracker/models/exercise_skill_category.dart';
import 'package:chinese_tracker/models/invoice.dart';
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
}
