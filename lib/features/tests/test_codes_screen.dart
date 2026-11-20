import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/question_bank_item.dart';
import '../../models/test_track.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/test_service.dart';
import 'test_labels.dart';
import 'test_parts_editor.dart';

/// Admin **Test codes**: every code with its worksheet, level and timing;
/// create, edit the copied timing, deactivate.
class TestCodesScreen extends StatelessWidget {
  const TestCodesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = TestService();
    return ShellNestedPage(
      embedded: embedded,
      title: l.testsCodesTitle,
      actions: [
        FilledButton.icon(
          onPressed: () => context.push('/admin/tests/codes/new'),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l.testsNewCode),
        ),
      ],
      child: StreamBuilder<List<TestCode>>(
        stream: service.watchCodes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final codes = snap.data!;
          if (codes.isEmpty) {
            return EmptyState(
              icon: Icons.qr_code_2_outlined,
              title: l.testsCodesEmptyTitle,
              subtitle: l.testsCodesEmptySubtitle,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final c in codes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => context
                        .push('/admin/tests/codes/${Uri.encodeComponent(c.id)}/edit'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.code,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: c.active
                                      ? AppColors.navy
                                      : AppColors.textSecondary,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                [
                                  c.level,
                                  if (c.releaseYear != null) '${c.releaseYear}',
                                  c.sheetKey,
                                  l.testsMinutesTotal(c.totalMinutes),
                                ].join(' · '),
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (!c.active)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              l.testsInactive,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Switch(
                          value: c.active,
                          onChanged: (v) => service.setCodeActive(c.id, v),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// ViewModel of the test code form: the chosen worksheet and format, the
/// copied timing, and the check of question counts per part.
class TestCodeFormViewModel extends ChangeNotifier {
  TestCodeFormViewModel({
    required this.service,
    required this.firestore,
    required this.bankOwnerId,
    this.editId,
    String? initialSheet,
  }) : sheetKey = initialSheet {
    _bankSub = firestore.watchQuestionBank(bankOwnerId).listen((items) {
      sheets = QuestionBankSheet.group(items).where((s) => s.isSheet).toList();
      _ready();
    });
    _formatSub = service.watchFormats().listen((list) {
      formats = list;
      _ready();
    });
    if (editId != null) {
      _codeSub = service.watchCodes().listen((codes) {
        if (_editLoaded) return;
        final c = codes.where((c) => c.id == editId).firstOrNull;
        if (c == null) return;
        _editLoaded = true;
        code = c.code;
        sheetKey = c.sheetKey;
        family = c.family;
        level = c.level;
        levelKey = c.levelKey;
        formatId = c.formatId;
        parts = c.parts;
        passMark = c.passMark;
        releaseYear = c.releaseYear;
        active = c.active;
        countsForPromotion = c.countsForPromotion;
        placement = c.placement;
        partsVersion++;
        _ready();
      });
    }
  }

  final TestService service;
  final FirestoreService firestore;
  final String bankOwnerId;
  final String? editId;

  late final StreamSubscription<List<QuestionBankItem>> _bankSub;
  late final StreamSubscription<List<TestFormat>> _formatSub;
  StreamSubscription<List<TestCode>>? _codeSub;
  bool _editLoaded = false;

  bool get isEditing => editId != null;
  bool loading = true;
  bool saving = false;

  List<QuestionBankSheet> sheets = const [];
  List<TestFormat> formats = const [];

  String code = '';
  String? sheetKey;
  String formatId = '';
  TestFamily family = TestFamily.hsk;
  String level = '';
  String levelKey = '';
  List<TestPart> parts = const [];
  int passMark = 0;
  int? releaseYear;
  bool active = true;
  bool countsForPromotion = true;

  /// Build 3: a placement code (visitors may sit it; never counts).
  bool placement = false;

  /// Bumped when [parts] is replaced from outside the editor (format
  /// chosen, code loaded) so the editor rebuilds with the new values.
  int partsVersion = 0;

  void _ready() {
    loading = formats.isEmpty && sheets.isEmpty;
    loading = false;
    notifyListeners();
  }

  QuestionBankSheet? get sheet =>
      sheets.where((s) => s.key == sheetKey).firstOrNull;

  List<int>? get found {
    final s = sheet;
    if (s == null || parts.isEmpty) return null;
    return TestService.partCounts(s.items, parts).map((c) => c.found).toList();
  }

  void pickSheet(String? key) {
    sheetKey = key;
    notifyListeners();
  }

  /// Picking a format copies its parts and pass mark into the code.
  void pickFormat(String? id) {
    final f = formats.where((f) => f.id == id).firstOrNull;
    if (f == null) return;
    formatId = f.id;
    family = f.family;
    level = f.level;
    levelKey = f.levelKey;
    parts = f.parts;
    passMark = f.passMark;
    partsVersion++;
    notifyListeners();
  }

  void setParts(List<TestPart> p, int pass) {
    parts = p;
    passMark = pass;
    notifyListeners();
  }

  void setCode(String v) {
    code = v;
    notifyListeners();
  }

  void setYear(String v) {
    releaseYear = int.tryParse(v);
  }

  void setActive(bool v) {
    active = v;
    notifyListeners();
  }

  void setCountsForPromotion(bool v) {
    countsForPromotion = v;
    notifyListeners();
  }

  void setPlacement(bool v) {
    placement = v;
    if (v) countsForPromotion = false;
    notifyListeners();
  }

  bool get canSave =>
      !saving &&
      TestCode.normalize(code).isNotEmpty &&
      (sheetKey ?? '').isNotEmpty &&
      parts.isNotEmpty;

  TestCode _build() => TestCode(
        id: editId ?? TestCode.normalize(code),
        code: TestCode.normalize(code),
        family: family,
        level: level,
        levelKey: levelKey,
        sheetKey: sheetKey ?? '',
        formatId: formatId,
        parts: parts,
        passMark: passMark,
        releaseYear: releaseYear,
        active: active,
        countsForPromotion: placement ? false : countsForPromotion,
        placement: placement,
      );

  Future<void> save(String createdBy) async {
    saving = true;
    notifyListeners();
    try {
      if (isEditing) {
        await service.updateCode(_build());
      } else {
        await service.createCode(_build(), createdBy: createdBy);
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _bankSub.cancel();
    _formatSub.cancel();
    _codeSub?.cancel();
    super.dispose();
  }
}

/// Create a test code from a bank worksheet (or edit one: timing, marks,
/// year, flags; the worksheet and the code itself never change).
class TestCodeFormScreen extends StatelessWidget {
  const TestCodeFormScreen({
    super.key,
    this.editId,
    this.initialSheet,
    this.embedded = false,
  });

  final String? editId;
  final String? initialSheet;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().appUser!;
    return ChangeNotifierProvider(
      create: (_) => TestCodeFormViewModel(
        service: TestService(),
        firestore: context.read<FirestoreService>(),
        bankOwnerId: AppConstants.contentTeacherId(user),
        editId: editId,
        initialSheet: initialSheet,
      ),
      child: _TestCodeForm(embedded: embedded),
    );
  }
}

class _TestCodeForm extends StatelessWidget {
  const _TestCodeForm({required this.embedded});

  final bool embedded;

  Future<void> _save(BuildContext context) async {
    final vm = context.read<TestCodeFormViewModel>();
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final uid = context.read<AuthService>().appUser!.uid;
    try {
      await vm.save(uid);
      messenger.showSnackBar(SnackBar(content: Text(l.testsCodeSaved)));
      if (context.mounted) context.pop();
    } on DuplicateTestCodeException {
      messenger.showSnackBar(SnackBar(
        content: Text(l.testsCodeDuplicate(TestCode.normalize(vm.code))),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TestCodeFormViewModel>();
    if (vm.loading) {
      return ShellNestedPage(
        embedded: embedded,
        title: l.testsNewCode,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final found = vm.found;
    final mismatches = found == null
        ? 0
        : [
            for (var i = 0; i < vm.parts.length && i < found.length; i++)
              if (found[i] != vm.parts[i].questions) i,
          ].length;
    return ShellNestedPage(
      embedded: embedded,
      title: vm.isEditing ? l.testsEditCode : l.testsNewCode,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: vm.sheet == null ? null : vm.sheetKey,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.testsWorksheet,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in vm.sheets)
                      DropdownMenuItem(
                        value: s.key,
                        child: Text(
                          '${s.key} · ${s.title} (${s.count})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: vm.isEditing ? null : vm.pickSheet,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: ValueKey('code-${vm.isEditing}-${vm.partsVersion > 0}'),
                  initialValue: vm.code,
                  enabled: !vm.isEditing,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                  ],
                  decoration: InputDecoration(
                    labelText: l.testsCode,
                    helperText: l.testsCodeHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: vm.setCode,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<String>(
                        initialValue: vm.formats.any((f) => f.id == vm.formatId)
                            ? vm.formatId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l.testsFormat,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final f in vm.formats)
                            DropdownMenuItem(
                              value: f.id,
                              child: Text(f.provisional
                                  ? '${f.level} (${l.testsDraft})'
                                  : f.level),
                            ),
                        ],
                        onChanged: vm.isEditing ? null : vm.pickFormat,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        key: ValueKey('year-${vm.partsVersion}'),
                        initialValue: vm.releaseYear?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: l.testsReleaseYear,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: vm.setYear,
                      ),
                    ),
                  ],
                ),
                if (vm.formats.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.testsNoFormatsYet,
                    style: TextStyle(color: AppColors.chipAmberFg),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (vm.parts.isNotEmpty)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.testsTimingTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.testsTimingHint,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TestPartsEditor(
                    key: ValueKey('parts-${vm.partsVersion}'),
                    parts: vm.parts,
                    passMark: vm.passMark,
                    found: found,
                    onChanged: vm.setParts,
                  ),
                  if (mismatches > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.chipAmberFg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.testsCountWarning,
                            style: TextStyle(color: AppColors.chipAmberFg),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: vm.active,
                  onChanged: vm.setActive,
                  title: Text(l.testsActive),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: vm.countsForPromotion && !vm.placement,
                  onChanged: vm.placement ? null : vm.setCountsForPromotion,
                  title: Text(l.testsCountsForPromotion),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: vm.placement,
                  onChanged: vm.setPlacement,
                  title: Text(l.placementCodeTick),
                  subtitle: Text(l.placementCodeTickHelp),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: vm.canSave ? () => _save(context) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.save_outlined),
            label: Text(vm.isEditing ? l.testsSave : l.testsCreateCode),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Skill names of the parts a worksheet's questions fall into, for the
/// worksheet screen's summary.
String partsSummary(AppLocalizations l, List<TestPart> parts) =>
    parts.map((p) => p.skill.localized(l)).join(' · ');
