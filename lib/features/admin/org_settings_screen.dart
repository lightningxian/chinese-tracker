import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/org_settings.dart';
import '../../services/firestore_service.dart';

/// Admin-only centre settings. Toggles persist immediately to `settings/org`
/// and gate dependent features (payments, evaluations, teacher reschedule).
class OrgSettingsScreen extends StatelessWidget {
  const OrgSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return ShellNestedPage(
      embedded: embedded,
      title: 'Settings',
      child: StreamBuilder<OrgSettings>(
        stream: firestore.watchOrgSettings(),
        builder: (context, snap) {
          final settings = snap.data ?? OrgSettings.defaults;
          final loading = snap.connectionState == ConnectionState.waiting &&
              !snap.hasData;
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          Future<void> update(OrgSettings next) async {
            try {
              await firestore.updateOrgSettings(next);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not save: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(title: 'Features'),
              _ToggleCard(
                title: 'Payments',
                subtitle:
                    'Show invoices and the pay/checkout UI for students and '
                    'admins. Turn off to hide billing entirely.',
                icon: Icons.receipt_long_outlined,
                value: settings.enablePayments,
                onChanged: (v) =>
                    update(settings.copyWith(enablePayments: v)),
              ),
              _ToggleCard(
                title: 'Evaluation forms open',
                subtitle:
                    'Allow teachers to create or edit semester evaluations. '
                    'Close between terms to freeze the forms.',
                icon: Icons.assignment_outlined,
                value: settings.evaluationFormsOpen,
                onChanged: (v) =>
                    update(settings.copyWith(evaluationFormsOpen: v)),
              ),
              _ToggleCard(
                title: 'Teachers can reschedule',
                subtitle:
                    'Let teachers edit their own class sessions. Turn off so '
                    'only admins can reschedule.',
                icon: Icons.event_repeat_outlined,
                value: settings.allowTeacherReschedule,
                onChanged: (v) =>
                    update(settings.copyWith(allowTeacherReschedule: v)),
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Accounts'),
              _ToggleCard(
                title: 'Require email verification',
                subtitle:
                    'Stored preference for future sign-up flows. Not enforced '
                    'automatically yet.',
                icon: Icons.mark_email_read_outlined,
                value: settings.requireEmailVerification,
                onChanged: (v) =>
                    update(settings.copyWith(requireEmailVerification: v)),
              ),
              _ToggleCard(
                title: 'Auto-generate staff passwords',
                subtitle:
                    'Stored preference for future staff creation. Not enforced '
                    'automatically yet.',
                icon: Icons.password_outlined,
                value: settings.autoGenerateStaffPasswords,
                onChanged: (v) =>
                    update(settings.copyWith(autoGenerateStaffPasswords: v)),
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Administration'),
              AppCard(
                onTap: () => context.push('/admin/audit-logs'),
                child: const _NavRow(
                  icon: Icons.history,
                  title: 'Audit logs',
                  subtitle: 'Money and permission events, newest first.',
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                onTap: () => context.push('/admin/materials'),
                child: const _NavRow(
                  icon: Icons.folder_open_outlined,
                  title: 'Materials',
                  subtitle: 'Shared files for students and parents.',
                ),
              ),
              if (settings.updatedAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Last updated ${settings.updatedAt}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: value,
          onChanged: onChanged,
          secondary: Icon(icon, color: AppColors.navy),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navy),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }
}
