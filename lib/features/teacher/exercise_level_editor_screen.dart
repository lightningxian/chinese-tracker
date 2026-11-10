import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_level.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Create or edit a level: name, HSK level, the exercises in it and the
/// students who get them. Saving syncs the assignments.
class ExerciseLevelEditorScreen extends StatefulWidget {
  const ExerciseLevelEditorScreen({
    super.key,
    this.levelId,
    this.embedded = false,
  });

  final String? levelId;
  final bool embedded;

  @override
  State<ExerciseLevelEditorScreen> createState() =>
      _ExerciseLevelEditorScreenState();
}

class _ExerciseLevelEditorScreenState extends State<ExerciseLevelEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String? _hskLevel;
  final Set<String> _exerciseIds = {};
  final Set<String> _studentIds = {};
  String _exerciseQuery = '';
  String _studentQuery = '';
  ExerciseLevel? _loaded;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.levelId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isNew) {
      setState(() => _loading = false);
      return;
    }
    final level = await context
        .read<FirestoreService>()
        .getExerciseLevel(widget.levelId!);
    if (!mounted) return;
    setState(() {
      _loaded = level;
      if (level != null) {
        _name.text = level.name;
        _description.text = level.description ?? '';
        _hskLevel = level.hskLevel;
        _exerciseIds.addAll(level.exerciseIds);
        _studentIds.addAll(level.studentIds);
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exerciseIds.isEmpty) {
      setState(() => _error = 'Pick at least one exercise.');
      return;
    }
    final user = context.read<AuthService>().appUser;
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final level = ExerciseLevel(
        id: _loaded?.id ?? '',
        name: _name.text.trim(),
        hskLevel: _hskLevel,
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        exerciseIds: _exerciseIds.toList(),
        studentIds: _studentIds.toList(),
        createdBy: _loaded?.createdBy,
        createdAt: _loaded?.createdAt,
      );
      await context.read<FirestoreService>().saveExerciseLevel(
            level,
            teacherId: AppConstants.contentTeacherId(user),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${level.name}" saved. ${level.exerciseIds.length} exercise(s) '
            'assigned to ${level.studentIds.length} student(s).',
          ),
        ),
      );
      if (context.canPop()) context.pop();
    } catch (e) {
      setState(() => _error = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return ShellNestedPage(
      embedded: widget.embedded,
      title: _isNew ? 'New level' : 'Edit level',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Level name',
                            hintText: 'e.g. HSK 1 · Term 1',
                            prefixIcon: Icon(Icons.layers_outlined),
                          ),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ? 'Enter a name' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _hskLevel,
                          decoration: const InputDecoration(
                            labelText: 'HSK level (filters the lists below)',
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Any level'),
                            ),
                            for (final l in AppConstants.hskLevels)
                              DropdownMenuItem(value: l, child: Text(l)),
                          ],
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _hskLevel = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Exercise>>(
                    stream: firestore.watchAllExercises(),
                    builder: (context, snap) {
                      final all = (snap.data ?? const [])
                          .where((e) => e.isPublished)
                          .toList()
                        ..sort((a, b) => a.title.compareTo(b.title));
                      return _PickerCard<Exercise>(
                        title: 'Exercises',
                        subtitle: 'Published exercises only.',
                        items: all,
                        matchesLevel: (e) =>
                            _hskLevel == null || e.level == _hskLevel,
                        label: (e) => e.title,
                        detail: (e) => [
                          if (e.level != null) e.level!,
                          e.type.label,
                          '${e.questions.length} question${e.questions.length == 1 ? '' : 's'}',
                        ].join(' · '),
                        id: (e) => e.id,
                        selected: _exerciseIds,
                        query: _exerciseQuery,
                        onQuery: (q) => setState(() => _exerciseQuery = q),
                        onToggle: (id, on) => setState(() => on
                            ? _exerciseIds.add(id)
                            : _exerciseIds.remove(id)),
                        enabled: !_saving,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<AppUser>>(
                    stream: firestore.watchAllStudents(),
                    builder: (context, snap) {
                      final all = (snap.data ?? const [])
                          .where((u) => u.active)
                          .toList()
                        ..sort((a, b) => a.displayNameIndonesian
                            .compareTo(b.displayNameIndonesian));
                      return _PickerCard<AppUser>(
                        title: 'Students',
                        subtitle: 'Everyone ticked gets every exercise above.',
                        items: all,
                        matchesLevel: (u) =>
                            _hskLevel == null || u.level == _hskLevel,
                        label: (u) => u.displayNameIndonesian,
                        detail: (u) => [
                          if (u.level != null) u.level!,
                          u.email,
                        ].join(' · '),
                        id: (u) => u.uid,
                        selected: _studentIds,
                        query: _studentQuery,
                        onQuery: (q) => setState(() => _studentQuery = q),
                        onToggle: (id, on) => setState(() =>
                            on ? _studentIds.add(id) : _studentIds.remove(id)),
                        enabled: !_saving,
                      );
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isNew ? 'Create level' : 'Save level'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

/// Searchable checklist with "select all shown" for exercises or students.
class _PickerCard<T> extends StatelessWidget {
  const _PickerCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.matchesLevel,
    required this.label,
    required this.detail,
    required this.id,
    required this.selected,
    required this.query,
    required this.onQuery,
    required this.onToggle,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final List<T> items;
  final bool Function(T) matchesLevel;
  final String Function(T) label;
  final String Function(T) detail;
  final String Function(T) id;
  final Set<String> selected;
  final String query;
  final ValueChanged<String> onQuery;
  final void Function(String id, bool on) onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final shown = items.where((it) {
      if (!matchesLevel(it) && !selected.contains(id(it))) return false;
      if (q.isEmpty) return true;
      return label(it).toLowerCase().contains(q) ||
          detail(it).toLowerCase().contains(q);
    }).toList();
    final allShownSelected =
        shown.isNotEmpty && shown.every((it) => selected.contains(id(it)));

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title · ${selected.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: !enabled || shown.isEmpty
                    ? null
                    : () {
                        for (final it in shown) {
                          onToggle(id(it), !allShownSelected);
                        }
                      },
                child:
                    Text(allShownSelected ? 'Clear shown' : 'Select all shown'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            enabled: enabled,
            onChanged: onQuery,
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nothing matches.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final it = shown[i];
                      final itemId = id(it);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selected.contains(itemId),
                        title: Text(label(it),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(detail(it),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        onChanged: enabled
                            ? (v) => onToggle(itemId, v ?? false)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
