import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/responsive_card_grid.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/exercise_widgets.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../models/exercise_assignment.dart';
import '../../models/exercise_result.dart';
import '../../models/exercise.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../services/firestore_service.dart';
import 'exercise_assign_dialog.dart';

class TeacherExercisesTab extends StatefulWidget {
  const TeacherExercisesTab({super.key});

  @override
  State<TeacherExercisesTab> createState() => _TeacherExercisesTabState();
}

class _TeacherExercisesTabState extends State<TeacherExercisesTab> {
  String? _selectedHsk;
  ExerciseSkillCategory? _selectedSkill;

  List<Exercise> _filterExercises(List<Exercise> exercises) {
    return exercises.where((exercise) {
      final hskMatch = _selectedHsk == null || exercise.level == _selectedHsk;
      final skillMatch =
          _selectedSkill == null || exercise.skillCategory == _selectedSkill;
      return hskMatch && skillMatch;
    }).toList();
  }

  Map<ExerciseSkillCategory, List<Exercise>> _groupBySkill(
    List<Exercise> exercises,
  ) {
    final grouped = {
      for (final category in ExerciseSkillCategory.values)
        category: <Exercise>[],
    };
    for (final exercise in exercises) {
      grouped[exercise.skillCategory]!.add(exercise);
    }
    return grouped;
  }

