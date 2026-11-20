import 'package:cloud_firestore/cloud_firestore.dart';

/// Build 3 (Must 9): the centre's rooms (`settings/rooms {names}`), edited on
/// the Org settings screen; the class session form picks from them.
class RoomsService {
  RoomsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// The owner's rooms (decision 2026-11-16).
  static const defaults = ['Main', 'Sub Room'];

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('settings').doc('rooms');

  /// The rooms, or [defaults] while the doc is missing.
  Stream<List<String>> watchRooms() => _doc.snapshots().map((d) {
        final names = (d.data()?['names'] as List?)
            ?.map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return names ?? defaults;
      });

  Future<void> save(List<String> names) => _doc.set({
        'names': cleanRooms(names),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Writes the defaults when the doc is missing (admin, Org settings).
  Future<void> ensureDefaults() async {
    final d = await _doc.get();
    if (!d.exists) await save(defaults);
  }

  /// Trimmed, no blanks, no duplicates (case-insensitive), order kept.
  static List<String> cleanRooms(Iterable<String> names) {
    final seen = <String>{};
    final out = <String>[];
    for (final n in names) {
      final v = n.trim();
      if (v.isEmpty || !seen.add(v.toLowerCase())) continue;
      out.add(v);
    }
    return out;
  }

  /// The picker's choices: the list, plus a stored room that is no longer
  /// in it (it stays selectable on an old session).
  static List<String> choices(List<String> rooms, String? stored) {
    final s = stored?.trim() ?? '';
    if (s.isEmpty || rooms.contains(s)) return rooms;
    return [...rooms, s];
  }
}
