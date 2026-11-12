import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../models/teacher_link_code.dart';
import '../../services/teacher_link_code_service.dart';
import 'app_card.dart';

class TeacherStudentLinkCard extends StatefulWidget {
  const TeacherStudentLinkCard({
    super.key,
    required this.teacherId,
  });

  final String teacherId;

  @override
  State<TeacherStudentLinkCard> createState() => _TeacherStudentLinkCardState();
}

class _TeacherStudentLinkCardState extends State<TeacherStudentLinkCard> {
  TeacherLinkCode? _linkCode;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final linkCode = await TeacherLinkCodeService.ensureLinkCode(
        firestore: FirebaseFirestore.instance,
        teacherId: widget.teacherId,
      );
      if (!mounted) return;
      setState(() {
        _linkCode = linkCode;
        _loading = false;
      });
      _scheduleRefresh(linkCode);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scheduleRefresh(TeacherLinkCode linkCode) {
    _refreshTimer?.cancel();
    final delay = linkCode.timeRemaining + const Duration(seconds: 1);
    _refreshTimer = Timer(delay, _loadCode);
  }

  Future<void> _copyCode() async {
    final code = _linkCode?.code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.linkCardCopied)),
    );
  }

  String _formatRemaining(Duration remaining) {
    final minutes =
        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.linkCardTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l.linkCardBody,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Text(_error!, style: TextStyle(color: AppColors.error))
          else if (_linkCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _linkCode!.code,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: AppColors.navy,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.linkCardCopyTooltip,
                    onPressed: _copyCode,
                    icon: Icon(Icons.copy_outlined, color: AppColors.navy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _CountdownLabel(
              expiresAt: _linkCode!.expiresAt,
              onExpired: _loadCode,
              formatRemaining: _formatRemaining,
            ),
          ],
        ],
      ),
    );
  }
}

class _CountdownLabel extends StatefulWidget {
  const _CountdownLabel({
    required this.expiresAt,
    required this.onExpired,
    required this.formatRemaining,
  });

  final DateTime expiresAt;
  final VoidCallback onExpired;
  final String Function(Duration remaining) formatRemaining;

  @override
  State<_CountdownLabel> createState() => _CountdownLabelState();
}

class _CountdownLabelState extends State<_CountdownLabel> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _CountdownLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _remaining = widget.expiresAt.difference(DateTime.now());
    }
  }

  void _tick() {
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _timer.cancel();
      widget.onExpired();
      return;
    }
    setState(() => _remaining = remaining);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.linkCardRefreshesIn(widget.formatRemaining(_remaining)),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }
}
