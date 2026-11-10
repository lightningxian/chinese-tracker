import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/app_user.dart';
import '../../models/exercise.dart';
import '../../models/exercise_assignment.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Pick the students who may do [exercise]. Students already assigned come
/// pre-ticked; unticking one removes the assignment. Only assigned students
/// see the exercise.
Future<void> showExerciseAssignDialog(
  BuildContext context, {
  required Exercise exercise,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ExerciseAssignDialog(exercise: exercise),
  );
}

class _ExerciseAssignDialog extends StatefulWidget {
  const _ExerciseAssignDialog({required this.exercise});
  final Exercise exercise;

  @override
  State<_ExerciseAssignDialog> createState() => _ExerciseAssignDialogState();
}

class _ExerciseAssignDialogState extends State<_ExerciseAssignDialog> {
  final Set<String> _selected = {};
  Set<String> _alreadyAssigned = {};
  bool _seeded = false;
  String? _levelFilter;
  String _search = '';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _levelFilter = widget.exercise.level;
  }

  List<AppUser> _visible(List<AppUser> students) {
    final needle = _search.trim().toLowerCase();
    return students.where((s) {
      if (!s.isStudent || !s.active) return false;
      if (_levelFilter != null && s.level != _levelFilter) return false;
      if (needle.isEmpty) return true;
      return '${s.displayNameIndonesian} ${s.name} ${s.email}'
          .toLowerCase()
          .contains(needle);
    }).toList()
      ..sort(
          (a, b) => a.displayNameIndonesian.compareTo(b.displayNameIndonesian));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final firestore = context.read<FirestoreService>();
    final teacherId =
        AppConstants.contentTeacherId(context.read<AuthService>().appUser!);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = _selected.difference(_alreadyAssigned);
      final removed = _alreadyAssigned.difference(_selected);
      if (added.isNotEmpty) {
        await firestore.assignExerciseToStudents(
          exerciseId: widget.exercise.id,
          studentIds: added,
          teacherId: teacherId,
          dueDate: _dueDate,
        );
      }
      for (final id in removed) {
        await firestore.unassignExerciseFromStudent(
          exerciseId: widget.exercise.id,
          studentId: id,
        );
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Assigned to ${_selected.length} student${_selected.length == 1 ? '' : 's'}'
            '${removed.isNotEmpty ? ', removed from ${removed.length}' : ''}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not assign: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: StreamBuilder<List<ExerciseAssignment>>(
          stream: firestore.watchAssignmentsForExercise(widget.exercise.id),
          builder: (context, assignSnap) {
            if (assignSnap.hasData && !_seeded) {
              _alreadyAssigned =
                  assignSnap.data!.map((a) => a.studentId).toSet();
              _selected.addAll(_alreadyAssigned);
              _seeded = true;
            }
            return StreamBuilder<List<AppUser>>(
              stream: firestore.watchAllStudents(),
              builder: (context, snap) {
                final students = _visible(snap.data ?? const []);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign "${widget.exercise.title}"',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only the students you tick can open this exercise.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search, size: 20),
                                    hintText: 'Search students',
                                    isDense: true,
                                  ),
                                  onChanged: (v) => setState(() => _search = v),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 130,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _levelFilter,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Level',
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All'),
                                    ),
                                    for (final l in AppConstants.hskLevels)
                                      DropdownMenuItem(
                                          value: l, child: Text(l)),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _levelFilter = v),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: students.isEmpty
                                    ? null
                                    : () => setState(() => _selected
                                        .addAll(students.map((s) => s.uid))),
                                child: Text(
                                    'Select all shown (${students.length})'),
                              ),
                              TextButton(
                                onPressed: _selected.isEmpty
                                    ? null
                                    : () => setState(_selected.clear),
                                child: const Text('Clear'),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _dueDate ??
                                        DateTime.now()
                                            .add(const Duration(days: 7)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() => _dueDate = picked);
                                  }
                                },
                                icon:
                                    const Icon(Icons.event_outlined, size: 18),
                                label: Text(
                                  _dueDate == null
                                      ? 'No due date'
                                      : 'Due ${DateFormat('d MMM').format(_dueDate!)}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: students.isEmpty
                          ? const EmptyState(
                              icon: Icons.people_outline,
                              title: 'No students match',
                              subtitle: 'Change the level or the search.',
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: students.length,
                              itemBuilder: (context, i) {
                                final s = students[i];
                                final ticked = _selected.contains(s.uid);
                                return CheckboxListTile(
                                  value: ticked,
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(s.displayNameIndonesian),
                                  subtitle: Text(
                                    [
                                      if (s.level != null) s.level!,
                                      if (_alreadyAssigned.contains(s.uid))
                                        'assigned',
                                    ].join(' · '),
                                  ),
                                  onChanged: (v) => setState(() {
                                    v == true
                                        ? _selected.add(s.uid)
                                        : _selected.remove(s.uid);
                                  }),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                            ),
                            icon: const Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 18),
                            label: Text(
                              _saving
                                  ? 'Saving…'
                                  : 'Save (${_selected.length} student${_selected.length == 1 ? '' : 's'})',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
