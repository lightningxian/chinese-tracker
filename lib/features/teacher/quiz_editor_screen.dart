import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/exercise_type.dart';
import '../../models/lesson.dart';
import '../../models/quiz.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../question_bank/question_bank_screen.dart';

/// Staff quiz editor — tie a quiz to a lesson and pull MC questions from the bank.
class QuizEditorScreen extends StatefulWidget {
  const QuizEditorScreen({
    super.key,
    this.embedded = false,
    this.existing,
  });

  final bool embedded;
  final Quiz? existing;

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  final _titleController = TextEditingController();
  String? _lessonId;
  final List<QuizQuestion> _questions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    if (q != null) {
      _titleController.text = q.title;
      _lessonId = q.lessonId;
      _questions.addAll(q.questions);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addFromBank(String ownerId) async {
    final picked = await showQuestionBankPicker(
      context,
      ownerId: ownerId,
      type: ExerciseType.multipleChoice,
    );
    if (picked == null || picked.isEmpty) return;

    setState(() {
      for (final item in picked) {
        final q = item.question;
        _questions.add(
          QuizQuestion(
            question: q.prompt,
            options: q.options,
            correctIndex: q.correctIndex,
            imageUrl: q.imageUrl.isNotEmpty ? q.imageUrl : null,
            audioUrl: q.audioUrl.isNotEmpty ? q.audioUrl : null,
          ),
        );
      }
    });
  }

  Future<void> _save(String teacherId) async {
    final title = _titleController.text.trim();
    final lessonId = _lessonId;
    if (title.isEmpty || lessonId == null || lessonId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and select a lesson.')),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one question.')),
      );
      return;
    }

    setState(() => _saving = true);
    final firestore = context.read<FirestoreService>();
    final quiz = Quiz(
      id: widget.existing?.id ?? '',
      lessonId: lessonId,
      title: title,
      teacherId: teacherId,
      questions: _questions,
    );

    try {
      if (widget.existing != null) {
        await firestore.updateQuiz(quiz);
      } else {
        await firestore.createQuiz(quiz);
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final teacherId = AppConstants.contentTeacherId(user);
    final ownerId = AppConstants.contentTeacherId(user);

    return ShellNestedPage(
      embedded: widget.embedded,
      title: widget.existing == null ? 'New quiz' : 'Edit quiz',
      child: StreamBuilder<List<Lesson>>(
        stream: context.read<FirestoreService>().watchLessons(teacherId),
        builder: (context, lessonSnap) {
          final lessons = lessonSnap.data ?? const <Lesson>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Quiz title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _lessonId,
                  decoration: const InputDecoration(labelText: 'Lesson'),
                  items: [
                    for (final l in lessons)
                      DropdownMenuItem(value: l.id, child: Text(l.title)),
                  ],
                  onChanged: (v) => setState(() => _lessonId = v),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Questions (${_questions.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _addFromBank(ownerId),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('From bank'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_questions.isEmpty)
                  const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No questions yet — pull from the bank.'),
                    ),
                  )
                else
                  ...List.generate(_questions.length, (i) {
                    final q = _questions[i];
                    return AppCard(
                      child: ListTile(
                        title: Text(q.question),
                        subtitle: Text(
                          q.options.join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _questions.removeAt(i)),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(teacherId),
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
                      : const Text('Save quiz'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lists quizzes for staff with edit/delete.
class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final teacherId = AppConstants.contentTeacherId(user);
    final firestore = context.read<FirestoreService>();

    return ShellNestedPage(
      embedded: embedded,
      title: 'Quizzes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          user.isAdmin ? '/admin/quizzes/new' : '/teacher/quizzes/new',
        ),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: const Text('New quiz'),
      ),
      child: StreamBuilder<List<Quiz>>(
        stream: firestore.watchQuizzesForTeacher(teacherId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final quizzes = snap.data ?? const <Quiz>[];
          if (quizzes.isEmpty) {
            return const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'No quizzes yet',
              subtitle: 'Create a quiz and attach it to a lesson.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final q = quizzes[i];
              return AppCard(
                child: ListTile(
                  title: Text(q.title),
                  subtitle: Text(
                    '${q.questions.length} question(s) · lesson ${q.lessonId}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'delete') {
                        await firestore.deleteQuiz(q.id);
                      } else if (action == 'edit') {
                        if (!context.mounted) return;
                        context.push(
                          user.isAdmin
                              ? '/admin/quizzes/${q.id}/edit'
                              : '/teacher/quizzes/${q.id}/edit',
                          extra: q,
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
