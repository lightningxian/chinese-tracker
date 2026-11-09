import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/locale_controller.dart';
import '../theme/app_theme.dart';

/// Small "ID | EN" segmented switch for the UI language.
///
/// Reads and writes [LocaleController]; the choice is saved on the device.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final l = context.l10n;
    final isId = controller.isIndonesian;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'ID',
            semanticLabel: l.languageToggleIndonesian,
            selected: isId,
            onTap: () => controller.setLocale(const Locale('id')),
          ),
          _Segment(
            label: 'EN',
            semanticLabel: l.languageToggleEnglish,
            selected: !isId,
            onTap: () => controller.setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile row: "Bahasa / Language" with the [LanguageToggle] on the right.
class LanguageSettingRow extends StatelessWidget {
  const LanguageSettingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.translate_outlined, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.languageRowLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        const LanguageToggle(),
      ],
    );
  }
}
