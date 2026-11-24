import 'package:chinese_tracker/core/utils/notification_routes.dart';
import 'package:chinese_tracker/features/announcements/announcements.dart';
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
}
