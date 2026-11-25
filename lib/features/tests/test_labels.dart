import 'package:cloud_functions/cloud_functions.dart';

import '../../l10n/l10n.dart';
import '../../models/test_track.dart';

/// UI words for the test track in the app language.
extension TestSkillL10n on TestSkill {
  String localized(AppLocalizations l) => switch (this) {
        TestSkill.listening => l.testsSkillListening,
        TestSkill.reading => l.testsSkillReading,
        TestSkill.writing => l.testsSkillWriting,
        TestSkill.speaking => l.testsSkillSpeaking,
      };
}

/// `mm:ss`, or `h:mm:ss` from an hour.
String clockText(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$sec';
  return '${m.toString().padLeft(2, '0')}:$sec';
}

/// A function error as the student or teacher should read it.
String testErrorMessage(AppLocalizations l, Object error) {
  if (error is FirebaseFunctionsException) {
    final details = error.details;
    final reason = details is Map ? details['reason'] : null;
    return switch (reason) {
      'bad-token' => l.testsErrorBadToken,
      'token-blocked' => l.testsErrorTokenBlocked,
      'join-closed' => l.testsErrorJoinClosed,
      'already-attempted' => l.testsErrorAlreadyAttempted,
      'part-closed' => l.testsErrorPartClosed,
      'session-open' => l.testsErrorReviewSessionOpen,
      'not-finished' => l.testsErrorReviewNotFinished,
      'reason-required' => l.testsErrorReasonRequired,
      'not-waiting' => l.promotionErrNotWaiting,
      'level-changed' => l.promotionErrLevelChanged,
      // Build 3.
      'not-approved' => l.placementErrNotApproved,
      'bad-key' => l.placementErrBadKey,
      'visitor-details' => l.placementErrVisitorDetails,
      'not-placement' => l.placementErrNotPlacement,
      'bad-result-code' => l.placementErrBadResultCode,
      'claimed' => l.placementErrClaimed,
      'not-pending' => l.approvalErrNotPending,
      'teacher' => l.approvalErrTeacher,
      'level' => l.approvalErrLevel,
      _ => error.message ?? l.testsErrorGeneric,
    };
  }
  return '$error';
}

/// Build 9D: "Sitting 2 · practice" (a repeat) or "Sitting 2" (it counts,
/// because the first sitting was invalid); empty for the first sitting.
String sittingLabel(AppLocalizations l, int sittingNo, {bool repeat = false}) {
  if (sittingNo <= 1 && !repeat) return '';
  return repeat ? l.testsSittingRepeat(sittingNo) : l.testsSitting(sittingNo);
}
