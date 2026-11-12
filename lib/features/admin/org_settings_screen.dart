import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../l10n/l10n.dart';
import '../../models/org_settings.dart';
import '../../services/firestore_service.dart';

/// Admin-only centre settings. Toggles persist immediately to `settings/org`
/// and gate dependent features (payments, evaluations, teacher reschedule).
class OrgSettingsScreen extends StatelessWidget {
  const OrgSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final firestore = context.read<FirestoreService>();

    return ShellNestedPage(
      embedded: embedded,
      title: l.orgSettingsTitle,
      child: StreamBuilder<OrgSettings>(
        stream: firestore.watchOrgSettings(),
        builder: (context, snap) {
          final settings = snap.data ?? OrgSettings.defaults;
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;
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
                    content: Text(l.adminPriceSaveFailed('$e')),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionHeader(title: l.orgSettingsFeatures),
              _ToggleCard(
                title: l.navPayments,
                subtitle: l.orgSettingsPaymentsHint,
                icon: Icons.receipt_long_outlined,
                value: settings.enablePayments,
                onChanged: (v) => update(settings.copyWith(enablePayments: v)),
              ),
              _ToggleCard(
                title: l.orgSettingsEvalOpen,
                subtitle: l.orgSettingsEvalOpenHint,
                icon: Icons.assignment_outlined,
                value: settings.evaluationFormsOpen,
                onChanged: (v) =>
                    update(settings.copyWith(evaluationFormsOpen: v)),
              ),
              _ToggleCard(
                title: l.orgSettingsTeacherReschedule,
                subtitle: l.orgSettingsTeacherRescheduleHint,
                icon: Icons.event_repeat_outlined,
                value: settings.allowTeacherReschedule,
                onChanged: (v) =>
                    update(settings.copyWith(allowTeacherReschedule: v)),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: l.orgSettingsAccounts),
              _ToggleCard(
                title: l.orgSettingsRequireEmailVerification,
                subtitle: l.orgSettingsRequireEmailVerificationHint,
                icon: Icons.mark_email_read_outlined,
                value: settings.requireEmailVerification,
                onChanged: (v) =>
                    update(settings.copyWith(requireEmailVerification: v)),
              ),
              _ToggleCard(
                title: l.orgSettingsAutoPasswords,
                subtitle: l.orgSettingsAutoPasswordsHint,
                icon: Icons.password_outlined,
                value: settings.autoGenerateStaffPasswords,
                onChanged: (v) =>
                    update(settings.copyWith(autoGenerateStaffPasswords: v)),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: l.orgSettingsPrices),
              AppCard(
                onTap: () => context.push('/admin/price-list'),
                child: _NavRow(
                  icon: Icons.sell_outlined,
                  title: l.adminPriceTitle,
                  subtitle: l.orgSettingsPriceListHint,
                ),
              ),
              const SizedBox(height: 12),
              SectionHeader(title: l.orgSettingsAdministration),
              AppCard(
                onTap: () => context.push('/admin/audit-logs'),
                child: _NavRow(
                  icon: Icons.history,
                  title: l.auditLogTitle,
                  subtitle: l.orgSettingsAuditLogsHint,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                onTap: () => context.push('/admin/materials'),
                child: _NavRow(
                  icon: Icons.folder_open_outlined,
                  title: l.studentHomeQuickMaterials,
                  subtitle: l.orgSettingsMaterialsHint,
                ),
              ),
              if (settings.updatedAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  l.orgSettingsLastUpdated('${settings.updatedAt}'),
                  style: TextStyle(
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
            style: TextStyle(
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }
}

/// Editable prices and term validity (`settings/pricing`). The server reads
/// the same document when it creates invoices, so what the admin types here
/// is what students are charged. The landing page shows these too.