  Widget _buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HSK level',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedHsk == null,
                onSelected: (_) => setState(() => _selectedHsk = null),
                selectedColor: AppColors.teal.withValues(alpha: 0.15),
                checkmarkColor: AppColors.teal,
              ),
              for (final level in AppConstants.hskLevels)
                FilterChip(
                  label: Text(level),
                  selected: _selectedHsk == level,
                  onSelected: (_) => setState(() => _selectedHsk = level),
                  selectedColor: AppColors.teal.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.teal,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Skill section',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedSkill == null,
                onSelected: (_) => setState(() => _selectedSkill = null),
                selectedColor: AppColors.navy.withValues(alpha: 0.1),
                checkmarkColor: AppColors.navy,
              ),
              for (final category in ExerciseSkillCategory.values)
                FilterChip(
                  label: Text(category.label),
                  selected: _selectedSkill == category,
                  onSelected: (_) => setState(() => _selectedSkill = category),
                  selectedColor: AppColors.navy.withValues(alpha: 0.1),
                  checkmarkColor: AppColors.navy,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageBanner(AppUser? user) {
    if (ExerciseAuthoringPlatform.canManageExercises(user)) {
      return const SizedBox.shrink();
    }

    final isTeacherOnWeb =
        user?.isTeacher == true && ExerciseAuthoringPlatform.isWeb;
    final message = !ExerciseAuthoringPlatform.isWeb
        ? ExerciseAuthoringPlatform.unsupportedMessage
        : isTeacherOnWeb
            ? ExerciseAuthoringPlatform.teacherReadOnlyMessage
            : ExerciseAuthoringPlatform.adminOnlyMessage;
    final title = isTeacherOnWeb ? 'View only' : 'Admin access required';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isTeacherOnWeb
                  ? Icons.visibility_outlined
                  : ExerciseAuthoringPlatform.isWeb
                      ? Icons.admin_panel_settings_outlined
                      : Icons.laptop_mac_outlined,
              color: AppColors.navy,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text(
          'Delete "${exercise.title}"? This cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await context.read<FirestoreService>().deleteExercise(exercise.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildQuestionBankButton(BuildContext context, bool canManage) {
    // Levels (assignment bundles) are for all staff; authoring tools stay
    // admin-only on web.
    final isAdmin = GoRouterState.of(context).uri.path.startsWith('/admin');
    final base = isAdmin ? '/admin' : '/teacher';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (canManage) ...[
            OutlinedButton.icon(
              onPressed: () => context.push('$base/exercise/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New exercise'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('$base/question-bank'),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Question bank'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('$base/quizzes'),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Quizzes'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('$base/levels'),
              icon: const Icon(Icons.layers_outlined),
              label: const Text('Levels'),
            ),
          ),
        ],
      ),
    );
  }

  String _exerciseEditPath(BuildContext context, String exerciseId) {
    final isAdmin = GoRouterState.of(context).uri.path.startsWith('/admin');
    final base = isAdmin ? '/admin' : '/teacher';
    return '$base/exercise/$exerciseId/edit';
  }

  /// The students who can open the exercise: the ones it is assigned to.
  List<AppUser> _studentsForExercise(
    List<AppUser> students,
    List<ExerciseAssignment> assignments,
    Exercise exercise,
  ) {
    final ids = {
      for (final a in assignments)
        if (a.exerciseId == exercise.id) a.studentId,
    };
    return students.where((s) => ids.contains(s.uid)).toList();
  }

  /// "3 worksheets · 1 question" for a package, "7 questions" otherwise.
  String _contentsLabel(Exercise exercise) {
    if (exercise.isPackage) {
      final n = exercise.bankSheets.length;
      final q = exercise.bankQuestionIds.length;
      return [
        if (n > 0) '$n worksheet${n == 1 ? '' : 's'}',
        if (q > 0) '$q single question${q == 1 ? '' : 's'}',
      ].join(' · ');
    }
    final n = exercise.questions.length;
    final unit = exercise.type == ExerciseType.composeSentences
        ? 'sentence'
        : 'question';
    return '${exercise.type.label} · $n $unit${n == 1 ? '' : 's'}';
  }

  Widget _buildExerciseCard({
    required BuildContext context,
    required Exercise exercise,
    required List<ExerciseResult> allResults,
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
    required bool compact,
    required bool canManage,
  }) {
    final eligibleStudents =
        _studentsForExercise(students, assignments, exercise);
    final eligibleCount = eligibleStudents.length;
    final scoresByStudent = ExerciseUtils.bestScoresByStudentForExercise(
      exercise.id,
      allResults,
    );
    final completedCount = eligibleStudents
        .where((student) => scoresByStudent.containsKey(student.uid))
        .length;
    final accessLabel = !exercise.isPublished
        ? 'Draft — not visible to students'
        : eligibleCount == 0
            ? 'Not assigned yet'
            : 'Assigned to $eligibleCount student${eligibleCount == 1 ? '' : 's'}';

    return AppCard(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 15 : 16,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (exercise.level != null)
                          HskBadge(label: exercise.level!),
                        _SkillSectionBadge(
                          label: exercise.skillCategory.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (exercise.isPackage) 'From the question bank',
                        _contentsLabel(exercise),
                        accessLabel,
                        if (exercise.isPublished && eligibleCount > 0)
                          '$completedCount/$eligibleCount completed',
                      ].join(' · '),
                      maxLines: compact ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (exercise.isPublished
                          ? AppColors.success
                          : AppColors.textSecondary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exercise.isPublished ? 'Published' : 'Draft',
                  style: TextStyle(
                    color: exercise.isPublished
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (!compact && exercise.instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exercise.instructions,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          if (exercise.isPublished && eligibleCount > 0) ...[
            SizedBox(height: compact ? 10 : 12),
            OutlinedButton.icon(
              onPressed: () => showExerciseHomeworkProgressDialog(
                context: context,
                exercise: exercise,
                assignments: assignments
                    .where((a) => a.exerciseId == exercise.id)
                    .toList(),
                results: allResults,
                students: students,
              ),
              icon: Icon(Icons.people_outline, size: compact ? 16 : 18),
              label: Text(
                compact
                    ? 'Progress ($completedCount/$eligibleCount)'
                    : 'View progress ($completedCount/$eligibleCount)',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(compact ? 36 : 42),
                textStyle: TextStyle(fontSize: compact ? 12 : 14),
              ),
            ),
          ],
          SizedBox(height: compact ? 10 : 12),
          if (exercise.isPublished)
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 8 : 10),
              child: FilledButton.icon(
                onPressed: () =>
                    showExerciseAssignDialog(context, exercise: exercise),
                icon: Icon(Icons.assignment_ind_outlined,
                    size: compact ? 16 : 18),
                label:
                    Text(eligibleCount == 0 ? 'Assign to students' : 'Assign'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: Size.fromHeight(compact ? 36 : 42),
                  textStyle: TextStyle(fontSize: compact ? 12 : 14),
                ),
              ),
            ),
          if (canManage)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      _exerciseEditPath(context, exercise.id),
                      extra: exercise,
                    ),
                    icon: Icon(Icons.edit_outlined, size: compact ? 16 : 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(compact ? 36 : 42),
                      textStyle: TextStyle(fontSize: compact ? 12 : 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, exercise),
                    icon: Icon(Icons.delete_outline, size: compact ? 16 : 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: Size.fromHeight(compact ? 36 : 42),
                      textStyle: TextStyle(fontSize: compact ? 12 : 14),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid({
    required BuildContext context,
    required List<Exercise> exercises,
    required List<ExerciseResult> allResults,
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
    required double maxWidth,
    required bool canManage,
  }) {
    final columns = ResponsiveCardGrid.columnCount(maxWidth);
    final compact = columns > 1;

    return ResponsiveCardGrid(
      width: maxWidth,
      children: [
        for (final exercise in exercises)
          _buildExerciseCard(
            context: context,
            exercise: exercise,
            allResults: allResults,
            students: students,
            assignments: assignments,
            compact: compact,
            canManage: canManage,
          ),
      ],
    );
  }

  List<Widget> _buildGroupedExerciseList({
    required BuildContext context,
    required List<Exercise> filtered,
    required List<ExerciseResult> allResults,
    required List<AppUser> students,
    required List<ExerciseAssignment> assignments,
    required double maxWidth,
    required bool canManage,
  }) {
    if (filtered.isEmpty) {
      return [
        EmptyState(
          icon: Icons.filter_list_off,
          title: 'No exercises in this category',
          subtitle: canManage
              ? 'Try another HSK level or skill section, or create a new exercise.'
              : 'Try another HSK level or skill section.',
        ),
      ];
    }

    if (_selectedSkill != null) {
      return [
        _buildExerciseGrid(
          context: context,
          exercises: filtered,
          allResults: allResults,
          students: students,
          assignments: assignments,
          maxWidth: maxWidth,
          canManage: canManage,
        ),
      ];
    }

    final grouped = _groupBySkill(filtered);
    final widgets = <Widget>[];
    for (final category in ExerciseSkillCategory.values) {
      final items = grouped[category]!;
      if (items.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            category.label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.navy,
            ),
          ),
        ),
      );
      widgets.add(
        _buildExerciseGrid(
          context: context,
          exercises: items,
          allResults: allResults,
          students: students,
          assignments: assignments,
          maxWidth: maxWidth,
          canManage: canManage,
        ),
      );
      widgets.add(const SizedBox(height: 4));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().appUser;
    final canManage = ExerciseAuthoringPlatform.canManageExercises(user);

    return StreamBuilder<List<Exercise>>(
      stream: context.read<FirestoreService>().watchAllExercises(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final exercises = snapshot.data ?? [];
        if (exercises.isEmpty) {
          return Column(
            children: [
              _buildManageBanner(user),
              const Expanded(
                child: EmptyState(
                  icon: Icons.fitness_center_outlined,
                  title: 'No exercises yet',
                  subtitle:
                      'An exercise bundles worksheets from the question bank; '
                      'students see it once it is assigned to them. '
                      'Admins create exercises on web.',
                ),
              ),
            ],
          );
        }

        return StreamBuilder<List<ExerciseResult>>(
          stream: context.read<FirestoreService>().watchAllExerciseResults(),
          builder: (context, resultsSnap) {
            return StreamBuilder<List<AppUser>>(
              stream: context.read<FirestoreService>().watchAllStudents(),
              builder: (context, studentsSnap) {
                return StreamBuilder<List<ExerciseAssignment>>(
                  stream: context
                      .read<FirestoreService>()
                      .watchAllExerciseAssignments(),
                  builder: (context, assignSnap) {
                    final allResults = resultsSnap.data ?? [];
                    final students = studentsSnap.data ?? [];
                    final assignments =
                        assignSnap.data ?? const <ExerciseAssignment>[];
                    final filtered = _filterExercises(exercises);

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        _buildManageBanner(user),
                        _buildQuestionBankButton(context, canManage),
                        _buildCategoryFilters(),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                children: _buildGroupedExerciseList(
                                  context: context,
                                  filtered: filtered,
                                  allResults: allResults,
                                  students: students,
                                  assignments: assignments,
                                  maxWidth: constraints.maxWidth,
                                  canManage: canManage,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SkillSectionBadge extends StatelessWidget {
  const _SkillSectionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
