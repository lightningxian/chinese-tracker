import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/evaluation.dart';
import '../../models/org_settings.dart';
import '../../services/firestore_service.dart';

/// Staff-facing management of a student's semester evaluations. New/edit is
/// gated by the `evaluationFormsOpen` org setting.
class StudentEvaluationsSection extends StatelessWidget {
  const StudentEvaluationsSection({
    super.key,
    required this.studentId,
    required this.teacherId,
  });

  final String studentId;
  final String teacherId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();

    return StreamBuilder<OrgSettings>(
      stream: firestore.watchOrgSettings(),
      builder: (context, settingsSnap) {
        final formsOpen =
            (settingsSnap.data ?? OrgSettings.defaults).evaluationFormsOpen;

        return StreamBuilder<List<Evaluation>>(
          stream: firestore.watchStudentEvaluations(studentId),
          builder: (context, snap) {
            final evaluations = snap.data ?? const <Evaluation>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: l.evaluationsTitle,
                  action: TextButton.icon(
                    onPressed: formsOpen
                        ? () => _openEditor(
                              context,
                              studentId: studentId,
                              teacherId: teacherId,
                            )
                        : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l.evaluationsNew),
                  ),
                ),
                if (!formsOpen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l.evaluationsFormsClosed,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (evaluations.isEmpty)
                  AppCard(
                    child: Text(
                      l.evaluationsEmpty,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  for (final e in evaluations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EvaluationRow(
                        evaluation: e,
                        canEdit: formsOpen,
                        onEdit: () => _openEditor(
                          context,
                          studentId: studentId,
                          teacherId: teacherId,
                          existing: e,
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    required String studentId,
    required String teacherId,
    Evaluation? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EvaluationEditorSheet(
        studentId: studentId,
        teacherId: teacherId,
        existing: existing,
      ),
    );
  }
}

class _EvaluationRow extends StatelessWidget {
  const _EvaluationRow({
    required this.evaluation,
    required this.canEdit,
    required this.onEdit,
  });

  final Evaluation evaluation;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = evaluation;
    final color = e.isPublished ? AppColors.success : AppColors.textSecondary;
    return AppCard(
      onTap: canEdit ? onEdit : null,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.term.isEmpty ? l.evaluationsFallbackTitle : e.term,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (e.rating != null) ...[
                Icon(Icons.star, size: 15, color: AppColors.teal),
                const SizedBox(width: 2),
                Text('${e.rating}/5',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    )),
                const SizedBox(width: 10),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.isPublished ? l.evaluationsPublished : l.evaluationsDraft,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (e.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              e.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvaluationEditorSheet extends StatefulWidget {
  const _EvaluationEditorSheet({
    required this.studentId,
    required this.teacherId,
    this.existing,
  });

  final String studentId;
  final String teacherId;
  final Evaluation? existing;

  @override
  State<_EvaluationEditorSheet> createState() => _EvaluationEditorSheetState();
}

class _EvaluationEditorSheetState extends State<_EvaluationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _termController;
  late final TextEditingController _strengthsController;
  late final TextEditingController _improvementsController;
  late final TextEditingController _commentController;
  int? _rating;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _termController = TextEditingController(text: e?.term ?? '');
    _strengthsController = TextEditingController(text: e?.strengths ?? '');
    _improvementsController =
        TextEditingController(text: e?.improvements ?? '');
    _commentController = TextEditingController(text: e?.comment ?? '');
    _rating = e?.rating?.toInt();
  }

  @override
  void dispose() {
    _termController.dispose();
    _strengthsController.dispose();
    _improvementsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final firestore = context.read<FirestoreService>();
    final evaluation = Evaluation(
      id: widget.existing?.id ?? '',
      studentId: widget.studentId,
      teacherId: widget.teacherId,
      term: _termController.text.trim(),
      status: publish ? 'published' : 'draft',
      rating: _rating,
      strengths: _strengthsController.text.trim(),
      improvements: _improvementsController.text.trim(),
      comment: _commentController.text.trim(),
    );
    try {
      if (_isEditing) {
        await firestore.updateEvaluation(evaluation);
      } else {
        await firestore.createEvaluation(evaluation);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await context.read<FirestoreService>().deleteEvaluation(
            widget.existing!.id,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? l.evaluationsEditTitle : l.evaluationsNewTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Text(_error!, style: TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _termController,
                decoration: InputDecoration(
                  labelText: l.evaluationsTermLabel,
                  hintText: l.evaluationsTermHint,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l.evaluationsTermRequired
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l.evaluationsRating,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(
                        () => _rating = _rating == i ? null : i,
                      ),
                      icon: Icon(
                        (_rating ?? 0) >= i ? Icons.star : Icons.star_border,
                        color: AppColors.teal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _strengthsController,
                maxLines: 2,
                decoration:
                    InputDecoration(labelText: l.evaluationsStrengths),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _improvementsController,
                maxLines: 2,
                decoration:
                    InputDecoration(labelText: l.evaluationsImprovements),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.evaluationsComment),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _save(publish: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l.evaluationsSaveDraft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(publish: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.evaluationsPublish),
                    ),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(
                    l.teacherAttDelete,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
