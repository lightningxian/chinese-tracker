import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_toggle.dart';
import '../../l10n/l10n.dart';
import '../../models/placement.dart';
import '../../models/test_track.dart';
import '../../services/placement_service.dart';
import '../tests/test_labels.dart';
import '../tests/test_player_screen.dart';

/// What the token form hands to the player.
class PlacementStart {
  const PlacementStart({
    required this.token,
    required this.name,
    required this.whatsapp,
  });

  final String token;
  final String name;
  final String whatsapp;
}

/// A plain public page frame (no shell, no sign-in).
class _PublicPage extends StatelessWidget {
  const _PublicPage({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.navy,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 8), child: LanguageToggle()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// `/placement`: the placement tests on offer and the token form (Build 3,
/// Must 8). The name and the WhatsApp number are kept for registration.
class PlacementHomePage extends StatefulWidget {
  const PlacementHomePage({super.key, this.initialToken});

  /// From the QR code beside the token (`/placement?token=…`).
  final String? initialToken;

  @override
  State<PlacementHomePage> createState() => _PlacementHomePageState();
}

class _PlacementHomePageState extends State<PlacementHomePage> {
  final _formKey = GlobalKey<FormState>();
  late final _token = TextEditingController(text: widget.initialToken ?? '');
  final _name = TextEditingController();
  final _whatsapp = TextEditingController();
  late final Future<List<PlacementMenuEntry>> _menu = PlacementService().menu();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _token.dispose();
    _name.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    final token = _token.text.trim().toUpperCase().replaceAll(' ', '');
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      // Check the token first so a mistake shows here, not on a new page.
      await VisitorTestBackend().peek(token);
      if (!mounted) return;
      context.go('/placement/test',
          extra: PlacementStart(
            token: token,
            name: _name.text.trim(),
            whatsapp: _whatsapp.text.trim(),
          ));
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _error = testErrorMessage(context.l10n, e));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final resume = VisitorTestBackend.stored();
    return _PublicPage(
      title: l.placementTestLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.placementHomeTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(l.placementHomeIntro,
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          if (resume != null) ...[
            AppCard(
              child: Row(
                children: [
                  Expanded(child: Text(l.placementResumeBody)),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.go('/placement/test'),
                    child: Text(l.placementResume),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          FutureBuilder<List<PlacementMenuEntry>>(
            future: _menu,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              final codes = snap.data ?? const [];
              if (codes.isEmpty) {
                return Text(l.placementMenuEmpty,
                    style: TextStyle(color: AppColors.textSecondary));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final c in codes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [c.level, if (c.title.isNotEmpty) c.title]
                                  .join(' · '),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                l.testsMinutesTotal(c.minutes),
                                l.testsQuestionsCount(c.questions),
                                for (final p in c.parts)
                                  TestSkill.fromValue(p.skill).localized(l),
                              ].join(' · '),
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.placementFormTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _token,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: l.placementToken,
                      prefixIcon: const Icon(Icons.key_outlined),
                    ),
                    validator: (v) => (v ?? '').trim().length < 6
                        ? l.placementErrTokenShort
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l.placementName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v ?? '').trim().length < 2
                        ? l.placementErrVisitorDetails
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l.placementWhatsapp,
                      hintText: '0812…',
                      prefixIcon: const Icon(Icons.chat_outlined),
                    ),
                    validator: (v) {
                      final digits =
                          (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      return digits.length < 8 || digits.length > 15
                          ? l.placementErrVisitorDetails
                          : null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(l.placementKeptNote,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _checking ? null : _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _checking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(l.placementContinue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `/placement/test`: the supervised player in visitor mode. Without a
/// start (a reload) it resumes the attempt kept in this tab.
class PlacementTestPage extends StatelessWidget {
  const PlacementTestPage({super.key, this.start});

  final PlacementStart? start;

  @override
  Widget build(BuildContext context) {
    final s = start;
    if (s == null && VisitorTestBackend.stored() == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/placement');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return TestPlayerScreen(
      token: VisitorTestBackend.stored() == null ? s?.token : null,
      backend: VisitorTestBackend(
        name: s?.name ?? '',
        whatsapp: s?.whatsapp ?? '',
      ),
    );
  }
}

/// `/placement/result`: marks per part, passed or not, the recommended
/// level and the result code to register with. No review (the papers are
/// reused).
class PlacementResultPage extends StatelessWidget {
  const PlacementResultPage({super.key, this.result});

  final VisitorResult? result;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = result ?? VisitorTestBackend.lastResult();
    if (r == null) {
      return _PublicPage(
        title: l.placementTestLabel,
        child: EmptyState(
          icon: Icons.search_off,
          title: l.placementNoResult,
          subtitle: '',
        ),
      );
    }
    return _PublicPage(
      title: l.placementResultTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: PlacementChip(label: l.placementTestLabel),
                ),
                const SizedBox(height: 8),
                Text(
                  r.level,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                for (final p in r.parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                            child:
                                Text(TestSkill.fromValue(p.skill).localized(l))),
                        Text('${p.mark} / ${p.maxScore}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(l.placementTotal,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text('${r.total} / ${r.max}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.passed ? l.placementPassed : l.placementNotPassed,
                  style: TextStyle(
                    color: r.passed ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (r.recommendedLevel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(l.placementRecommended(r.recommendedLevel),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                Text(l.placementYourCode,
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                SelectableText(
                  r.resultCode,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: AppColors.navy,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(l.placementCodeHelp,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: r.resultCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.placementCopied)));
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(l.commonCopy),
                    ),
                    FilledButton.icon(
                      onPressed: () => context
                          .go('/register?placement=${r.resultCode}'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy),
                      icon: const Icon(Icons.how_to_reg),
                      label: Text(l.placementRegisterNow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
