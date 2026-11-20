import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/language_toggle.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';

/// Centre WhatsApp (the flyer's 0823-3383-6362), as wa.me expects it.
const centreWhatsAppNumber = '6282333836362';
const centreWhatsAppDisplay = '0823-3383-6362';

/// Build 3 (Must 3): a self-registered student waits here until an admin
/// approves them. The router sends a pending or rejected student nowhere
/// else. The page follows the profile, so the approval opens the app at
/// once.
class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((d) {
      final status = d.data()?['status'] as String?;
      final now = auth.appUser?.status;
      if (status != now || status == AppUser.statusActive) {
        unawaited(auth.refreshProfile());
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _whatsApp() async {
    final uri = Uri.parse('https://wa.me/$centreWhatsAppNumber');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.watch<AuthService>();
    final u = auth.appUser;
    final rejected = u?.isRejected ?? false;
    final choice = u == null
        ? ''
        : u.placementChoice == AppUser.choiceTest
            ? [
                l.waitingChoiceTest(u.placementTarget ?? ''),
                if ((u.placementResultCode ?? '').isNotEmpty)
                  l.waitingResultCode(u.placementResultCode!),
              ].join(' · ')
            : l.registerChoiceHsk1;
    return AuthScaffold(
      title: rejected ? l.waitingRejectedTitle : l.waitingTitle,
      subtitle: rejected ? l.waitingRejectedSubtitle : l.waitingSubtitle,
      topAction: const LanguageToggle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      rejected ? Icons.block_outlined : Icons.hourglass_top,
                      color: rejected ? AppColors.error : AppColors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        u?.staffLabel ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(u?.email ?? '',
                    style: TextStyle(color: AppColors.textSecondary)),
                const Divider(height: 24),
                Text(l.waitingYourChoice,
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(choice, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (rejected) ...[
                  Text(l.waitingReason,
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    (u?.rejectReason ?? '').isEmpty ? '—' : u!.rejectReason!,
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(l.waitingForAdmin),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _whatsApp,
            icon: const Icon(Icons.chat_outlined),
            label: Text(l.waitingWhatsApp(centreWhatsAppDisplay)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout),
            label: Text(l.commonSignOut),
          ),
        ],
      ),
    );
  }
}
