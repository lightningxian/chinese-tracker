import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Build 9 part 2: until an admin presses **Rebuild list indexes** once
/// after the deploy, older packages and worksheets have no list fields and
/// do not show in the paged lists. Admins get the button; teachers a note.
class ListIndexBanner extends StatefulWidget {
  const ListIndexBanner({
    super.key,
    required this.notIndexed,
    required this.isAdmin,
    required this.onRebuild,
  });

  final Future<int> notIndexed;
  final bool isAdmin;
  final Future<void> Function() onRebuild;

  @override
  State<ListIndexBanner> createState() => _ListIndexBannerState();
}

class _ListIndexBannerState extends State<ListIndexBanner> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<int>(
      future: widget.notIndexed,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        if (n <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppColors.error),
                Text(widget.isAdmin
                    ? l.listIndexMissingAdmin(n)
                    : l.listIndexMissingTeacher(n)),
                if (widget.isAdmin)
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await widget.onRebuild();
                            } catch (e) {
                              messenger.showSnackBar(
                                  SnackBar(content: Text('$e')));
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                    icon: const Icon(Icons.build_outlined, size: 18),
                    label: Text(l.listIndexRebuild),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

