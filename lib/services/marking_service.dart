import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../core/paging/date_range.dart';
import '../core/paging/paged_controller.dart';
import '../models/app_user.dart';
import '../models/marking_item.dart';

/// The marking queue (Build 2A): answers the scoring functions could not
/// settle alone. Reads follow the rules (a teacher: their own queue; an
/// admin: all); marks go through the `markAnswer` function, which re-scores
/// the result and tells the student when it is final.
class MarkingService {
  MarkingService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Build 9A session 2: the open queue of [user] (a teacher: their own;
  /// an admin: all), newest first, within [range].
  Query<Map<String, dynamic>> openQuery(AppUser user,
      [DateRangeSel range = const DateRangeSel.all()]) {
    Query<Map<String, dynamic>> q = _db.collection('marking_items');
    if (!user.isAdmin) q = q.where('teacherIds', arrayContains: user.uid);
    return applyDateRange(
        q
            .where('status', isEqualTo: 'open')
            .orderBy('createdAt', descending: true),
        'createdAt',
        range);
  }

  PageSource<MarkingItem> openSource(AppUser user, DateRangeSel range) =>
      FirestorePageSource(openQuery(user, range), MarkingItem.fromDoc);

  /// How many answers wait for [user] (a count, no documents read).
  Future<int> openCount(AppUser user) async =>
      (await openQuery(user).count().get()).count ?? 0;

  /// Open answers waiting for [user], newest first.
  Stream<List<MarkingItem>> watchOpen(AppUser user) {
    Query<Map<String, dynamic>> q = _db.collection('marking_items');
    if (!user.isAdmin) q = q.where('teacherIds', arrayContains: user.uid);
    return q
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(MarkingItem.fromDoc).toList());
  }

  /// Typed answer: `keep` (the machine's half), `full` or `zero`.
  Future<double> markTyped(String itemId, String decision) =>
      _mark({'itemId': itemId, 'decision': decision});

  /// Free writing with the rubric (grammar 0-40, vocabulary 0-30,
  /// content 0-30). Returns the points given.
  Future<double> markRubric(
    String itemId, {
    required int grammar,
    required int vocabulary,
    required int content,
  }) =>
      _mark({
        'itemId': itemId,
        'rubric': {
          'grammar': grammar,
          'vocabulary': vocabulary,
          'content': content,
        },
      });

  Future<double> _mark(Map<String, Object?> data) async {
    final r = await _functions.httpsCallable('markAnswer').call(data);
    return ((r.data as Map)['points'] as num?)?.toDouble() ?? 0;
  }
}
