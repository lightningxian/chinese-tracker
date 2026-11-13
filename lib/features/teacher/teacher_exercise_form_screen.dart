import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_authoring_platform.dart';
import '../../core/constants/worksheet_import_platform.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/question_import_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/exercise.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/worksheet_import_stage.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/question_bank_media_service.dart';
import '../../services/worksheet_import_service.dart';
import '../question_bank/question_bank_screen.dart';
import 'widgets/matching_exercise_editor.dart';
import 'widgets/worksheet_import_progress_dialog.dart';
import 'worksheet_import_review_screen.dart';

class TeacherExerciseFormScreen extends StatefulWidget {
  const TeacherExerciseFormScreen({
    super.key,
    required this.teacherId,
    this.exercise,
    this.embedded = false,
    this.initialImport,
  });

  final String teacherId;
  final Exercise? exercise;
  final bool embedded;

  /// A worksheet already scanned and reviewed (Scan worksheet button): the
  /// form opens filled in with it.
  final WorksheetImportReviewResult? initialImport;

  bool get isEditing => exercise != null;

  @override
  State<TeacherExerciseFormScreen> createState() =>
      _TeacherExerciseFormScreenState();
}

class _McQuestionDraft {
  _McQuestionDraft({
    String prompt = '',
    List<String>? options,
    this.correctIndex = 0,
  })  : promptController = TextEditingController(text: prompt),
        optionControllers = List.generate(
          (options?.length ?? 0) > 4 ? options!.length : 4,
          (i) => TextEditingController(
            text: i < (options?.length ?? 0) ? options![i] : '',
          ),
        );

  final TextEditingController promptController;
  final List<TextEditingController> optionControllers;
  int correctIndex;

  void dispose() {
    promptController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }

  ExerciseQuestion? toQuestion() {
    final prompt = promptController.text.trim();
    final options = optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    if (prompt.isEmpty || options.length < 2) return null;
    final index = correctIndex.clamp(0, options.length - 1);
    return ExerciseQuestion(
      prompt: prompt,
      options: options,
      correctIndex: index,
    );
  }
}

/// "Type the hanzi" (sentence with （ ）, pinyin hint, accepted answers)
/// and picture sentences (keyword, optional picture).
class _TypedQuestionDraft {
  _TypedQuestionDraft({
    String prompt = '',
    String keyword = '',
    List<String> answers = const [],
    this.imageUrl = '',
  })  : promptController = TextEditingController(text: prompt),
        keywordController = TextEditingController(text: keyword),
        answersController = TextEditingController(text: answers.join(', '));

  final TextEditingController promptController;
  final TextEditingController keywordController;
  final TextEditingController answersController;
  String imageUrl;

  void dispose() {
    promptController.dispose();
    keywordController.dispose();
    answersController.dispose();
  }

  ExerciseQuestion? toQuestion(ExerciseType type) {
    final prompt = promptController.text.trim();
    final keyword = keywordController.text.trim();
    if (type == ExerciseType.pictureSentence) {
      if (keyword.isEmpty) return null;
      return ExerciseQuestion(
        prompt: prompt.isEmpty ? keyword : prompt,
        keyword: keyword,
        imageUrl: imageUrl,
      );
    }
    final answers = answersController.text
        .split(RegExp(r'[,，/、\n]'))
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    if (prompt.isEmpty || answers.isEmpty) return null;
    return ExerciseQuestion(prompt: prompt, keyword: keyword, options: answers);
  }
}

class _ComposeQuestionDraft {
  _ComposeQuestionDraft({
    String prompt = '',
    List<String>? segments,
  })  : promptController = TextEditingController(text: prompt),
        segmentControllers = (segments == null || segments.isEmpty)
            ? [
                TextEditingController(),
                TextEditingController(),
              ]
            : segments
                .map((segment) => TextEditingController(text: segment))
                .toList();

  final TextEditingController promptController;
  final List<TextEditingController> segmentControllers;

  void dispose() {
    promptController.dispose();
    for (final c in segmentControllers) {
      c.dispose();
    }
  }

  void addSegment() {
    segmentControllers.add(TextEditingController());
  }

  void removeSegment(int index) {
    if (segmentControllers.length <= 2) return;
    segmentControllers[index].dispose();
    segmentControllers.removeAt(index);
  }

