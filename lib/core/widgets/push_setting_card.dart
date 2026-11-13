import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../services/push_service.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Profile card: "Push notifications" with an on/off switch for this device.
/// Renders nothing when the build has no VAPID key or the browser cannot
/// show notifications, so the profile tabs can always include it.
class PushSettingCard extends StatefulWidget {
  const PushSettingCard({super.key, required this.uid});

  final String uid;

  @override
  State<PushSettingCard> createState() => _PushSettingCardState();
}

class _PushSettingCardState extends State<PushSettingCard> {
  @override
  void initState() {
    super.initState();
    // After the first frame: sync() notifies listeners, which must not happen
    // while the tree is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PushService>().sync(widget.uid);
    });
  }

  Future<void> _toggle(bool on) async {
    final service = context.read<PushService>();
    final l = context.l10n;
    if (!on) {
      await service.disable();
      return;
    }
    final ok = await service.enable(widget.uid);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.blocked ? l.pushRowBlocked : l.pushEnableFailed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PushService>();
    if (!service.supported) return const SizedBox.shrink();
    final l = context.l10n;
    return Column(
      children: [
        AppCard(
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.pushRowLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.blocked ? l.pushRowBlocked : l.pushRowHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: service.blocked
                            ? AppColors.error
                            : AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: service.enabled,
                onChanged: service.busy ? null : _toggle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
