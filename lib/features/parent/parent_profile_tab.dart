import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key, required this.parent});

  final AppUser parent;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final l = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parent.displayNameIndonesian,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(parent.email,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(l.parentProfileRole,
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AppCard(child: LanguageSettingRow()),
        const SizedBox(height: 16),
        const AppCard(child: ThemeSettingRow()),
        const SizedBox(height: 16),
        const AppCard(child: TextSizeSettingRow()),
        const SizedBox(height: 20),
        SectionHeader(title: l.parentProfileLinkedChildren),
        StreamBuilder<List<AppUser>>(
          stream: firestore.watchUsersByIds(parent.studentIds),
          builder: (context, snap) {
            final children = snap.data ?? [];
            if (children.isEmpty) {
              return Text(
                l.parentProfileNoChildren,
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: [
                for (final c in children)
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: AppColors.navy),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.displayNameIndonesian)),
                        if (c.level != null)
                          Text(c.level!,
                              style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthService>().signOut(),
          icon: Icon(Icons.logout, color: AppColors.error),
          label:
              Text(l.commonSignOut, style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}
