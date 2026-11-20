import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_user.dart';
import '../models/leaderboard.dart';

/// Build 2B: leaderboards, the promotion count and the admin's decision.
/// Everything here is written by Cloud Functions (onTestResultWritten,
/// decidePromotion); the app only reads, except `settings/promotion`, which
/// the admin edits.
class PromotionService {
  PromotionService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// The ranked board of a code. A student may read it only after sitting
  /// the code (rules).
  Stream<List<LeaderboardEntry>> watchLeaderboard(String codeId) => _db
      .collection('leaderboards')
      .doc(codeId)
      .collection('entries')
      .snapshots()
      .map((s) => LeaderboardEntry.ranked(s.docs.map(LeaderboardEntry.fromDoc)));

  /// Staff labels (`中文名 (Latin)`) of the students on a board.
  Future<Map<String, String>> staffLabels(Iterable<String> uids) async {
    final out = <String, String>{};
    final list = uids.toSet().toList();
    for (var i = 0; i < list.length; i += 30) {
      final snap = await _db
          .collection('users')
          // Teachers may read student profiles only: the rules need the
          // role in the query.
          .where('role', isEqualTo: 'student')
          .where(FieldPath.documentId, whereIn: list.skip(i).take(30).toList())
          .get();
      for (final d in snap.docs) {
        out[d.id] = AppUser.fromFirestore(d).staffLabel;
      }
    }
    return out;
  }

  /// Waiting recommendations, newest first (admin).
  Stream<List<LevelPromotion>> watchWaiting() => _db
      .collection('level_promotions')
      .where('status', isEqualTo: 'waiting')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(LevelPromotion.fromDoc).toList());

  /// Build 3: the student's placement recommendation, if any.
  Stream<LevelPromotion?> watchPlacement(String uid) => _db
      .collection('level_promotions')
      .doc('${uid}_placement')
      .snapshots()
      .map((d) => d.exists ? LevelPromotion.fromDoc(d) : null);

  /// "2 of 3 codes passed" of one student (null before the first result).
  Stream<PromotionProgress?> watchProgress(String uid) => _db
      .collection('promotion_progress')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? PromotionProgress.fromMap(d.data()!) : null);

  Stream<int> watchMinCodes() => _db
      .collection('settings')
      .doc('promotion')
      .snapshots()
      .map((d) => (d.data()?['minCodes'] as num?)?.round() ?? 3);

  Future<void> setMinCodes(int value) => _db
      .collection('settings')
      .doc('promotion')
      .set({'minCodes': value, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  /// Approve: the level goes up one, the history is written, the student
  /// and a linked parent are told. Decline needs a [reason].
  Future<void> decide(String promotionId, {required bool approve, String reason = ''}) =>
      _functions.httpsCallable('decidePromotion').call<dynamic>({
        'promotionId': promotionId,
        'approve': approve,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
}
