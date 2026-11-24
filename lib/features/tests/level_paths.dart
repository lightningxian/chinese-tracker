import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/discard_guard.dart';
import '../../l10n/l10n.dart';
import '../../models/exercise.dart';
import '../../models/leaderboard.dart';
import '../../models/test_track.dart';
import '../../services/firestore_service.dart';
import '../../services/test_service.dart';

/// One thing on a level's checklist.
class LevelPathItem {
  const LevelPathItem({
    required this.kind,
    required this.id,
    required this.title,
    this.minScore = 0,
  });

  /// `exercise` (a package) or `test` (a test code).
  final String kind;
  final String id;
  final String title;

  /// Exercises: the score needed (0 = finished).
  final int minScore;

  bool get isExercise => kind == 'exercise';

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'id': id,
        'title': title,
        if (isExercise) 'minScore': minScore,
      };

  factory LevelPathItem.fromMap(Map<String, dynamic> m) => LevelPathItem(
        kind: m['kind'] as String? ?? 'exercise',
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        minScore: (m['minScore'] as num?)?.toInt() ?? 0,
      );
}

/// Owner 2026-11-24: "to go from HSK 1 to HSK 2, finish these": one
/// checklist per level (`level_paths/{levelKey}`, admin writes). A level
/// with a checklist uses it instead of the test-code count; the functions
/// keep each student's progress in `promotion_progress`.
class LevelPathService {
  LevelPathService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('level_paths');

  Stream<Map<String, List<LevelPathItem>>> watchAll() => _col.snapshots().map((s) => {
        for (final d in s.docs)
          d.id: [
            for (final i in (d.data()['items'] as List? ?? const []))
              LevelPathItem.fromMap(Map<String, dynamic>.from(i as Map)),
          ],
      });

  Future<void> save(String levelKey, List<LevelPathItem> items) => _col.doc(levelKey).set({
        'level': 'HSK $levelKey',
        'items': [for (final i in items) i.toMap()],
        'updatedAt': FieldValue.serverTimestamp(),
      });
}

/// The six levels and their checklists, each with **Edit** (Promotion
/// screen).
class LevelPathsCard extends StatefulWidget {
  const LevelPathsCard({super.key});

  @override
  State<LevelPathsCard> createState() => _LevelPathsCardState();
}

