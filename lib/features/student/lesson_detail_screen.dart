import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../services/firestore_service.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  List<String> _vocabularyBlocks(String content) {
    final blocks = content
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();
    if (blocks.length > 1) return blocks;
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder(
        future: context.read<FirestoreService>().getLesson(lessonId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lesson = snapshot.data;
          if (lesson == null) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Lesson not found',
              subtitle: 'This lesson may have been removed.',
            );
          }

          final vocabulary = _vocabularyBlocks(lesson.content);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (lesson.level != null) ...[
                HskBadge(label: lesson.level!),
                const SizedBox(height: 12),
              ],
              Text(
                lesson.unit,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.termLabel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Vocabulary & notes'),
              const SizedBox(height: 8),
              ...vocabulary.map(
                (block) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Text(
                      block,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ),
                ),
              ),
              if (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up_outlined, color: AppColors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lesson.audioUrl!,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.push('/student/quiz/$lessonId'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Start quiz'),
              ),
            ],
          );
        },
      ),
    );
  }
}
