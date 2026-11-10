import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../core/widgets/status_pill.dart';
import '../../models/exercise_level.dart';
import '../../services/firestore_service.dart';

/// Staff list of exercise bundles ("Levels"). A level assigns every exercise
/// in it to every student in it; editing the level updates all of them.
class ExerciseLevelsScreen extends StatelessWidget {
  const ExerciseLevelsScreen({super.key, this.embedded = false});

  final bool embedded;

  String _base(BuildContext context) =>
      GoRouterState.of(context).uri.path.startsWith('/admin')
          ? '/admin'
          : '/teacher';

  Future<void> _delete(BuildContext context, ExerciseLevel level) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${level.name}"?'),
        content: Text(
          'This removes the level and un-assigns its ${level.exerciseIds.length} '
          'exercise(s) from its ${level.studentIds.length} student(s). '
          'Exercises students already finished keep their scores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete level'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<FirestoreService>().deleteExerciseLevel(level.id);
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final base = _base(context);
    return ShellNestedPage(
      embedded: embedded,
      title: 'Levels',
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('$base/levels/new'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New level'),
        ),
      ],
      child: StreamBuilder<List<ExerciseLevel>>(
        stream: firestore.watchExerciseLevels(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final levels = snap.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'A level is a bundle of exercises for a group of students. Add '
                'students to a level once; every exercise in the level is '
                'assigned to them, and anything you add or remove later applies '
                'to all of them.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (levels.isEmpty)
                const EmptyState(
                  icon: Icons.layers_outlined,
                  title: 'No levels yet',
                  subtitle: 'Tap New level to bundle exercises for a group.',
                )
              else
                for (final level in levels) ...[
                  AppCard(
                    onTap: () => context.push('$base/levels/${level.id}/edit'),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.layers_outlined,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      level.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (level.hskLevel != null) ...[
                                    const SizedBox(width: 8),
                                    StatusPill(
                                      label: level.hskLevel!,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${level.exerciseIds.length} exercise'
                                '${level.exerciseIds.length == 1 ? '' : 's'} · '
                                '${level.studentIds.length} student'
                                '${level.studentIds.length == 1 ? '' : 's'}'
                                '${level.description?.isNotEmpty == true ? ' · ${level.description}' : ''}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete level',
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.error,
                          onPressed: () => _delete(context, level),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}
