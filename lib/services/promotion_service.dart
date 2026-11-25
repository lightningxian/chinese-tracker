import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/paging/paged_controller.dart';
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

  CollectionReference<Map<String, dynamic>> _entries(String codeId) =>
      _db.collection('leaderboards').doc(codeId).collection('entries');

  /// Build 9C: the board's code and paper level (`leaderboards/{codeId}`).
  Future<({String code, String level})> boardInfo(String codeId) async {
    final d = await _db.collection('leaderboards').doc(codeId).get();
    final m = d.data() ?? const {};
    return (code: '${m['code'] ?? codeId}', level: '${m['level'] ?? ''}');
  }

  /// Build 9C: the board one page at a time, ordered by `rankKey`. Rows
  /// written before Build 9C have no key; while any is left (until an admin
  /// presses Rebuild leaderboards) the board is ranked from one read of
  /// all rows instead, so nobody drops off it.
  Future<PageSource<LeaderboardEntry>> leaderboardSource(String codeId) async {
    final col = _entries(codeId);
    final keyed = col.orderBy('rankKey');
    final all = (await col.count().get()).count ?? 0;
    final withKey = (await keyed.count().get()).count ?? 0;
    if (all != withKey) {
      final snap = await col.get();
      return ListPageSource(
          LeaderboardEntry.ranked(snap.docs.map(LeaderboardEntry.fromDoc)));
    }
    return _RankedBoardSource(keyed);
  }

  /// The student's own row and its rank, or null when they are not on it.
  Future<({LeaderboardEntry entry, int total})?> myPlace(
      String codeId, String uid) async {
    final col = _entries(codeId);
    final doc = await col.doc(uid).get();
    if (!doc.exists) return null;
    final me = LeaderboardEntry.fromDoc(doc);
    final total = (await col.count().get()).count ?? 0;
    if (me.rankKey == null) {
      final snap = await col.get();
      final ranked = LeaderboardEntry.ranked(snap.docs.map(LeaderboardEntry.fromDoc));
      final mine = ranked.where((e) => e.studentId == uid).firstOrNull;
      return mine == null ? null : (entry: mine, total: ranked.length);
    }
    final before = (await col
                .where('rankKey', isLessThan: me.rankPrefix)
                .count()
                .get())
            .count ??
        0;
    return (entry: me.withRank(before + 1), total: total);
  }

  /// Build 9C: writes every board row again (admin). Returns the count.
  Future<int> rebuildLeaderboards() async {
    final r = await _functions
        .httpsCallable('rebuildLeaderboards',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 9)))
        .call({});
    return ((r.data as Map)['rebuilt'] as num?)?.toInt() ?? 0;
  }

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

  /// Declined recommendations, newest first (admin; owner 2026-11-24 may
  /// promote anyway).
  Stream<List<LevelPromotion>> watchDeclined({int limit = 20}) => _db
      .collection('level_promotions')
      .where('status', isEqualTo: 'declined')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(LevelPromotion.fromDoc).toList());

  /// Owner 2026-11-24 (Q12): promote a capable student straight away to
  /// [toLevel] (above their level). [reason] is required and kept in the
  /// history and the audit log.
  Future<void> promote(String studentId, {required String toLevel, required String reason}) =>
      _functions.httpsCallable('promoteStudent').call<dynamic>({
        'studentId': studentId,
        'toLevel': toLevel,
        'reason': reason.trim(),
      });

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

/// Build 9C: a board page with its ranks. Equal total and seconds share a
/// rank, also across a page break: the first row's rank is counted.
class _RankedBoardSource implements PageSource<LeaderboardEntry> {
  _RankedBoardSource(this.query);

  final Query<Map<String, dynamic>> query;

  @override
  Future<PageChunk<LeaderboardEntry>> fetch(
      {Object? after, required int limit}) async {
    var q = query;
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);
    final snap = await q.limit(limit).get();
    final rows = snap.docs.map(LeaderboardEntry.fromDoc).toList();
    if (rows.isEmpty) return const PageChunk([], []);
    final first = rows.first;
    final ahead = await Future.wait([
      query.where('rankKey', isLessThan: first.rankKey).count().get(),
      query.where('rankKey', isLessThan: first.rankPrefix).count().get(),
    ]);
    final index0 = ahead[0].count ?? 0;
    var rank = (ahead[1].count ?? 0) + 1;
    final out = <LeaderboardEntry>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0 && rows[i].rankPrefix != rows[i - 1].rankPrefix) {
        rank = index0 + i + 1;
      }
      out.add(rows[i].withRank(rank));
    }
    return PageChunk(out, List<Object?>.of(snap.docs));
  }

  @override
  Future<int?> count() async {
    try {
      return (await query.count().get()).count;
    } catch (_) {
      return null;
    }
  }
}
