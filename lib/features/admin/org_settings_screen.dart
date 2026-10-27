import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/org_settings.dart';
import '../../models/pricing_settings.dart';
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
                onChanged: (v) => update(settings.copyWith(enablePayments: v)),
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
              const SectionHeader(title: 'Prices'),
              const _PricingCard(),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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

/// Editable prices and term validity (`settings/pricing`). The server reads
/// the same document when it creates invoices, so what the admin types here
/// is what students are charged. The landing page shows these too.
class _PricingCard extends StatefulWidget {
  const _PricingCard();

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  final _formKey = GlobalKey<FormState>();
  final _c8 = TextEditingController();
  final _c16 = TextEditingController();
  final _book = TextEditingController();
  final _registration = TextEditingController();
  final _days = TextEditingController();
  PricingSettings? _loaded;
  bool _saving = false;
  bool _dirty = false;

  @override
  void dispose() {
    for (final c in [_c8, _c16, _book, _registration, _days]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(PricingSettings p) {
    _loaded = p;
    _c8.text = '${p.package8}';
    _c16.text = '${p.package16}';
    _book.text = '${p.book}';
    _registration.text = '${p.registration}';
    _days.text = '${p.termValidDays}';
    _dirty = false;
  }

  String? _positiveInt(String? v) {
    final n = int.tryParse((v ?? '').replaceAll('.', '').trim());
    if (n == null || n <= 0) return 'Enter a whole number above 0';
    return null;
  }

  int _parse(TextEditingController c) =>
      int.parse(c.text.replaceAll('.', '').trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<FirestoreService>().updatePricing(
            PricingSettings(
              package8: _parse(_c8),
              package16: _parse(_c16),
              book: _parse(_book),
              registration: _parse(_registration),
              termValidDays: _parse(_days),
            ),
          );
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prices saved. New invoices use them.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not save: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label,
      {String? helper, String prefix = 'Rp '}) {
    return TextFormField(
      controller: c,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
          labelText: label, prefixText: prefix, helperText: helper),
      validator: _positiveInt,
      onChanged: (_) {
        if (!_dirty) setState(() => _dirty = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PricingSettings>(
      stream: context.read<FirestoreService>().watchPricing(),
      builder: (context, snap) {
        final remote = snap.data;
        // Fill once, and again whenever the stored doc changes while the form
        // is clean (another admin saved), without clobbering unsaved typing.
        if (remote != null &&
            (_loaded == null ||
                (!_dirty && remote.updatedAt != _loaded!.updatedAt))) {
          _fill(remote);
        }
        return AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Used for every new invoice and shown on the website. Existing '
                  'invoices keep the price they were created with.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 14),
                _field(_c8, '8-session term'),
                const SizedBox(height: 12),
                _field(_c16, '16-session term'),
                const SizedBox(height: 12),
                _field(_book, 'HSK materials & book'),
                const SizedBox(height: 12),
                _field(_registration, 'One-time registration',
                    helper: 'Shown on the website only.'),
                const SizedBox(height: 12),
                _field(_days, 'Term validity',
                    prefix: '',
                    helper:
                        'Days a paid term stays valid (flyer: 2 months = 60).'),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving || !_dirty ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save prices'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
