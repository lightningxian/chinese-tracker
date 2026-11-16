import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/test_track.dart';
import '../../services/test_service.dart';
import 'test_labels.dart';
import 'test_parts_editor.dart';

/// ViewModel of the admin **Test formats** screen.
class TestFormatsViewModel extends ChangeNotifier {
  TestFormatsViewModel(this._service) {
    _sub = _service.watchFormats().listen((list) {
      formats = list;
      loading = false;
      notifyListeners();
    }, onError: (Object e) {
      error = '$e';
      loading = false;
      notifyListeners();
    });
  }

  final TestService _service;
  late final StreamSubscription<List<TestFormat>> _sub;

  List<TestFormat> formats = const [];
  bool loading = true;
  bool busy = false;
  String? error;

  /// Adds the missing standard formats; returns how many were added.
  Future<int> loadStandard() async {
    busy = true;
    notifyListeners();
    try {
      return await _service.loadStandardFormats();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> save(TestFormat format) => _service.saveFormat(format);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class TestFormatsScreen extends StatelessWidget {
  const TestFormatsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestFormatsViewModel(TestService()),
      child: _TestFormatsView(embedded: embedded),
    );
  }
}

class _TestFormatsView extends StatelessWidget {
  const _TestFormatsView({required this.embedded});

  final bool embedded;

  Future<void> _loadStandard(BuildContext context) async {
    final vm = context.read<TestFormatsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      final added = await vm.loadStandard();
      messenger.showSnackBar(SnackBar(
        content: Text(added == 0
            ? l.testsFormatsNothingAdded
            : l.testsFormatsAdded(added)),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TestFormatsViewModel>();
    return ShellNestedPage(
      embedded: embedded,
      title: l.testsFormatsTitle,
      actions: [
        FilledButton.icon(
          onPressed: vm.busy ? null : () => _loadStandard(context),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(l.testsLoadStandardFormats),
        ),
      ],
      child: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.formats.isEmpty
              ? EmptyState(
                  icon: Icons.rule_folder_outlined,
                  title: l.testsFormatsEmptyTitle,
                  subtitle: l.testsFormatsEmptySubtitle,
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final f in vm.formats)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FormatTile(format: f),
                      ),
                  ],
                ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({required this.format});

  final TestFormat format;

  Future<void> _edit(BuildContext context) async {
    final vm = context.read<TestFormatsViewModel>();
    final edited = await showDialog<TestFormat>(
      context: context,
      builder: (_) => _FormatDialog(format: format),
    );
    if (edited == null) return;
    await vm.save(edited);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parts = format.parts
        .map((p) => '${p.skill.localized(l)} ${p.questions} · ${p.minutes}′')
        .join('   ');
    return AppCard(
      onTap: () => _edit(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      format.level,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      chineseExamType(format.family, format.levelKey),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    if (format.provisional)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.chipAmberBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.testsDraft,
                          style: TextStyle(
                            color: AppColors.chipAmberFg,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(parts, style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  l.testsMaxPassLine(format.maxTotal, format.passMark),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _FormatDialog extends StatefulWidget {
  const _FormatDialog({required this.format});

  final TestFormat format;

  @override
  State<_FormatDialog> createState() => _FormatDialogState();
}

class _FormatDialogState extends State<_FormatDialog> {
  late List<TestPart> _parts = widget.format.parts;
  late int _passMark = widget.format.passMark;
  late bool _provisional = widget.format.provisional;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.format.level),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TestPartsEditor(
                parts: _parts,
                passMark: _passMark,
                onChanged: (parts, pass) {
                  _parts = parts;
                  _passMark = pass;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _provisional,
                onChanged: (v) => setState(() => _provisional = v),
                title: Text(l.testsDraftSwitch),
                subtitle: Text(l.testsDraftSwitchHint),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(widget.format.copyWith(
            parts: _parts,
            passMark: _passMark,
            provisional: _provisional,
          )),
          child: Text(l.testsSave),
        ),
      ],
    );
  }
}