class _LevelPathsCardState extends State<LevelPathsCard> {
  late final Stream<Map<String, List<LevelPathItem>>> _paths = LevelPathService().watchAll();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
      child: StreamBuilder<Map<String, List<LevelPathItem>>>(
        stream: _paths,
        builder: (context, snap) {
          final paths = snap.data ?? const <String, List<LevelPathItem>>{};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.levelPathsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(l.levelPathsHelp,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 6),
              for (var k = 1; k <= 5; k++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('HSK $k → HSK ${k + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text((paths['$k'] ?? const []).isEmpty
                      ? l.levelPathNone
                      : l.levelPathCount((paths['$k'] ?? const []).length)),
                  trailing: TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _LevelPathEditor(
                        levelKey: '$k',
                        initial: paths['$k'] ?? const [],
                      ),
                    ),
                    child: Text(l.levelPathEdit),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelPathEditor extends StatefulWidget {
  const _LevelPathEditor({required this.levelKey, required this.initial});
  final String levelKey;
  final List<LevelPathItem> initial;

  @override
  State<_LevelPathEditor> createState() => _LevelPathEditorState();
}

class _LevelPathEditorState extends State<_LevelPathEditor> {
  late final List<LevelPathItem> _items = [...widget.initial];
  late final Stream<List<Exercise>> _exercises =
      context.read<FirestoreService>().watchAllExercises();
  late final Stream<List<TestCode>> _codes = TestService().watchCodes();
  bool _saving = false;
  String? _error;

  String _sig(List<LevelPathItem> list) =>
      list.map((i) => '${i.kind}:${i.id}:${i.minScore}').join('|');

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await LevelPathService().save(widget.levelKey, _items);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addExercise(List<Exercise> all) async {
    final l = context.l10n;
    final level = 'HSK ${widget.levelKey}';
    final options = all
        .where((e) => e.isPackage && !_items.any((i) => i.isExercise && i.id == e.id))
        .toList()
      ..sort((a, b) {
        // The level's own exercises first.
        final la = a.level == level ? 0 : 1, lb = b.level == level ? 0 : 1;
        return la != lb ? la.compareTo(lb) : a.title.compareTo(b.title);
      });
    final picked = await showDialog<Exercise>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.levelPathAddExercise),
        children: [
          SizedBox(
            width: 480,
            height: 420,
            child: ListView(
              children: [
                for (final e in options)
                  ListTile(
                    title: Text(e.title),
                    subtitle: Text(e.level ?? ''),
                    onTap: () => Navigator.pop(ctx, e),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(LevelPathItem(kind: 'exercise', id: picked.id, title: picked.title)));
  }

  Future<void> _addTest(List<TestCode> all) async {
    final l = context.l10n;
    final options = all
        .where((c) => !c.placement && !_items.any((i) => !i.isExercise && i.id == c.id))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final picked = await showDialog<TestCode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.levelPathAddTest),
        children: [
          SizedBox(
            width: 420,
            height: 380,
            child: ListView(
              children: [
                for (final c in options)
                  ListTile(
                    title: Text(c.code),
                    subtitle: Text(c.level),
                    onTap: () => Navigator.pop(ctx, c),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => _items.add(LevelPathItem(kind: 'test', id: picked.id, title: picked.code)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final k = widget.levelKey;
    return DiscardGuard(
      isDirty: () => !_saving && _sig(_items) != _sig(widget.initial),
      child: AlertDialog(
        title: Text(l.levelPathEditorTitle('HSK $k', 'HSK ${int.parse(k) + 1}')),
        content: SizedBox(
          width: 620,
          child: StreamBuilder<List<Exercise>>(
            stream: _exercises,
            builder: (context, exSnap) => StreamBuilder<List<TestCode>>(
              stream: _codes,
              builder: (context, codeSnap) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.levelPathEditorHelp,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 10),
                  if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.levelPathEmpty,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _items[i].isExercise ? Icons.menu_book_outlined : Icons.timer_outlined,
                              color: AppColors.teal,
                            ),
                            title: Text(_items[i].title),
                            subtitle: _items[i].isExercise
                                ? Row(
                                    children: [
                                      Text(l.levelPathMinScore),
                                      const SizedBox(width: 8),
                                      DropdownButton<int>(
                                        value: _items[i].minScore,
                                        isDense: true,
                                        items: [
                                          for (final v in const [0, 50, 60, 70, 80, 90, 100])
                                            DropdownMenuItem(
                                              value: v,
                                              child: Text(v == 0 ? l.levelPathJustFinish : '$v%'),
                                            ),
                                        ],
                                        onChanged: (v) => setState(() => _items[i] = LevelPathItem(
                                              kind: 'exercise',
                                              id: _items[i].id,
                                              title: _items[i].title,
                                              minScore: v ?? 0,
                                            )),
                                      ),
                                    ],
                                  )
                                : Text(l.levelPathPassTest),
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  tooltip: l.levelPathUp,
                                  onPressed: i == 0
                                      ? null
                                      : () => setState(() =>
                                          _items.insert(i - 1, _items.removeAt(i))),
                                  icon: const Icon(Icons.arrow_upward, size: 18),
                                ),
                                IconButton(
                                  tooltip: l.timetableDelete,
                                  onPressed: () => setState(() => _items.removeAt(i)),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addExercise(exSnap.data ?? const []),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.levelPathAddExercise),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addTest(codeSnap.data ?? const []),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.levelPathAddTest),
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.maybePop(context), child: Text(l.commonCancel)),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.roomsSave)),
        ],
      ),
    );
  }
}

/// The student's checklist toward the next level (Tests tab, the student
/// page): a progress bar and one line per item with a tick.
class LevelPathProgress extends StatelessWidget {
  const LevelPathProgress({super.key, required this.progress});
  final PromotionProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.levelPathProgressTitle(p.level, p.next, p.done, p.total),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: p.total == 0 ? 0 : p.done / p.total,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        for (final i in p.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(i.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20, color: i.done ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: 8),
                Icon(i.kind == 'test' ? Icons.timer_outlined : Icons.menu_book_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(i.title)),
                Text(
                  i.kind == 'test'
                      ? (i.done ? l.levelPathPassed : l.levelPathPassTest)
                      : i.minScore > 0
                          ? l.levelPathScoreNeeded(i.best ?? 0, i.minScore)
                          : (i.done ? l.levelPathFinished : l.levelPathToDo),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
