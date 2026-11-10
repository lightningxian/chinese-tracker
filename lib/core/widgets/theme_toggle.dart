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