  void moveSegment(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= segmentControllers.length) return;
    final current = segmentControllers.removeAt(index);
    segmentControllers.insert(target, current);
  }

  ExerciseQuestion? toQuestion() {
    final prompt = promptController.text.trim();
    final segments = segmentControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.length < 2) return null;
    return ExerciseQuestion(
      prompt: prompt,
      segments: segments,
    );
  }
}

class _TeacherExerciseFormScreenState extends State<TeacherExerciseFormScreen> {
  /// Matching and fill-in-the-blank share the editor: one answer bank (A–F)
  /// and one prompt per item with the letter of the right answer.
  static bool _usesBank(ExerciseType type) =>
      type == ExerciseType.matching || type == ExerciseType.readingCloze;

  /// Typed answers: type the hanzi, picture sentence.
  static bool _usesTyped(ExerciseType type) =>
      type == ExerciseType.typeHanzi || type == ExerciseType.pictureSentence;

  /// Types that can show a reading passage above the questions.
  static bool _hasPassage(ExerciseType type) =>
      type == ExerciseType.multipleChoice ||
      type == ExerciseType.listening ||
      type == ExerciseType.readingCloze;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _passageController = TextEditingController();
  final List<_McQuestionDraft> _mcQuestions = [];
  final List<_ComposeQuestionDraft> _composeQuestions = [];
  final List<MatchingQuestionDraft> _matchingQuestions = [];
  final List<_TypedQuestionDraft> _typedQuestions = [];
  late List<TextEditingController> _matchingOptionControllers =
      MatchingExerciseEditor.createOptionControllers();
  ExerciseType _type = ExerciseType.multipleChoice;
  String _level = AppConstants.hskLevels.first;
  ExerciseSkillCategory _skillCategory = ExerciseSkillCategory.reading;
  bool _saving = false;
  bool _importingWorksheet = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final import = widget.initialImport?.parseResult;
    if (import != null && widget.exercise == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyImportedWorksheet(import);
      });
    }
    final exercise = widget.exercise;
    if (exercise != null) {
      _titleController.text = exercise.title;
      _instructionsController.text = exercise.instructions;
      _passageController.text = exercise.passage;
      _level = exercise.level ?? AppConstants.hskLevels.first;
      _skillCategory = exercise.skillCategory;
      _type = exercise.type;
      for (final q in exercise.questions) {
        if (exercise.type == ExerciseType.composeSentences) {
          _composeQuestions.add(
            _ComposeQuestionDraft(
              prompt: q.prompt,
              segments: q.segments,
            ),
          );
        } else if (_usesBank(exercise.type)) {
          _matchingQuestions.add(
            MatchingQuestionDraft(
              prompt: q.prompt,
              correctIndex: q.correctIndex,
            ),
          );
        } else if (_usesTyped(_type)) {
          _typedQuestions.add(
            _TypedQuestionDraft(
              prompt: q.prompt,
              keyword: q.keyword,
              answers: q.options,
              imageUrl: q.imageUrl,
            ),
          );
        } else {
          final options = q.options.length >= 4
              ? q.options
              : [
                  ...q.options,
                  for (var i = q.options.length; i < 4; i++) '',
                ];
          _mcQuestions.add(
            _McQuestionDraft(
              prompt: q.prompt,
              options: options,
              correctIndex: q.correctIndex,
            ),
          );
        }
      }
      if (_usesBank(exercise.type)) {
        MatchingExerciseEditor.disposeOptionControllers(
            _matchingOptionControllers);
        final options = exercise.matchingOptions;
        _matchingOptionControllers =
            MatchingExerciseEditor.createOptionControllers(
          List.generate(
              6, (index) => index < options.length ? options[index] : ''),
        );
      }
    }
    _ensureAtLeastOneQuestion();
  }

  /// Questions come from the worksheet scanner (or the bank); the form never
  /// starts with a blank question to type into.
  void _ensureAtLeastOneQuestion() {}

  void _clearAllQuestionDrafts() {
    for (final q in _mcQuestions) {
      q.dispose();
    }
    for (final q in _composeQuestions) {
      q.dispose();
    }
    for (final q in _matchingQuestions) {
      q.dispose();
    }
    for (final q in _typedQuestions) {
      q.dispose();
    }
    _mcQuestions.clear();
    _composeQuestions.clear();
    _matchingQuestions.clear();
    _typedQuestions.clear();
    MatchingExerciseEditor.disposeOptionControllers(_matchingOptionControllers);
    _matchingOptionControllers =
        MatchingExerciseEditor.createOptionControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    _passageController.dispose();
    for (final q in _mcQuestions) {
      q.dispose();
    }
    for (final q in _composeQuestions) {
      q.dispose();
    }
    for (final q in _matchingQuestions) {
      q.dispose();
    }
    for (final q in _typedQuestions) {
      q.dispose();
    }
    MatchingExerciseEditor.disposeOptionControllers(_matchingOptionControllers);
    super.dispose();
  }

  void _onTypeChanged(ExerciseType? value) {
    if (value == null || value == _type) return;
    if (!value.isImplemented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${value.label} is recognized on import but not editable yet. '
            'Use compose sentences or matching for now.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _clearAllQuestionDrafts();
      _type = value;
      _skillCategory = ExerciseSkillCategory.forExerciseType(value);
      _ensureAtLeastOneQuestion();
      _error = null;
    });
  }

  void _addQuestion() {
    setState(() {
      if (_type == ExerciseType.composeSentences) {
        _composeQuestions.add(_ComposeQuestionDraft());
      } else if (_usesBank(_type)) {
        _matchingQuestions.add(MatchingQuestionDraft());
      } else if (_usesTyped(_type)) {
        _typedQuestions.add(_TypedQuestionDraft());
      } else {
        _mcQuestions.add(_McQuestionDraft());
      }
    });
  }

  Future<void> _addFromBank() async {
    final user = context.read<AuthService>().appUser;
    final ownerId =
        user == null ? widget.teacherId : AppConstants.contentTeacherId(user);
    final picked = await showQuestionBankPicker(
      context,
      ownerId: ownerId,
      type: _type,
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      for (final item in picked) {
        final q = item.question;
        if (_type == ExerciseType.composeSentences) {
          _composeQuestions.add(
            _ComposeQuestionDraft(prompt: q.prompt, segments: q.segments),
          );
        } else if (_usesBank(_type)) {
          // An empty exercise takes the word bank stored with the question.
          final bankEmpty =
              _matchingOptionControllers.every((c) => c.text.trim().isEmpty);
          if (bankEmpty && q.options.isNotEmpty) {
            MatchingExerciseEditor.disposeOptionControllers(
                _matchingOptionControllers);
            _matchingOptionControllers =
                MatchingExerciseEditor.createOptionControllers(
              List.generate(
                6,
                (i) => i < q.options.length ? q.options[i] : '',
              ),
            );
          }
          _matchingQuestions.add(
            MatchingQuestionDraft(
              prompt: q.prompt,
              correctIndex: q.correctIndex,
            ),
          );
        } else if (_usesTyped(_type)) {
          _typedQuestions.add(
            _TypedQuestionDraft(
              prompt: q.prompt,
              keyword: q.keyword,
              answers: q.options,
              imageUrl: q.imageUrl,
            ),
          );
        } else {
          final options = q.options.length >= 4
              ? q.options
              : [
                  ...q.options,
                  for (var i = q.options.length; i < 4; i++) '',
                ];
          _mcQuestions.add(
            _McQuestionDraft(
              prompt: q.prompt,
              options: options,
              correctIndex: q.correctIndex,
            ),
          );
        }
      }
    });
  }

  void _removeQuestion(int index) {
    if (_type == ExerciseType.composeSentences) {
      if (_composeQuestions.length <= 1) return;
      setState(() {
        _composeQuestions[index].dispose();
        _composeQuestions.removeAt(index);
      });
    } else if (_usesBank(_type)) {
      if (_matchingQuestions.length <= 1) return;
      setState(() {
        _matchingQuestions[index].dispose();
        _matchingQuestions.removeAt(index);
      });
    } else if (_usesTyped(_type)) {
      setState(() {
        _typedQuestions[index].dispose();
        _typedQuestions.removeAt(index);
      });
    } else {
      if (_mcQuestions.length <= 1) return;
      setState(() {
        _mcQuestions[index].dispose();
        _mcQuestions.removeAt(index);
      });
    }
  }

  Future<void> _importFromWorksheet() async {
    final user = context.read<AuthService>().appUser;
    if (!WorksheetImportPlatform.isSupportedFor(user)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(WorksheetImportPlatform.unsupportedMessage)),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: WorksheetImportService.allowedExtensions.toList(),
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() => _error = 'Could not read the selected file.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _importingWorksheet = true;
      _error = null;
    });

    final progress = ValueNotifier(WorksheetImportStage.prepare());
    final fileName = file.name;

    unawaited(
      showWorksheetImportProgress(
        context: context,
        fileName: fileName,
        progress: progress,
      ),
    );

    try {
      final text =
          await context.read<WorksheetImportService>().extractTextFromWorksheet(
                bytes: bytes,
                fileName: fileName,
                onProgress: (stage) => progress.value = stage,
              );
      if (!mounted) return;

      progress.value = WorksheetImportStage.analyze();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _showImportReviewScreen(text);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _error = formatUserFacingError(e));
      }
    } finally {
      progress.dispose();
      if (mounted) setState(() => _importingWorksheet = false);
    }
  }

  Future<void> _showImportReviewScreen(String text) async {
    if (!mounted) return;

    final result =
        await Navigator.of(context).push<WorksheetImportReviewResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorksheetImportReviewScreen(extractedText: text),
      ),
    );

    if (!mounted || result == null) return;

    switch (result.action) {
      case WorksheetImportReviewAction.cancel:
        return;
      case WorksheetImportReviewAction.instructionsOnly:
        setState(() {
          _instructionsController.text = result.instructions;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applied to instructions')),
        );
      case WorksheetImportReviewAction.importQuestions:
        final parseResult = result.parseResult;
        if (parseResult != null) {
          _applyImportedWorksheet(parseResult);
        }
    }
  }

  void _removeEmptyQuestionDrafts() {
    if (_type == ExerciseType.composeSentences) {
      _composeQuestions.removeWhere((draft) {
        final isEmpty = draft.promptController.text.trim().isEmpty &&
            draft.segmentControllers.every((c) => c.text.trim().isEmpty);
        if (isEmpty) draft.dispose();
        return isEmpty;
      });
    } else if (_usesBank(_type)) {
      _matchingQuestions.removeWhere((draft) {
        final isEmpty = draft.promptController.text.trim().isEmpty;
        if (isEmpty) draft.dispose();
        return isEmpty;
      });
    } else if (_usesTyped(_type)) {
      _typedQuestions.removeWhere((draft) {
        final isEmpty = draft.promptController.text.trim().isEmpty &&
            draft.keywordController.text.trim().isEmpty;
        if (isEmpty) draft.dispose();
        return isEmpty;
      });
    } else {
      _mcQuestions.removeWhere((draft) {
        final isEmpty = draft.promptController.text.trim().isEmpty &&
            draft.optionControllers.every((c) => c.text.trim().isEmpty);
        if (isEmpty) draft.dispose();
        return isEmpty;
      });
    }
  }

  void _applyImportedWorksheet(WorksheetParseResult result) {
    if (!result.suggestedType.isImplemented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.detectionSummary)),
      );
      return;
    }

    final importCount = result.questionCount;
    if (importCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No questions found to import.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      if (result.suggestedType != _type) {
        _clearAllQuestionDrafts();
        _type = result.suggestedType;
      } else {
        _removeEmptyQuestionDrafts();
      }

      if (result.instructions.isNotEmpty) {
        _instructionsController.text = result.instructions;
      }
      if (result.passage.isNotEmpty) {
        _passageController.text = result.passage;
      }

      if (result.suggestedLevel != null) {
        _level = result.suggestedLevel!;
      }
      _skillCategory =
          result.suggestedSkill ?? ExerciseSkillCategory.forExerciseType(_type);
      if (_titleController.text.trim().isEmpty &&
          (result.suggestedTitle ?? '').isNotEmpty) {
        _titleController.text = result.suggestedTitle!;
      }

      if (_type == ExerciseType.composeSentences) {
        for (final question in result.composeQuestions) {
          _composeQuestions.add(
            _ComposeQuestionDraft(
              prompt: question.prompt,
              segments: question.segments,
            ),
          );
        }
      } else if (_usesBank(_type)) {
        MatchingExerciseEditor.disposeOptionControllers(
            _matchingOptionControllers);
        final options = result.matchingOptions;
        _matchingOptionControllers =
            MatchingExerciseEditor.createOptionControllers(
          List.generate(
              6, (index) => index < options.length ? options[index] : ''),
        );
        for (final question in result.matchingQuestions) {
          _matchingQuestions.add(
            MatchingQuestionDraft(
              prompt: question.prompt,
              correctIndex: question.correctIndex,
            ),
          );
        }
      } else if (_usesTyped(_type)) {
        for (final question in result.mcQuestions) {
          _typedQuestions.add(
            _TypedQuestionDraft(
              prompt: question.prompt,
              keyword: question.keyword,
              answers: question.options,
            ),
          );
        }
      } else {
        for (final question in result.mcQuestions) {
          final options = question.options.length >= 4
              ? question.options
              : [
                  ...question.options,
                  for (var i = question.options.length; i < 4; i++) '',
                ];
          _mcQuestions.add(
            _McQuestionDraft(
              prompt: question.prompt,
              options: options,
              correctIndex: question.correctIndex,
            ),
          );
        }
      }
      _ensureAtLeastOneQuestion();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported $importCount item${importCount == 1 ? '' : 's'} '
          'as ${_type.label}. Review and edit before saving.',
        ),
      ),
    );
  }

  Future<void> _save({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_type.isImplemented) {
      setState(() => _error = 'This exercise type is not editable yet.');
      return;
    }

    List<ExerciseQuestion?> builtQuestions;
    List<String> matchingOptions = const [];

    if (_type == ExerciseType.composeSentences) {
      builtQuestions = _composeQuestions.map((q) => q.toQuestion()).toList();
    } else if (_usesBank(_type)) {
      builtQuestions = _matchingQuestions.map((q) => q.toQuestion()).toList();
      matchingOptions = _matchingOptionControllers
          .map((controller) => controller.text.trim())
          .toList();
      while (matchingOptions.isNotEmpty && matchingOptions.last.isEmpty) {
        matchingOptions =
            matchingOptions.sublist(0, matchingOptions.length - 1);
      }
      if (matchingOptions.length < 2) {
        setState(() => _error = _type == ExerciseType.readingCloze
            ? 'Add at least 2 words to the word bank (A–B).'
            : 'Add at least 2 options in the answer bank (A–B).');
        return;
      }
    } else if (_usesTyped(_type)) {
      builtQuestions = _typedQuestions.map((q) => q.toQuestion(_type)).toList();
    } else {
      builtQuestions = _mcQuestions.map((q) => q.toQuestion()).toList();
    }

    if (builtQuestions.any((q) => q == null)) {
      setState(() {
        _error = switch (_type) {
          ExerciseType.composeSentences =>
            'Each sentence needs at least 2 parts in the correct order.',
          ExerciseType.matching =>
            'Each prompt needs text and a correct answer letter.',
          ExerciseType.readingCloze =>
            'Each blank needs a sentence and the letter of the right word.',
          ExerciseType.typeHanzi =>
            'Each sentence needs at least one accepted hanzi answer.',
          ExerciseType.pictureSentence => 'Each item needs a keyword.',
          _ => 'Each question needs a prompt and at least 2 answer options.',
        };
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final questions = builtQuestions.cast<ExerciseQuestion>();

    try {
      final firestore = context.read<FirestoreService>();
      late final String exerciseId;
      if (widget.isEditing) {
        exerciseId = widget.exercise!.id;
        await firestore.updateExercise(
          exerciseId: exerciseId,
          title: _titleController.text,
          instructions: _instructionsController.text,
          questions: questions,
          type: _type,
          matchingOptions: matchingOptions,
          passage: _hasPassage(_type) ? _passageController.text : '',
          level: _level,
          skillCategory: _skillCategory,
          isPublished: publish,
        );
      } else {
        exerciseId = await firestore.createExercise(
          teacherId: widget.teacherId,
          title: _titleController.text,
          instructions: _instructionsController.text,
          questions: questions,
          type: _type,
          matchingOptions: matchingOptions,
          passage: _hasPassage(_type) ? _passageController.text : '',
          level: _level,
          skillCategory: _skillCategory,
          isPublished: publish,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = formatUserFacingError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _typeHint => switch (_type) {
        ExerciseType.multipleChoice =>
          'Students pick one answer from A–D options',
        ExerciseType.composeSentences =>
          'Students drag word parts into the correct sentence order',
        ExerciseType.matching =>
          'Students match each prompt to an answer letter',
        ExerciseType.listening =>
          'Students listen and choose the correct answer',
        ExerciseType.readingCloze =>
          'Students pick the word for each blank from a shared word bank (A–F)',
        ExerciseType.pictureSentence =>
          'Students write a sentence using the keyword and picture',
        ExerciseType.typeHanzi =>
          'Students type the hanzi for the pinyin shown in the sentence',
      };

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().appUser;
    // Old-format exercises (questions inside the document): admins only.
    // Teachers build packages in ExercisePackageFormScreen instead.
    if (!ExerciseAuthoringPlatform.canManageLegacyExercises(user)) {
      final message = !ExerciseAuthoringPlatform.isWeb
          ? ExerciseAuthoringPlatform.unsupportedMessage
          : ExerciseAuthoringPlatform.adminOnlyMessage;
      return ShellNestedPage(
        embedded: widget.embedded,
        title: widget.isEditing ? 'Edit exercise' : 'New exercise',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }

    final questionCount = switch (_type) {
      ExerciseType.composeSentences => _composeQuestions.length,
      ExerciseType.matching ||
      ExerciseType.readingCloze =>
        _matchingQuestions.length,
      ExerciseType.typeHanzi ||
      ExerciseType.pictureSentence =>
        _typedQuestions.length,
      _ => _mcQuestions.length,
    };
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final formBody = Form(
      key: _formKey,
      child: ListView(
        padding:
            EdgeInsets.fromLTRB(isWide ? 32 : 20, 20, isWide ? 32 : 20, 32),
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildDetailsCard(),
                      const SizedBox(height: 16),
                      _buildQuestionsCard(questionCount),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: _buildSidebar(),
                ),
              ],
            )
          else ...[
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildQuestionsCard(questionCount),
            const SizedBox(height: 16),
            _buildSidebar(),
          ],
        ],
      ),
    );

    return ShellNestedPage(
      embedded: widget.embedded,
      title: widget.isEditing ? 'Edit exercise' : 'New exercise',
      actions: [
        TextButton(
          onPressed: _saving ? null : () => _save(publish: false),
          child: const Text('Save draft'),
        ),
        FilledButton(
          onPressed: _saving ? null : () => _save(publish: true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Publish'),
        ),
      ],
      child: formBody,
    );
  }

  Widget _buildDetailsCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<ExerciseType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Exercise type'),
            items: ExerciseType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),
                )
                .toList(),
            onChanged: _onTypeChanged,
          ),
          const SizedBox(height: 6),
          Text(
            _typeHint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. HSK 2 Grammar — Unit 3',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _level,
                  decoration: const InputDecoration(labelText: 'HSK level'),
                  items: AppConstants.hskLevels
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _level = v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: HskBadge(label: _level),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExerciseSkillCategory>(
            value: _skillCategory,
            decoration: const InputDecoration(labelText: 'Skill section'),
            items: ExerciseSkillCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _skillCategory = v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _instructionsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Instructions (optional)',
              hintText: 'e.g. Circle the correct answer',
              alignLabelWithHint: true,
            ),
          ),
          if (_hasPassage(_type)) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _passageController,
              minLines: 3,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Reading passage (optional)',
                hintText: 'Shown above every question, e.g. the short text of '
                    'a reading comprehension (阅读理解)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionsCard(int questionCount) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Questions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$questionCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addFromBank,
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('From bank'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (questionCount == 0 && !_usesBank(_type))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No questions yet. Upload a worksheet (Import from worksheet) '
                'and the scanner fills this list; you can then correct any '
                'question before publishing. "From bank" adds questions that '
                'were scanned earlier.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            )
          else if (_usesBank(_type))
            MatchingExerciseEditor(
              optionControllers: _matchingOptionControllers,
              questions: _matchingQuestions,
              onAddQuestion: _addQuestion,
              onRemoveQuestion: _removeQuestion,
              onChanged: () => setState(() {}),
            )
          else if (_type == ExerciseType.composeSentences)
            ...List.generate(
              questionCount,
              (index) => _buildComposeQuestionCard(index),
            )
          else if (_usesTyped(_type))
            ...List.generate(
              questionCount,
              (index) => _buildTypedQuestionCard(index),
            )
          else
            ...List.generate(
              questionCount,
              (index) => _buildMcQuestionCard(index),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final user = context.read<AuthService>().appUser;
    if (!WorksheetImportPlatform.isSupportedFor(user)) {
      return _buildWorksheetWebOnlyCard();
    }
    return _buildWorksheetUploadCard();
  }

  Widget _buildWorksheetWebOnlyCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.laptop_mac_outlined,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Import from worksheet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            WorksheetImportPlatform.unsupportedMessage,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorksheetUploadCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.document_scanner_outlined,
                    color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Import from worksheet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Upload a PDF, Word doc, or image. OCR reads scanned pages on your '
            'device, then auto-detects question type and answers.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['PDF', 'DOCX', 'JPG', 'PNG']
                .map(
                  (format) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      format,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _importingWorksheet ? null : _importFromWorksheet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _importingWorksheet
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Choose file'),
          ),
        ],
      ),
    );
  }

  Widget _buildMcQuestionCard(int index) {
    final draft = _mcQuestions[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                if (_mcQuestions.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: draft.promptController,
              style: AppTextStyles.question,
              decoration: const InputDecoration(
                hintText: 'Question prompt',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(draft.optionControllers.length, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        String.fromCharCode(65 + optionIndex),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    Radio<int>(
                      value: optionIndex,
                      groupValue: draft.correctIndex,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => draft.correctIndex = v);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: draft.optionControllers[optionIndex],
                        style: AppTextStyles.question,
                        decoration: InputDecoration(
                          hintText:
                              'Option ${String.fromCharCode(65 + optionIndex)}',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTypedQuestionCard(int index) {
    final draft = _typedQuestions[index];
    final isPicture = _type == ExerciseType.pictureSentence;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: () => _removeQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isPicture) ...[
              TextField(
                controller: draft.keywordController,
                decoration: const InputDecoration(
                  labelText: 'Keyword the sentence must use',
                  hintText: 'e.g. 钥匙',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (draft.imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        draft.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => _pickPicture(draft),
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      draft.imageUrl.isEmpty ? 'Add picture' : 'Change picture',
                    ),
                  ),
                  if (draft.imageUrl.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => draft.imageUrl = ''),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ] else ...[
              TextField(
                controller: draft.promptController,
                style: AppTextStyles.question,
                decoration: const InputDecoration(
                  labelText: 'Sentence with （ ） where the hanzi goes',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.keywordController,
                      decoration: const InputDecoration(
                        labelText: 'Pinyin hint',
                        hintText: 'gāng',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: draft.answersController,
                      decoration: const InputDecoration(
                        labelText: 'Accepted hanzi (comma for more than one)',
                        hintText: '刚',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickPicture(_TypedQuestionDraft draft) async {
    final user = context.read<AuthService>().appUser;
    final ownerId =
        user == null ? widget.teacherId : AppConstants.contentTeacherId(user);
    try {
      final url = await context
          .read<QuestionBankMediaService>()
          .pickAndUploadImage(ownerId);
      if (!mounted) return;
      setState(() => draft.imageUrl = url);
    } on QuestionBankMediaCancelledException {
      // nothing chosen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload the picture: $e')),
      );
    }
  }

  Widget _buildComposeQuestionCard(int index) {
    final draft = _composeQuestions[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sentence ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_composeQuestions.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: draft.promptController,
              decoration: const InputDecoration(
                labelText: 'Hint (optional)',
                hintText: 'e.g. I like learning Chinese',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sentence parts in correct order (top to bottom)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Students will see these parts jumbled and must rearrange them.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(draft.segmentControllers.length, (segmentIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        '${segmentIndex + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 20),
                      onPressed: segmentIndex == 0
                          ? null
                          : () => setState(
                                () => draft.moveSegment(segmentIndex, -1),
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 20),
                      onPressed:
                          segmentIndex >= draft.segmentControllers.length - 1
                              ? null
                              : () => setState(
                                    () => draft.moveSegment(segmentIndex, 1),
                                  ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: draft.segmentControllers[segmentIndex],
                        style: AppTextStyles.question,
                        decoration: InputDecoration(
                          labelText: 'Part ${segmentIndex + 1}',
                          hintText: segmentIndex == 0 ? '我' : '喜欢',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (draft.segmentControllers.length > 2)
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => draft.removeSegment(segmentIndex),
                        ),
                      ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => draft.addSegment()),
                icon: const Icon(Icons.add),
                label: const Text('Add part'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
