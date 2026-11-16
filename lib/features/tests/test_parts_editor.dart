import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../models/test_track.dart';
import 'test_labels.dart';

/// Edits the parts of a format or a test code: skill, questions, minutes and
/// marks per part, plus the pass mark. Reports every change with
/// [onChanged]; parts can be added and removed (HSK 3.0 drafts).
class TestPartsEditor extends StatefulWidget {
  const TestPartsEditor({
    super.key,
    required this.parts,
    required this.passMark,
    required this.onChanged,
    this.found,
  });

  final List<TestPart> parts;
  final int passMark;
  final void Function(List<TestPart> parts, int passMark) onChanged;

  /// Questions the worksheet has per part (test code form); a difference
  /// from the expected count is shown as a warning, not a block.
  final List<int>? found;

  @override
  State<TestPartsEditor> createState() => _TestPartsEditorState();
}

class _TestPartsEditorState extends State<TestPartsEditor> {
  late List<TestPart> _parts = List.of(widget.parts);
  late final _pass = TextEditingController(text: '${widget.passMark}');

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  void _emit() =>
      widget.onChanged(List.unmodifiable(_parts), int.tryParse(_pass.text) ?? 0);

  void _set(int i, TestPart p) {
    setState(() => _parts[i] = p);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final maxTotal = _parts.fold<int>(0, (n, p) => n + p.maxScore);
    final minutes = _parts.fold<int>(0, (n, p) => n + p.minutes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _parts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PartRow(
              key: ValueKey('part$i-${_parts.length}'),
              index: i,
              part: _parts[i],
              found: widget.found != null && i < widget.found!.length
                  ? widget.found![i]
                  : null,
              onChanged: (p) => _set(i, p),
              onRemove: _parts.length > 1
                  ? () {
                      setState(() => _parts = List.of(_parts)..removeAt(i));
                      _emit();
                    }
                  : null,
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() => _parts = [
                    ..._parts,
                    const TestPart(
                      skill: TestSkill.reading,
                      questions: 10,
                      minutes: 10,
                      maxScore: 100,
                    ),
                  ]);
              _emit();
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.testsAddPart),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 140,
              child: TextField(
                controller: _pass,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l.testsPassMark,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _emit(),
              ),
            ),
            Text(
              l.testsTotalsLine(maxTotal, minutes),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({
    super.key,
    required this.index,
    required this.part,
    required this.onChanged,
    this.found,
    this.onRemove,
  });

  final int index;
  final TestPart part;
  final int? found;
  final ValueChanged<TestPart> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget number(String label, int value, ValueChanged<int> set) => SizedBox(
          width: 96,
          child: TextFormField(
            initialValue: '$value',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => set(int.tryParse(v) ?? 0),
          ),
        );
    final mismatch = found != null && found != part.questions;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mismatch ? AppColors.chipAmberFg : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l.testsPartNumber(index + 1),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              DropdownButton<TestSkill>(
                value: part.skill,
                isDense: true,
                items: [
                  for (final s in TestSkill.values)
                    DropdownMenuItem(value: s, child: Text(s.localized(l))),
                ],
                onChanged: (s) {
                  if (s != null) onChanged(part.copyWith(skill: s));
                },
              ),
              number(l.testsQuestions, part.questions,
                  (v) => onChanged(part.copyWith(questions: v))),
              number(l.testsMinutes, part.minutes,
                  (v) => onChanged(part.copyWith(minutes: v))),
              number(l.testsMaxMark, part.maxScore,
                  (v) => onChanged(part.copyWith(maxScore: v))),
              if (onRemove != null)
                IconButton(
                  tooltip: l.testsRemovePart,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          if (found != null) ...[
            const SizedBox(height: 6),
            Text(
              mismatch
                  ? l.testsFoundMismatch(part.questions, found!)
                  : l.testsFoundMatch(found!),
              style: TextStyle(
                fontSize: 12,
                color: mismatch ? AppColors.chipAmberFg : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
