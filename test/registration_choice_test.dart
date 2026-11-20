import 'package:chinese_tracker/models/app_user.dart';
import 'package:chinese_tracker/models/placement.dart';
import 'package:chinese_tracker/services/rooms_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Build 3: the register form's start-level choice (PL-01, PL-02) and the
// rooms list.
PlacementSummary _summary(String code, {bool claimed = false}) => PlacementSummary(
      resultCode: code,
      level: 'HSK 3',
      total: 225,
      max: 300,
      passed: true,
      recommendedLevel: 'HSK 4',
      claimed: claimed,
    );

void main() {
  test('PL-02 "Mulai dari HSK 1" can be sent as it is', () {
    const c = RegistrationChoice();
    expect(c.issue, isNull);
    expect(c.toFields(), {
      'placementChoice': AppUser.choiceHsk1,
      'placementTarget': '',
      'placementResultCode': '',
    });
  });

  test('PL-01 the placement test needs a target level HSK 2-6', () {
    const c = RegistrationChoice(choice: AppUser.choiceTest);
    expect(c.issue, RegistrationChoiceIssue.targetMissing);
    expect(c.copyWith(target: 'HSK 1').issue, RegistrationChoiceIssue.targetMissing);
    final ok = c.copyWith(target: 'HSK 4');
    expect(ok.issue, isNull);
    expect(ok.toFields()['placementTarget'], 'HSK 4');
    // Back to HSK 1: the target is not stored.
    expect(ok.copyWith(choice: AppUser.choiceHsk1).toFields()['placementTarget'], '');
  });

  test('a result code must be valid, checked and not used by someone else', () {
    const base = RegistrationChoice(choice: AppUser.choiceTest, target: 'HSK 4');
    expect(base.copyWith(resultCode: 'ABC').issue,
        RegistrationChoiceIssue.resultCodeInvalid);
    expect(base.copyWith(resultCode: 'ABCDE0').issue,
        RegistrationChoiceIssue.resultCodeInvalid, reason: 'no 0/O/1/I');
    expect(base.copyWith(resultCode: 'rk4-plc').issue,
        RegistrationChoiceIssue.resultCodeUnchecked);
    final checked = base.copyWith(resultCode: 'rk4-plc', checked: _summary('RK4PLC'));
    expect(checked.issue, isNull);
    expect(checked.toFields()['placementResultCode'], 'RK4PLC');
    // Changed after the check: check again.
    expect(checked.copyWith(resultCode: 'RK4PLD').issue,
        RegistrationChoiceIssue.resultCodeUnchecked);
    expect(base.copyWith(resultCode: 'RK4PLC', checked: _summary('RK4PLC', claimed: true)).issue,
        RegistrationChoiceIssue.resultCodeClaimed);
  });

  test('normalizeCode: upper case, spaces and dashes dropped', () {
    expect(RegistrationChoice.normalizeCode(' ab c-12 3'), '');
    expect(RegistrationChoice.normalizeCode('abc-234'), 'ABC234');
    expect(RegistrationChoice.normalizeCode('ABCDEFG'), '');
  });

  test('a claimed code is fine for the student who claimed it', () {
    const p = PlacementSummary(
      resultCode: 'RK4PLC', level: 'HSK 3', total: 1, max: 2, passed: true,
      recommendedLevel: 'HSK 4', claimed: true, claimedBy: 'me');
    expect(p.claimedByOther('me'), isFalse);
    expect(p.claimedByOther('other'), isTrue);
  });

  test('rooms: cleaned list; a stored room not in it stays selectable', () {
    expect(RoomsService.cleanRooms([' Main ', 'main', '', 'Sub Room']),
        ['Main', 'Sub Room']);
    expect(RoomsService.choices(['Main', 'Sub Room'], 'Ruang 3'),
        ['Main', 'Sub Room', 'Ruang 3']);
    expect(RoomsService.choices(['Main'], 'Main'), ['Main']);
    expect(RoomsService.choices(['Main'], ''), ['Main']);
  });

  test('a pending or rejected student waits; an old student (no status) does not', () {
    const old = AppUser(uid: 'a', email: '', name: 'A', role: 'student');
    expect(old.awaitsApproval, isFalse);
    const pending = AppUser(
        uid: 'b', email: '', name: 'B', role: 'student', status: 'pending');
    expect(pending.awaitsApproval, isTrue);
    const rejected = AppUser(
        uid: 'c', email: '', name: 'C', role: 'student', status: 'rejected');
    expect(rejected.awaitsApproval, isTrue);
    const teacher = AppUser(
        uid: 'd', email: '', name: 'D', role: 'teacher', status: 'pending');
    expect(teacher.awaitsApproval, isFalse);
  });
}
