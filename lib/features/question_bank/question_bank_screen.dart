import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_data_table.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/exercise.dart';
import '../../models/exercise_skill_category.dart';
import '../../models/exercise_type.dart';
import '../../models/question_bank_item.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/question_bank_media_service.dart';
import 'question_bank_bulk_import.dart';
import 'question_bank_harvest.dart';
import 'question_bank_sheet_screen.dart';
import 'question_bank_text.dart';

/// Admin/teacher screen for the shared question bank (`question_bank`
/// collection). A scanned worksheet is one row (open it to see and edit its
/// questions); a question typed or pasted on its own is a row by itself.
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  ExerciseType? _typeFilter;
  String? _levelFilter;
  String _search = '';
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

  /// A worksheet matches when its type and level match and the search text
  /// is in its code, title, tags or any of its questions.
  bool _matchesFilters(QuestionBankSheet sheet) {
    if (_typeFilter != null && sheet.type != _typeFilter) return false;
    if (_levelFilter != null && sheet.level != _levelFilter) return false;
    if (_search.isNotEmpty) {
      final needle = _search.toLowerCase();
      final hay = [
        sheet.code,
        sheet.title,
        ...sheet.tags,
        for (final item in sheet.items) item.displayText,
      ].join(' ').toLowerCase();
      if (!hay.contains(needle)) return false;
    }
    return true;
  }

  List<QuestionBankSheet> _sorted(List<QuestionBankSheet> sheets) {
    final col = _sortColumnId;
    if (col == null) return sheets;
    final sorted = [...sheets];
    sorted.sort((a, b) {
      final cmp = switch (col) {
        'title' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        'type' => a.type.label.compareTo(b.type.label),
        'level' => (a.level ?? '').compareTo(b.level ?? ''),
        'count' => a.count.compareTo(b.count),
        'used' => a.usageCount.compareTo(b.usageCount),
        _ => 0,
      };
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final user = context.watch<AuthService>().appUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ownerId = AppConstants.contentTeacherId(user);

    return ShellNestedPage(
      embedded: widget.embedded,
      title: 'Question bank',
      actions: [
        TextButton.icon(
          onPressed: () => _openEditor(ownerId: ownerId),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Type a question'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) async {
            switch (action) {
              case 'samples':
                final all = await firestore.watchQuestionBank(ownerId).first;
                if (!context.mounted) return;
                await runQuestionBankSampleSetImport(
                  context,
                  ownerId: ownerId,
                  existingBank: all,
                );
              case 'paste':
                await showQuestionBankPasteImport(context, ownerId: ownerId);
              case 'harvest':
                final all = await firestore.watchQuestionBank(ownerId).first;
                if (!context.mounted) return;
                await showQuestionBankHarvestFromExercises(
                  context,
                  ownerId: ownerId,
                  existingBank: all,
                );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'samples',
              child: Text("Load the centre's sample sheets (10 worksheets)"),
            ),
            PopupMenuItem(value: 'paste', child: Text('Bulk import — paste')),
            PopupMenuItem(
              value: 'harvest',
              child: Text('Import from exercises'),
            ),
          ],
        ),
      ],
      // Scanner first: upload a worksheet, the app detects each question's
      // type and answer, and the admin checks the list before it is added.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => runQuestionBankWorksheetImport(
          context,
          ownerId: ownerId,
        ),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.document_scanner_outlined),
        label: const Text('Scan worksheet'),
      ),
      child: StreamBuilder<List<QuestionBankItem>>(
        stream: firestore.watchQuestionBank(ownerId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? const <QuestionBankItem>[];
          final sheets = QuestionBankSheet.group(all);
          final rows = _sorted(sheets.where(_matchesFilters).toList());

          return Column(
            children: [
              _Filters(
                typeFilter: _typeFilter,
                levelFilter: _levelFilter,
                onType: (t) => setState(() => _typeFilter = t),
                onLevel: (l) => setState(() => _levelFilter = l),
                onSearch: (s) => setState(() => _search = s),
              ),
              Expanded(
                child: all.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No worksheets yet',
                        subtitle:
                            'Scan a worksheet to add it whole, or type a single '
                            'question. Exercises pull from here.',
                      )
                    : rows.isEmpty
                        ? const EmptyState(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'No matches',
                            subtitle: 'Adjust the filters.',
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                            child: SingleChildScrollView(
                              child: AppDataTable<QuestionBankSheet>(
                                rows: rows,
                                sortColumnId: _sortColumnId,
                                sortAscending: _sortAscending,
                                onSort: _onSort,
                                onRowTap: (sheet) => _open(ownerId, sheet),
                                columns: _buildColumns(firestore),
                                mobileCardBuilder: (sheet) => _SheetCard(
                                  sheet: sheet,
                                  onTap: () => _open(ownerId, sheet),
                                  onDelete: () => _delete(firestore, sheet),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppTableColumn<QuestionBankSheet>> _buildColumns(
    FirestoreService firestore,
  ) {
    return [
      AppTableColumn(
        id: 'title',
        label: 'Worksheet / question',
        flex: 3,
        sortable: true,
        cell: (sheet) => _TitleCell(sheet: sheet),
      ),
      AppTableColumn(
        id: 'type',
        label: 'Type',
        width: 130,
        sortable: true,
        cell: (sheet) => Text(sheet.type.label),
      ),
      AppTableColumn(
        id: 'level',
        label: 'Level',
        width: 70,
        sortable: true,
        cell: (sheet) => Text(sheet.level ?? '—'),
      ),
      AppTableColumn(
        id: 'count',
        label: 'Questions',
        width: 96,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (sheet) => Text('${sheet.count}'),
      ),
      AppTableColumn(
        id: 'tags',
        label: 'Tags',
        flex: 2,
        cell: (sheet) => Text(
          sheet.tags.map((t) => '#$t').join(' '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
      AppTableColumn(
        id: 'used',
        label: 'Used',
        width: 56,
        sortable: true,
        alignment: Alignment.centerRight,
        cell: (sheet) => Text('${sheet.usageCount}'),
      ),
      AppTableColumn(
        id: 'actions',
        label: '',
        width: 48,
        cell: (sheet) => IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => _delete(firestore, sheet),
          tooltip: sheet.isSheet ? 'Delete worksheet' : 'Delete',
        ),
      ),
    ];
  }

  void _open(String ownerId, QuestionBankSheet sheet) {
    if (sheet.isSheet) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuestionBankSheetScreen(
            ownerId: ownerId,
            sheetKey: sheet.key!,
          ),
        ),
      );
    } else {
      _openEditor(ownerId: ownerId, existing: sheet.first);
    }
  }

  Future<void> _delete(
      FirestoreService firestore, QuestionBankSheet sheet) async {
    if (!sheet.isSheet) {
      await firestore.deleteQuestionBankItem(sheet.first.id);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete worksheet ${sheet.code}?'),
        content: Text(
          'All ${QuestionBankText.questionCount(sheet.count)} leave the bank. '
          'Exercises that already use them keep their copies.',
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
    if (ok == true) {
      await firestore.deleteQuestionBankItems(sheet.items.map((i) => i.id));
    }
  }

  Future<void> _openEditor({
    required String ownerId,
    QuestionBankItem? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuestionBankEditorSheet(
        ownerId: ownerId,
        existing: existing,
      ),
    );
  }
}

/// First column: the sheet title with its code underneath, or the single
/// question's text in the question face.
class _TitleCell extends StatelessWidget {
  const _TitleCell({required this.sheet});
  final QuestionBankSheet sheet;

  @override
  Widget build(BuildContext context) {
    if (!sheet.isSheet) {
      return Text(
        sheet.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.question.copyWith(fontSize: 17),
      );
    }
    return Row(
      children: [
        const Icon(Icons.description_outlined, size: 20, color: AppColors.navy),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.question.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              if (sheet.title != sheet.code)
                Text(
                  sheet.code,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.typeFilter,
    required this.levelFilter,
    required this.onType,
    required this.onLevel,
    required this.onSearch,
  });

  final ExerciseType? typeFilter;
  final String? levelFilter;
  final ValueChanged<ExerciseType?> onType;
  final ValueChanged<String?> onLevel;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search worksheet, question or tag',
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<ExerciseType?>(
              initialValue: typeFilter,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Type', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final t in ExerciseType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: onType,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String?>(
              initialValue: levelFilter,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Level', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final l in AppConstants.hskLevels)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: onLevel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.sheet,
    required this.onTap,
    required this.onDelete,
  });

  final QuestionBankSheet sheet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheet.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.question.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (sheet.isSheet) _Chip(label: sheet.code),
                    _Chip(label: sheet.type.label),
                    if (sheet.level != null && sheet.level!.isNotEmpty)
                      _Chip(label: sheet.level!),
                    if (sheet.isSheet)
                      _Chip(label: QuestionBankText.questionCount(sheet.count)),
                    if (sheet.usageCount > 0)
                      _Chip(label: 'Used ${sheet.usageCount}'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.navy)),
    );
  }
}

/// Create/edit a single bank question.
class QuestionBankEditorSheet extends StatefulWidget {
  const QuestionBankEditorSheet({
    super.key,
    required this.ownerId,
    this.existing,
  });

  final String ownerId;
  final QuestionBankItem? existing;

  @override
  State<QuestionBankEditorSheet> createState() =>
      _QuestionBankEditorSheetState();
}

class _QuestionBankEditorSheetState extends State<QuestionBankEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  final _segmentsController = TextEditingController();

  ExerciseType _type = ExerciseType.multipleChoice;
  ExerciseSkillCategory _skill = ExerciseSkillCategory.reading;
  String _level = AppConstants.hskLevels.first;
  int _correctIndex = 0;
  String _imageUrl = '';
  String _audioUrl = '';
  bool _saving = false;
  bool _uploadingMedia = false;

  bool get _isEditing => widget.existing != null;
  bool get _isChoice =>
      _type == ExerciseType.multipleChoice || _type == ExerciseType.listening;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _skill = e.skillCategory ?? ExerciseSkillCategory.forExerciseType(e.type);
      _level = e.level ?? AppConstants.hskLevels.first;
      _tagsController.text = e.tags.join(', ');
      _promptController.text = e.question.prompt;
      _correctIndex = e.question.correctIndex;
      _imageUrl = e.question.imageUrl;
      _audioUrl = e.question.audioUrl;
      for (var i = 0; i < e.question.options.length && i < 4; i++) {
        _optionControllers[i].text = e.question.options[i];
      }
      if (e.question.segments.isNotEmpty) {
        _segmentsController.text = e.question.segments.join('\n');
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _tagsController.dispose();
    _segmentsController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  ExerciseQuestion _buildQuestion() {
    final prompt = _promptController.text.trim();
    if (_type == ExerciseType.composeSentences) {
      final segments = _segmentsController.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      return ExerciseQuestion(
        prompt: prompt,
        segments: segments,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
      );
    }
    if (_type == ExerciseType.matching) {
      return ExerciseQuestion(
        prompt: prompt,
        correctIndex: _correctIndex,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
      );
    }
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    return ExerciseQuestion(
      prompt: prompt,
      options: options,
      correctIndex: _correctIndex.clamp(0, options.length - 1),
      imageUrl: _imageUrl,
      audioUrl: _audioUrl,
    );
  }

  Future<void> _uploadMedia({required bool image}) async {
    setState(() => _uploadingMedia = true);
    try {
      final service = context.read<QuestionBankMediaService>();
      final url = image
          ? await service.pickAndUploadImage(widget.ownerId)
          : await service.pickAndUploadAudio(widget.ownerId);
      setState(() {
        if (image) {
          _imageUrl = url;
        } else {
          _audioUrl = url;
        }
      });
    } on QuestionBankMediaCancelledException {
      // user cancelled
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final question = _buildQuestion();
    if (question.prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a prompt.')),
      );
      return;
    }
    setState(() => _saving = true);

    final firestore = context.read<FirestoreService>();
    final navigator = Navigator.of(context);
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final item = QuestionBankItem(
      id: widget.existing?.id ?? '',
      ownerId: widget.ownerId,
      type: _type,
      question: question,
      skillCategory: _skill,
      level: _level,
      tags: tags,
      sheetCode: widget.existing?.sheetCode,
      sheetTitle: widget.existing?.sheetTitle,
      sheetIndex: widget.existing?.sheetIndex,
      usageCount: widget.existing?.usageCount ?? 0,
      lastUsedAt: widget.existing?.lastUsedAt,
      sourceExerciseId: widget.existing?.sourceExerciseId,
    );

    try {
      if (_isEditing) {
        await firestore.updateQuestionBankItem(item);
      } else {
        await firestore.createQuestionBankItem(item);
      }
      navigator.pop();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 20, bottom: 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit question' : 'New question',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExerciseType>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in ExerciseType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (t) => setState(() {
                  _type = t ?? ExerciseType.multipleChoice;
                  _skill = ExerciseSkillCategory.forExerciseType(_type);
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _promptController,
                style: AppTextStyles.question,
                decoration: const InputDecoration(labelText: 'Prompt'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a prompt' : null,
              ),
              const SizedBox(height: 12),
              if (_isChoice) ..._buildChoiceFields(),
              if (_type == ExerciseType.composeSentences)
                TextFormField(
                  controller: _segmentsController,
                  style: AppTextStyles.question,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Segments (one per line)',
                  ),
                ),
              const SizedBox(height: 12),
              _MediaRow(
                imageUrl: _imageUrl,
                audioUrl: _audioUrl,
                uploading: _uploadingMedia,
                onUploadImage: () => _uploadMedia(image: true),
                onUploadAudio: () => _uploadMedia(image: false),
                onClearImage: () => setState(() => _imageUrl = ''),
                onClearAudio: () => setState(() => _audioUrl = ''),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _level,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Level'),
                      items: [
                        for (final l in AppConstants.hskLevels)
                          DropdownMenuItem(value: l, child: Text(l)),
                      ],
                      onChanged: (l) => setState(
                          () => _level = l ?? AppConstants.hskLevels.first),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ExerciseSkillCategory>(
                      initialValue: _skill,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Skill'),
                      items: [
                        for (final c in ExerciseSkillCategory.values)
                          DropdownMenuItem(value: c, child: Text(c.label)),
                      ],
                      onChanged: (c) => setState(
                          () => _skill = c ?? ExerciseSkillCategory.reading),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                ),
              ),
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
                      : Text(_isEditing ? 'Save' : 'Add to bank'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChoiceFields() {
    return [
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Radio<int>(
                value: i,
                groupValue: _correctIndex,
                onChanged: (v) => setState(() => _correctIndex = v ?? 0),
              ),
              Expanded(
                child: TextFormField(
                  controller: _optionControllers[i],
                  style: AppTextStyles.question,
                  decoration: InputDecoration(
                    labelText: 'Option ${String.fromCharCode(65 + i)}',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.imageUrl,
    required this.audioUrl,
    required this.uploading,
    required this.onUploadImage,
    required this.onUploadAudio,
    required this.onClearImage,
    required this.onClearAudio,
  });

  final String imageUrl;
  final String audioUrl;
  final bool uploading;
  final VoidCallback onUploadImage;
  final VoidCallback onUploadAudio;
  final VoidCallback onClearImage;
  final VoidCallback onClearAudio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Media (optional)',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: uploading ? null : onUploadImage,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(imageUrl.isEmpty ? 'Add image' : 'Image attached'),
            ),
            if (imageUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClearImage,
              ),
            OutlinedButton.icon(
              onPressed: uploading ? null : onUploadAudio,
              icon: const Icon(Icons.audiotrack_outlined, size: 18),
              label: Text(audioUrl.isEmpty ? 'Add audio' : 'Audio attached'),
            ),
            if (audioUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClearAudio,
              ),
          ],
        ),
        if (imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.network(imageUrl, height: 80, fit: BoxFit.contain),
          ),
      ],
    );
  }
}

/// Multi-select picker; bumps usageCount on confirm.
Future<List<QuestionBankItem>?> showQuestionBankPicker(
  BuildContext context, {
  required String ownerId,
  required ExerciseType type,
}) {
  return showModalBottomSheet<List<QuestionBankItem>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _QuestionBankPicker(ownerId: ownerId, type: type),
  );
}

class _QuestionBankPicker extends StatefulWidget {
  const _QuestionBankPicker({required this.ownerId, required this.type});

  final String ownerId;
  final ExerciseType type;

  @override
  State<_QuestionBankPicker> createState() => _QuestionBankPickerState();
}

class _QuestionBankPickerState extends State<_QuestionBankPicker> {
  final Set<String> _selected = {};
  String _filter = '';

  Future<void> _confirm(List<QuestionBankItem> items) async {
    final picked = items.where((i) => _selected.contains(i.id)).toList();
    if (picked.isEmpty) return;
    await context.read<FirestoreService>().incrementQuestionBankUsage(
          picked.map((p) => p.id),
        );
    if (!mounted) return;
    Navigator.of(context).pop(picked);
  }

  void _toggle(Iterable<QuestionBankItem> items, bool on) => setState(() {
        for (final item in items) {
          on ? _selected.add(item.id) : _selected.remove(item.id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return StreamBuilder<List<QuestionBankItem>>(
          stream: firestore.watchQuestionBank(widget.ownerId),
          builder: (context, snap) {
            final all = (snap.data ?? const <QuestionBankItem>[])
                .where((i) => i.type == widget.type)
                .toList();
            final needle = _filter.toLowerCase();
            // One block per worksheet (tick the header to take the whole
            // sheet), stand-alone questions after them.
            final sheets = QuestionBankSheet.group(all).where((sheet) {
              if (needle.isEmpty) return true;
              return [
                sheet.code,
                sheet.title,
                for (final i in sheet.items) i.displayText,
              ].join(' ').toLowerCase().contains(needle);
            }).toList()
              ..sort(
                  (a, b) => a.isSheet == b.isSheet ? 0 : (a.isSheet ? -1 : 1));
            final items = [for (final s in sheets) ...s.items];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add from bank — ${widget.type.label}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _selected.isEmpty
                                ? null
                                : () => _confirm(items),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.navy,
                            ),
                            child: Text('Add (${_selected.length})'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Filter worksheets and questions…',
                          isDense: true,
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        onChanged: (v) => setState(() => _filter = v),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              items.isEmpty ? null : () => _toggle(items, true),
                          child: Text('Select all (${items.length} filtered)'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No matching bank questions',
                          subtitle:
                              'Add questions of this type to the bank first.',
                        )
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          children: [
                            for (final sheet in sheets) ...[
                              if (sheet.isSheet) _sheetHeader(sheet),
                              for (final item in sheet.items)
                                _questionTile(item, indented: sheet.isSheet),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Ticking the worksheet ticks every question on it.
  Widget _sheetHeader(QuestionBankSheet sheet) {
    final picked = sheet.items.where((i) => _selected.contains(i.id)).length;
    final all = picked == sheet.count;
    return CheckboxListTile(
      value: all ? true : (picked == 0 ? false : null),
      tristate: true,
      controlAffinity: ListTileControlAffinity.leading,
      tileColor: AppColors.navy.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      secondary: const Icon(Icons.description_outlined, color: AppColors.navy),
      title: Text(
        sheet.title,
        style:
            const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
      ),
      subtitle: Text(
        '${sheet.code} · ${QuestionBankText.questionCount(sheet.count)}'
        '${sheet.level != null ? ' · ${sheet.level}' : ''}',
      ),
      onChanged: (_) => _toggle(sheet.items, !all),
    );
  }

  Widget _questionTile(QuestionBankItem item, {required bool indented}) {
    return CheckboxListTile(
      value: _selected.contains(item.id),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.only(left: indented ? 36 : 16, right: 16),
      title: Text(
        item.displayText.isEmpty ? '(no prompt)' : item.displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.question.copyWith(fontSize: 17),
      ),
      subtitle: Text(
        [
          if (!indented && item.level != null) item.level!,
          if (item.question.imageUrl.isNotEmpty) '🖼',
          if (item.question.audioUrl.isNotEmpty) '🔊',
          QuestionBankText.answerLine(item),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.questionDetail.copyWith(fontSize: 13),
      ),
      onChanged: (v) => _toggle([item], v == true),
    );
  }
}
