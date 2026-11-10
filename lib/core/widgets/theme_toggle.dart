import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/theme_controller.dart';
import '../theme/app_theme.dart';

/// Light / Dark / Device switch. Reads and writes [ThemeController]; the
/// choice is saved on the device.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final l = context.l10n;
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
      ),
      segments: [
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined, size: 18),
          label: Text(l.themeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined, size: 18),
          label: Text(l.themeDark),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.devices_outlined, size: 18),
          label: Text(l.themeSystem),
          tooltip: l.themeSystemHint,
        ),
      ],
      selected: {controller.mode},
      onSelectionChanged: (s) => controller.setMode(s.first),
    );
  }
}

/// Three-stop slider for the text size: Normal · Big · Bigger.
class TextSizeSlider extends StatelessWidget {
  const TextSizeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final l = context.l10n;
    final labels = [l.textSizeNormal, l.textSizeBig, l.textSizeBigger];
    final index = controller.textSize.index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          value: index.toDouble(),
          min: 0,
          max: (AppTextSize.values.length - 1).toDouble(),
          divisions: AppTextSize.values.length - 1,
          label: labels[index],
          onChanged: (v) =>
              controller.setTextSize(AppTextSize.values[v.round()]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final (i, label) in labels.indexed)
                Expanded(
                  child: Text(
                    label,
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == labels.length - 1
                            ? TextAlign.right
                            : TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          i == index ? FontWeight.w700 : FontWeight.w500,
                      color: i == index
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Header button next to the bell: opens a small panel with the theme switch
/// and the text-size slider, so the settings are one tap away on any page.
class AppearanceMenuButton extends StatelessWidget {
  const AppearanceMenuButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final l = context.l10n;
    return PopupMenuButton<void>(
      tooltip: l.appearanceMenuTooltip,
      icon: Icon(
        controller.isDark
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: iconColor ?? AppColors.textSecondary,
      ),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 380, maxWidth: 420),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _AppearancePanel(l: l),
        ),
      ],
    );
  }
}

class _AppearancePanel extends StatelessWidget {
  const _AppearancePanel({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    // The item is disabled so taps do not close the menu; its text would be
    // greyed out, so the labels set their own colour.
    final heading = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: AppColors.textPrimary,
    );
    return DefaultTextStyle.merge(
      style: TextStyle(color: AppColors.textPrimary),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.themeRowLabel, style: heading),
          const SizedBox(height: 8),
          const ThemeToggle(),
          const SizedBox(height: 16),
          Text(l.textSizeRowLabel, style: heading),
          const TextSizeSlider(),
        ],
      ),
    );
  }
}

/// Profile row: "Appearance" with the [ThemeToggle]. Wraps under the label
/// on narrow screens.
class ThemeSettingRow extends StatelessWidget {
  const ThemeSettingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.brightness_6_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              context.l10n.themeRowLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
        const ThemeToggle(),
      ],
    );
  }
}

/// Profile row: "Text size" with the [TextSizeSlider] underneath.
class TextSizeSettingRow extends StatelessWidget {
  const TextSizeSettingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_size_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              context.l10n.textSizeRowLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
        const TextSizeSlider(),
      ],
    );
  }
}
