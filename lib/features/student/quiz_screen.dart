import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/score_summary.dart';
import '../../models/quiz.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Quiz? _quiz;
  int _currentIndex = 0;
  int? _selectedIndex;
  int _correct = 0;
  bool _loading = true;
  bool _finished = false;
  bool _submitting = false;
  bool _answerSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quiz =
        await context.read<FirestoreService>().getQuizForLesson(widget.lessonId);
    setState(() {
      _quiz = quiz;
      _loading = false;
    });
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null || _finished || _answerSubmitted) return;
    setState(() => _selectedIndex = index);
  }

  void _onPrimaryAction() {
    final quiz = _quiz!;
    if (_selectedIndex == null) return;

    if (!_answerSubmitted) {
      final isCorrect =
          _selectedIndex == quiz.questions[_currentIndex].correctIndex;
      if (isCorrect) _correct++;
      setState(() {
        _answerSubmitted = true;
      });
      return;
    }

    if (_currentIndex + 1 >= quiz.questions.length) {
      _submitResults();
    } else {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answerSubmitted = false;
      });
    }
  }

  Future<void> _submitResults() async {
    final quiz = _quiz!;
    final total = quiz.questions.length;
    final score = total == 0 ? 0 : ((_correct / total) * 100).round();

    setState(() {
      _finished = true;
      _submitting = true;
    });

    final student = context.read<AuthService>().appUser!;
    await context.read<FirestoreService>().saveQuizResult(
          studentId: student.uid,
          quizId: quiz.id,
          lessonId: widget.lessonId,
          score: score,
        );

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _quiz == null
              ? const EmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'No quiz for this lesson',
                  subtitle: 'No quiz is available for this lesson yet.',
                )
              : _finished
                  ? _buildResult()
                  : _buildQuestion(),
    );
  }

  Widget _buildResult() {
    final total = _quiz!.questions.length;
    final score = total == 0 ? 0 : ((_correct / total) * 100).round();

    return ScoreSummary(
      scorePercent: score,
      correctCount: _correct,
      totalCount: total,
      primaryLabel: 'Back to home',
      loading: _submitting,
      onPrimaryPressed: _submitting ? null : () => context.go('/student'),
    );
  }

  Widget _resultBanner() {
    final correct =
        _selectedIndex == _quiz!.questions[_currentIndex].correctIndex;
    final color = correct ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Text(
            correct ? 'Correct!' : 'Not quite',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final question = _quiz!.questions[_currentIndex];
    final progress = (_currentIndex + 1) / _quiz!.questions.length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          color: AppColors.teal,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Text(
          'Question ${_currentIndex + 1} of ${_quiz!.questions.length}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Text(
          question.question,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
        const SizedBox(height: 20),
        ...List.generate(question.options.length, (i) {
          final selected = _selectedIndex == i;
          final isCorrect = i == question.correctIndex;
          Color? borderColor;
          Color? fillColor;
          IconData? resultIcon;
          Color? resultIconColor;
          if (_answerSubmitted) {
            if (isCorrect) {
              borderColor = AppColors.success;
              fillColor = AppColors.success.withValues(alpha: 0.14);
              resultIcon = Icons.check_circle;
              resultIconColor = AppColors.success;
            } else if (selected) {
              borderColor = AppColors.error;
              fillColor = AppColors.error.withValues(alpha: 0.10);
              resultIcon = Icons.cancel;
              resultIconColor = AppColors.error;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => _selectAnswer(i),
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: 2)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.teal.withValues(alpha: 0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected ? AppColors.teal : AppColors.border,
                        ),
                      ),
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              selected ? AppColors.teal : AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options[i],
                        style: const TextStyle(fontSize: 18, height: 1.4),
                      ),
                    ),
                    if (resultIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(resultIcon, color: resultIconColor, size: 26),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (_answerSubmitted) ...[
          const SizedBox(height: 20),
          _resultBanner(),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _selectedIndex == null ? null : _onPrimaryAction,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            !_answerSubmitted
                ? 'Check answer'
                : _currentIndex + 1 >= _quiz!.questions.length
                    ? 'Finish quiz'
                    : 'Next question',
          ),
        ),
      ],
    );
  }
}
