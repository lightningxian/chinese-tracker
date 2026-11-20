import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/progress_summary.dart';

/// Build 4: the progress summary (written by functions) and teachers'
/// follow-up notes.
class ProgressService {
  ProgressService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  static const summaries = 'progress_summary';
  static const notes = 'progress_notes';

  Stream<ProgressSummary?> watchSummary(String studentId) => _db
      .collection(summaries)
      .doc(studentId)
      .snapshots()
      .map((d) => d.exists ? ProgressSummary.fromDoc(d) : null);

  Future<ProgressSummary?> loadSummary(String studentId) async {
    final d = await _db.collection(summaries).doc(studentId).get();
    return d.exists ? ProgressSummary.fromDoc(d) : null;
  }

  /// Staff: the summaries of one teacher's students, or all (admin).
  Stream<List<ProgressSummary>> watchSummaries({String? teacherId}) {
    Query<Map<String, dynamic>> q = _db.collection(summaries);
    if (teacherId != null) q = q.where('teacherId', isEqualTo: teacherId);
    return q.snapshots().map((s) => s.docs
        .map(ProgressSummary.fromDoc)
        .where((x) => (x.studentName.isNotEmpty || x.level.isNotEmpty))
        .toList());
  }

  /// Notes on one student, newest first.
  Stream<List<ProgressNote>> watchNotes(String studentId) => _db
      .collection(notes)
      .where('studentId', isEqualTo: studentId)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(ProgressNote.fromDoc).toList());

  Future<void> addNote({
    required String studentId,
    required String teacherId,
    required String teacherName,
    required String text,
  }) =>
      _db.collection(notes).add({
        'studentId': studentId,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateNote(String id, String text) => _db
      .collection(notes)
      .doc(id)
      .update({'text': text.trim(), 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteNote(String id) => _db.collection(notes).doc(id).delete();

  /// Admin: rebuild every active student's summary (once after the deploy).
  Future<int> rebuildAll() async {
    final r = await _functions
        .httpsCallable('rebuildProgressSummaries',
            options: HttpsCallableOptions(timeout: const Duration(minutes: 9)))
        .call({});
    return ((r.data as Map)['rebuilt'] as num?)?.toInt() ?? 0;
  }
}
