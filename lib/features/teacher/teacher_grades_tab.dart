import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/app_user.dart';
import '../../models/grade.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Teacher/admin gradebook: a "grades pending" queue plus recorded grades,
/// with create/score/edit actions.
class TeacherGradesTab extends StatefulWidget {
  const TeacherGradesTab({super.key});

  @override
  State<TeacherGradesTab> createState() => _TeacherGradesTabState();
}

class _TeacherGradesTabState extends State<TeacherGradesTab> {
  String? _sortColumnId;
  bool _sortAscending = true;

  void _onSort(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnId = columnId;
        _sortAscending = true;
      }
    });
  }

  List<Grade> _sorted(List<Grade> grades) {
    final columnId = _sortColumnId;
    if (columnId == null) return grades;

    final sorted = [...grades];
    sorted.sort((a, b) {
      final compare = switch (columnId) {
        'title' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        'category' => a.category.label.compareTo(b.category.label),
        'score' => (a.score ?? -1).compareTo(b.score ?? -1),
        'status' => a.status.label.compareTo(b.status.label),
        'date' => (a.gradedAt ?? a.createdAt ?? DateTime(0))
            .compareTo(b.gradedAt ?? b.createdAt ?? DateTime(0)),
        _ => 0,
      };
      return _sortAscending ? compare : -compare;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final user = context.watch<AuthService>().appUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final teacherId = AppConstants.contentTeacherId(user);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGradeSheet(context, teacherId: teacherId),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: const Text('New grade'),
      ),
      body: StreamBuilder<List<Grade>>(
        stream: firestore.watchTeacherGrades(teacherId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final grades = snap.data ?? const <Grade>[];
          final pending = grades.where((g) => g.isPending).toList();
          final graded = grades.where((g) => g.isGraded).toList();

          if (grades.isEmpty) {
            return const EmptyState(
              icon: Icons.grading_outlined,
              title: 'No grades yet',
              subtitle:
                  'Record an assessment score, or schedule a pending grade to '
                  'fill in later.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              if (pending.isNotEmpty) ...[
                SectionHeader(title: 'Grades pending (${pending.length})'),
                const SizedBox(height: 10),
                _gradeTable(context, firestore, pending),
                const SizedBox(height: 20),
              ],
              const SectionHeader(title: 'Recorded'),
              if (graded.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No recorded grades yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else ...[
                const SizedBox(height: 10),
                _gradeTable(context, firestore, graded),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _gradeTable(
    BuildContext context,
    FirestoreService firestore,
    List<Grade> grades,
  ) {
    return AppDataTable<Grade>(
      rows: _sorted(grades),
      columns: _buildColumns(context, firestore),
      sortColumnId: _sortColumnId,
      sortAscending: _sortAscending,
      onSort: _onSort,
      onRowTap: (grade) => _openScoreSheet(context, grade),
      mobileCardBuilder: (grade) => _GradeCard(
        grade: grade,
        onTap: () => _openScoreSheet(context, grade),
      ),
    );
  }

  List<AppTableColumn<Grade>> _buildColumns(
    BuildContext context,
    FirestoreService firestore,
  ) {
    final cellStyle = TextStyle(fontSize: 13, color: AppColors.textPrimary);
    final metaStyle = TextStyle(fontSize: 12, color: AppColors.textSecondary);
    final dateFormat = DateFormat('d MMM yyyy');

    return [
      AppTableColumn<Grade>(
        id: 'student',
        label: 'Student',
        flex: 2,
        cell: (grade) => _StudentLine(
          studentId: grade.studentId,
          firestore: firestore,
        ),
      ),
      AppTableColumn<Grade>(
        id: 'title',
        label: 'Assessment',
        sortable: true,
        flex: 2,
        cell: (grade) => Text(
          grade.title.isEmpty ? grade.category.label : grade.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      AppTableColumn<Grade>(
        id: 'category',
        label: 'Category',
        sortable: true,
        width: 110,
        cell: (grade) => Text(
          grade.category.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: metaStyle,
        ),
      ),
      AppTableColumn<Grade>(
        id: 'score',
        label: 'Score',
        sortable: true,
        width: 70,
        cell: (grade) => Text(
          grade.score != null ? '${grade.score!.round()}' : '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
      ),
      AppTableColumn<Grade>(
        id: 'letter',
        label: 'Letter',
        width: 64,
        cell: (grade) => Text(
          grade.displayLetter ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.teal,
          ),
        ),
      ),
      AppTableColumn<Grade>(
        id: 'status',
        label: 'Status',
        sortable: true,
        width: 96,
        cell: (grade) => StatusPill(
          label: grade.status.label,
          color: grade.isGraded ? AppColors.success : AppColors.brandYellow,
        ),
      ),
      AppTableColumn<Grade>(
        id: 'date',
        label: 'Date',
        sortable: true,
        width: 110,
        cell: (grade) {
          final date = grade.gradedAt ?? grade.createdAt;
          return Text(
            date == null ? '—' : dateFormat.format(date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cellStyle,
          );
        },
      ),
      AppTableColumn<Grade>(
        id: 'actions',
        label: 'Actions',
        width: 100,
        alignment: Alignment.centerRight,
        cell: (grade) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GradeIconAction(
              icon: grade.isPending
                  ? Icons.grading_outlined
                  : Icons.edit_outlined,
              tooltip: grade.isPending ? 'Add score' : 'Edit grade',
              onPressed: () => _openScoreSheet(context, grade),
            ),
            const SizedBox(width: 10),
            _GradeIconAction(
              icon: Icons.delete_outline,
              tooltip: 'Delete grade',
              color: AppColors.error,
              onPressed: () => _confirmDeleteGrade(context, grade),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _confirmDeleteGrade(BuildContext context, Grade grade) async {
    final firestore = context.read<FirestoreService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete grade?'),
        content: const Text('This removes the grade for this student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestore.deleteGrade(grade.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openGradeSheet(
    BuildContext context, {
    required String teacherId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GradeFormSheet(teacherId: teacherId),
    );
  }

  Future<void> _openScoreSheet(BuildContext context, Grade grade) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _GradeFormSheet(teacherId: grade.teacherId, existing: grade),
    );
  }
}

class _GradeIconAction extends StatelessWidget {
  _GradeIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    Color? color,
  }) : color = color ?? AppColors.navy;

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade, this.onTap});

  final Grade grade;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final pending = grade.isPending;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (pending ? AppColors.brandYellow : AppColors.success)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              pending ? Icons.schedule : Icons.check_circle_outline,
              color: pending ? AppColors.brandYellow : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.title.isEmpty ? grade.category.label : grade.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                _StudentLine(studentId: grade.studentId, firestore: firestore),
                Text(
                  grade.category.label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (grade.isGraded && grade.score != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${grade.score!.round()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  grade.displayLetter ?? '',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Text(
              'Add score',
              style: TextStyle(
                color: AppColors.brandYellow,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentLine extends StatelessWidget {
  const _StudentLine({required this.studentId, required this.firestore});

  final String studentId;
  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: firestore.getUser(studentId),
      builder: (context, snap) {
        final name = snap.data?.displayNameIndonesian ?? '…';
        return Text(
          name,
          style: const TextStyle(fontSize: 13),
        );
      },
    );
  }
}

/// Create a grade (with optional immediate score) or fill/edit an existing
/// grade's score.
class _GradeFormSheet extends StatefulWidget {
  const _GradeFormSheet({required this.teacherId, this.existing});

  final String teacherId;
  final Grade? existing;

  @override
  State<_GradeFormSheet> createState() => _GradeFormSheetState();
}

class _GradeFormSheetState extends State<_GradeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _scoreController = TextEditingController();

  String? _studentId;
  GradeCategory _category = GradeCategory.exam;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _studentId = existing.studentId;
      _titleController.text = existing.title;
      _category = existing.category;
      if (existing.score != null) {
        _scoreController.text = existing.score!.round().toString();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_studentId == null || _studentId!.isEmpty) {
      setState(() => _error = 'Pick a student.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final firestore = context.read<FirestoreService>();
    final scoreText = _scoreController.text.trim();
    final score = scoreText.isEmpty ? null : num.tryParse(scoreText);
    final navigator = Navigator.of(context);

    try {
      if (_isEditing) {
        final existing = widget.existing!;
        await firestore.updateGradeMeta(
          gradeId: existing.id,
          title: _titleController.text,
          category: _category,
        );
        if (score != null) {
          await firestore.setGradeScore(gradeId: existing.id, score: score);
        }
      } else {
        await firestore.createGrade(
          studentId: _studentId!,
          teacherId: widget.teacherId,
          title: _titleController.text,
          category: _category,
          score: score,
        );
      }
      navigator.pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not save grade: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit grade' : 'New grade',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 16),
              if (!_isEditing)
                StreamBuilder<List<AppUser>>(
                  stream: firestore.watchAllStudents(),
                  builder: (context, snap) {
                    final authUser = context.read<AuthService>().appUser;
                    final students =
                        (snap.data ?? const <AppUser>[]).where((s) {
                      // Admins see every active murid; teachers only their linked ones.
                      if (authUser?.isAdmin == true) return true;
                      return widget.teacherId.isEmpty ||
                          s.teacherId == widget.teacherId;
                    }).toList();
                    return DropdownButtonFormField<String>(
                      initialValue: _studentId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Student'),
                      items: [
                        for (final s in students)
                          DropdownMenuItem(
                            value: s.uid,
                            child: Text(s.displayNameIndonesian),
                          ),
                      ],
                      onChanged: (v) => setState(() => _studentId = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Pick a student' : null,
                    );
                  },
                ),
              if (!_isEditing) const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Speaking Test, Midterm',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GradeCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in GradeCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) =>
                    setState(() => _category = v ?? GradeCategory.other),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Score (0–100)'
                      : 'Score (0–100) — leave blank to schedule',
                  helperText: _buildLetterHint(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return null;
                  final n = num.tryParse(text);
                  if (n == null || n < 0 || n > 100) {
                    return 'Enter a number 0–100';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Save' : 'Create grade'),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _confirmDelete,
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    label: Text('Delete grade',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _buildLetterHint() {
    final text = _scoreController.text.trim();
    if (text.isEmpty) return null;
    final n = num.tryParse(text);
    if (n == null || n < 0 || n > 100) return null;
    return 'Letter grade: ${GradeUtils.letterGradeFor(n)}';
  }

  Future<void> _confirmDelete() async {
    final navigator = Navigator.of(context);
    final firestore = context.read<FirestoreService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete grade?'),
        content: const Text('This removes the grade for this student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await firestore.deleteGrade(widget.existing!.id);
    navigator.pop();
  }
}
