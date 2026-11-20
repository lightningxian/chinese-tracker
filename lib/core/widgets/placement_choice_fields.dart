import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../features/tests/test_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/placement.dart';
import '../../services/placement_service.dart';
import '../theme/app_theme.dart';

/// Build 3 (Must 1): where a new student starts. "Mulai dari HSK 1", or
/// "Ikut tes penempatan" with a target level HSK 2-6, plus an optional
/// result code of a public placement test, checked live before the form is
/// sent. The parent form reads [value] and [RegistrationChoice.issue].
class PlacementChoiceFields extends StatefulWidget {
  const PlacementChoiceFields({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.service,
  });

  final RegistrationChoice value;
  final ValueChanged<RegistrationChoice> onChanged;
  final bool enabled;
  final PlacementService? service;

  @override
  State<PlacementChoiceFields> createState() => _PlacementChoiceFieldsState();
}

class _PlacementChoiceFieldsState extends State<PlacementChoiceFields> {
  late final _codeController =
      TextEditingController(text: widget.value.resultCode);
  bool _checking = false;
  String? _codeError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  RegistrationChoice get _v => widget.value;

  Future<void> _check() async {
    final l = context.l10n;
    final code = RegistrationChoice.normalizeCode(_codeController.text);
    if (code.isEmpty) {
      setState(() => _codeError = l.placementErrBadResultCode);
      return;
    }
    setState(() {
      _checking = true;
      _codeError = null;
    });
    try {
      final summary =
          await (widget.service ?? PlacementService()).resolveResultCode(code);
      if (!mounted) return;
      var next = _v.copyWith(resultCode: code, checked: summary);
      // A result code says the visitor sat a placement test: pick that.
      if (!next.wantsTest) next = next.copyWith(choice: AppUser.choiceTest);
      if (next.target.isEmpty &&
          RegistrationChoice.targets.contains(summary.recommendedLevel)) {
        next = next.copyWith(target: summary.recommendedLevel);
      }
      widget.onChanged(next);
      if (summary.claimed) _codeError = l.placementErrClaimed;
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      widget.onChanged(_v.copyWith(clearChecked: true));
      _codeError = testErrorMessage(l, e);
    } catch (e) {
      if (!mounted) return;
      _codeError = '$e';
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final checked = _v.checked;
    final showChecked = checked != null &&
        checked.resultCode ==
            RegistrationChoice.normalizeCode(_codeController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.registerStartLevelTitle,
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        const SizedBox(height: 4),
        RadioGroup<String>(
          groupValue: _v.choice,
          onChanged: (v) {
            if (!widget.enabled || v == null) return;
            widget.onChanged(_v.copyWith(choice: v));
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: AppUser.choiceHsk1,
                contentPadding: EdgeInsets.zero,
                title: Text(l.registerChoiceHsk1),
                subtitle: Text(l.registerChoiceHsk1Help),
              ),
              RadioListTile<String>(
                value: AppUser.choiceTest,
                contentPadding: EdgeInsets.zero,
                title: Text(l.registerChoiceTest),
                subtitle: Text(l.registerChoiceTestHelp),
              ),
            ],
          ),
        ),
        if (_v.wantsTest) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: RegistrationChoice.targets.contains(_v.target)
                ? _v.target
                : null,
            decoration: InputDecoration(
              labelText: l.registerTargetLevel,
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
            items: [
              for (final t in RegistrationChoice.targets)
                DropdownMenuItem(value: t, child: Text(t)),
            ],
            validator: (v) => v == null ? l.registerTargetLevelRequired : null,
            onChanged: widget.enabled
                ? (v) => widget.onChanged(_v.copyWith(target: v ?? ''))
                : null,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                enabled: widget.enabled,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l.registerResultCodeLabel,
                  hintText: 'ABC123',
                  helperText: l.registerResultCodeHelper,
                  helperMaxLines: 3,
                  errorText: _codeError,
                  errorMaxLines: 3,
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
                onChanged: (v) {
                  setState(() => _codeError = null);
                  widget.onChanged(_v.copyWith(resultCode: v));
                },
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: !widget.enabled ||
                        _checking ||
                        _codeController.text.trim().isEmpty
                    ? null
                    : _check,
                child: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.registerResultCodeCheck),
              ),
            ),
          ],
        ),
        if (showChecked && !checked.claimed) ...[
          const SizedBox(height: 8),
          PlacementSummaryBox(summary: checked),
        ],
      ],
    );
  }
}

/// The paper's level, the mark, passed or not and the recommended level.
class PlacementSummaryBox extends StatelessWidget {
  const PlacementSummaryBox({super.key, required this.summary});

  final PlacementSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = summary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.placementSummaryLine(s.level, s.total, s.max),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            s.passed ? l.placementPassed : l.placementNotPassed,
            style: TextStyle(
              color: s.passed ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (s.recommendedLevel.isNotEmpty)
            Text(l.placementRecommended(s.recommendedLevel)),
        ],
      ),
    );
  }
}
