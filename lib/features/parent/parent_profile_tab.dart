import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ParentProfileTab extends StatelessWidget {
  const ParentProfileTab({super.key, required this.parent});

  final AppUser parent;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parent.displayNameIndonesian,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(parent.email,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              const Text('Orang Tua (Parent)',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Linked children'),
        StreamBuilder<List<AppUser>>(
          stream: firestore.watchUsersByIds(parent.studentIds),
          builder: (context, snap) {
            final children = snap.data ?? [];
            if (children.isEmpty) {
              return const Text(
                'No children linked yet. Ask your admin to link your account.',
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
                        const Icon(Icons.person_outline,
                            color: AppColors.navy),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.displayNameIndonesian)),
                        if (c.level != null)
                          Text(c.level!,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
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
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: const Text('Sign out',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}
