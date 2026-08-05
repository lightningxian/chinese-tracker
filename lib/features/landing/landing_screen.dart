import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_logo.dart';
import 'landing_media.dart';
import 'widgets/landing_youtube_embed.dart';

/// Debug → one-click test login; release → real login.
String get _signInRoute => kDebugMode ? '/dev-login' : '/login';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scroll = ScrollController();
  final _featuresKey = GlobalKey();
  final _rolesKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.card.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 66,
            title: const _NavBrand(),
            actions: [
              if (MediaQuery.sizeOf(context).width >= 520) ...[
                TextButton(
                  onPressed: () => _scrollTo(_featuresKey),
                  child: const Text('Features'),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_rolesKey),
                  child: const Text('For you'),
                ),
              ],
              TextButton(
                onPressed: () => context.go(_signInRoute),
                child: const Text('Sign in'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton(
                  onPressed: () => context.go('/register'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  child: const Text('Get started'),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _HeroSection()),
          SliverToBoxAdapter(child: _TrustBar()),
          SliverToBoxAdapter(
            child: KeyedSubtree(key: _featuresKey, child: _FeaturesSection()),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(key: _rolesKey, child: _RolesSection()),
          ),
          SliverToBoxAdapter(child: _HowItWorksSection()),
          SliverToBoxAdapter(child: _VisualShowcaseSection()),
          if (kIsWeb) SliverToBoxAdapter(child: _DownloadAppSection()),
          SliverToBoxAdapter(child: _CtaSection()),
          SliverToBoxAdapter(child: const _LandingFooter()),
        ],
      ),
    );
  }
}

class _NavBrand extends StatelessWidget {
  const _NavBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(variant: AppLogoVariant.mascot, height: 32),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.brandName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
            ),
            const Text(
              AppConstants.brandNameChinese,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF14181F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.network(
                LandingMedia.heroBackground,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 24,
              vertical: isWide ? 72 : 48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _heroCopy(context)),
                          const SizedBox(width: 48),
                          Expanded(child: _HeroPreviewCard()),
                        ],
                      )
                    : Column(
                        children: [
                          const _HeroPreviewCard(),
                          const SizedBox(height: 32),
                          _heroCopy(context),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(
          label: 'Mandarin learning platform',
          background: AppColors.teal.withValues(alpha: 0.25),
          color: const Color(0xFF8EC5D4),
        ),
        const SizedBox(height: 16),
        Text(
          'Learn Chinese.\nTeach with confidence.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.12,
                fontSize: 40,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'One platform for your Chinese course — HSK-aligned lessons, live '
          'classes, progress tracking, and online payments. For students, '
          'parents, teachers, and your centre.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 17,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => context.go('/register'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              child: const Text('Create free account →'),
            ),
            OutlinedButton(
              onPressed: () => context.go(_signInRoute),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
        const SizedBox(height: 34),
        const Wrap(
          spacing: 28,
          runSpacing: 12,
          children: [
            _HeroStat(value: 'HSK 1–6', label: 'Structured levels'),
            _HeroStat(value: '8 / 16', label: 'Sessions per term'),
            _HeroStat(value: 'Web + mobile', label: 'Learn anywhere'),
          ],
        ),
      ],
    );
  }
}

class _HeroPreviewCard extends StatelessWidget {
  const _HeroPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        children: const [
          _PreviewRow(
            icon: Icons.check_circle_outline,
            iconBg: Color(0xFFE7F5EF),
            iconColor: AppColors.success,
            title: 'Lesson 3 · Greetings',
            subtitle: '你好 · Completed',
            pill: '92%',
          ),
          _PreviewRow(
            icon: Icons.headphones_outlined,
            iconBg: Color(0xFFE8F0FE),
            iconColor: Color(0xFF2B5FB0),
            title: 'Listening practice',
            subtitle: 'HSK 2 · Due today',
          ),
          _PreviewRow(
            icon: Icons.videocam_outlined,
            iconBg: Color(0xFFF0EAFB),
            iconColor: Color(0xFF6B4FBF),
            title: 'Live class · 16:00',
            subtitle: 'Beginner A · Room A',
          ),
          _PreviewRow(
            icon: Icons.payments_outlined,
            iconBg: Color(0xFFFDF3E0),
            iconColor: Color(0xFFB7791F),
            title: '8-session package',
            subtitle: 'Paid · Rp 800,000',
            pill: 'Active',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.pill,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? pill;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (pill != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pill!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _TrustBar extends StatelessWidget {
  static const _items = [
    ('📗', 'HSK 1–6', 'curriculum-aligned'),
    ('🗓️', '8 / 16 sessions', 'flexible terms'),
    ('💳', 'Midtrans', 'cards & installments'),
    ('📱', 'Web + Android + iPhone', ''),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 20,
        vertical: 26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final item in _items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${item.$1} ${item.$2}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: AppColors.navy)),
                      if (item.$3.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(item.$3,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  static const _features = [
    (Icons.menu_book_outlined, 'Lessons & quizzes',
        'HSK-aligned lessons with vocabulary, quizzes, and instant scoring.',
        Color(0xFFE7F5EF), AppColors.success),
    (Icons.edit_note_outlined, 'Practice exercises',
        'Reading, listening, typing, and speaking — organised by HSK level.',
        Color(0xFFE8F0FE), Color(0xFF2B5FB0)),
    (Icons.videocam_outlined, 'Live classes & attendance',
        'Students join scheduled sessions; teachers track attendance and terms.',
        Color(0xFFF0EAFB), Color(0xFF6B4FBF)),
    (Icons.grade_outlined, 'Progress & grades',
        'Scores, letter grades, and semester evaluations — visible to parents too.',
        Color(0xFFFDF3E0), Color(0xFFB7791F)),
    (Icons.payments_outlined, 'Online payments',
        'Pay session packages by card, bank transfer, or installments via Midtrans.',
        Color(0xFFE7F5EF), AppColors.success),
    (Icons.insights_outlined, 'Reports for admins',
        'Revenue, outstanding invoices, and cohort activity at a glance.',
        Color(0xFFE8F0FE), Color(0xFF2B5FB0)),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final padding = EdgeInsets.symmetric(
      horizontal: isWide ? 48 : 24,
      vertical: 64,
    );

    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const _SectionIntro(
                eyebrow: 'Everything in one place',
                title: 'Built for Mandarin education',
                body:
                    'Easy Study connects students, parents, teachers, and centre '
                    'admins on a single platform.',
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = isWide ? 3 : 1;
                  final gap = 18.0;
                  final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final f in _features)
                        SizedBox(
                          width: cols == 1 ? double.infinity : w,
                          child: AppCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: f.$4,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(f.$1, color: f.$5, size: 22),
                                ),
                                const SizedBox(height: 14),
                                Text(f.$2,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17)),
                                const SizedBox(height: 8),
                                Text(f.$3,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        height: 1.45)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolesSection extends StatelessWidget {
  static const _roles = [
    ('Students', 'Murid',
        'Join classes, do homework, track HSK progress, and see sessions remaining.',
        Icons.menu_book_outlined, AppColors.teal),
    ('Teachers', 'Guru',
        'Manage students, assign practice, run live classes, and record grades.',
        Icons.school_outlined, AppColors.navy),
    ('Centre operators', 'Admin',
        'Users, vouchers, payments, reports, and platform-wide activity.',
        Icons.verified_user_outlined, Color(0xFF6B4FBF)),
    ('Families', 'Orang Tua',
        'Parents follow their child\'s progress, attendance, grades, and bills.',
        Icons.family_restroom_outlined, AppColors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const _SectionIntro(
                eyebrow: 'Built for every role',
                title: 'One app, four experiences',
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w >= 900 ? 4 : (w >= 520 ? 2 : 1);
                  final gap = 16.0;
                  final cardW = (w - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final r in _roles)
                        SizedBox(
                          width: cols == 1 ? double.infinity : cardW,
                          child: AppCard(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.$1,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                Text(r.$2,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 19,
                                        color: AppColors.navy)),
                                const SizedBox(height: 8),
                                Text(r.$3,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.textSecondary,
                                        height: 1.45)),
                                const SizedBox(height: 12),
                                Icon(r.$4, color: r.$5, size: 28),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  static const _steps = [
    ('Register with your teacher\'s code',
        'Pick your HSK level and term size, and enter the code from your teacher.'),
    ('Learn & attend classes',
        'Work through lessons and exercises, and join scheduled live sessions.'),
    ('Track progress & pay online',
        'See grades and sessions left; top up packages securely when you need to.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const _SectionIntro(
                eyebrow: 'How it works',
                title: 'Up and running in minutes',
              ),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = isWide ? 3 : 1;
                  final gap = 18.0;
                  final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        SizedBox(
                          width: cols == 1 ? double.infinity : w,
                          child: AppCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 17,
                                  backgroundColor: AppColors.navy,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(_steps[i].$1,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(_steps[i].$2,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        height: 1.45)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualShowcaseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Container(
      color: const Color(0xFFF0F2F5),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            children: [
              const _SectionIntro(
                eyebrow: 'See it in action',
                title: 'Professional Mandarin learning, beautifully organised',
                body:
                    'Structured lessons, live classes, and real progress — '
                    'the way a modern language centre should work.',
              ),
              const SizedBox(height: 32),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _NetworkPhoto(
                            url: LandingMedia.showcaseClassroom,
                            height: 200,
                          ),
                          const SizedBox(height: 16),
                          _NetworkPhoto(
                            url: LandingMedia.showcaseStudy,
                            height: 200,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LandingYoutubeEmbed(height: 280),
                          const SizedBox(height: 16),
                          Text(
                            'Watch how structured Mandarin teaching works — '
                            'from vocabulary to live conversation practice.',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                const LandingYoutubeEmbed(height: 220),
                const SizedBox(height: 16),
                _NetworkPhoto(
                  url: LandingMedia.showcaseClassroom,
                  height: 180,
                ),
                const SizedBox(height: 12),
                _NetworkPhoto(
                  url: LandingMedia.showcaseStudy,
                  height: 180,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            color: AppColors.border,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: AppColors.border,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 24, 48, isWide ? 48 : 24, 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(44),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Ready to start learning?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Create your account in minutes — choose your HSK level, pick a '
                  'term size, and join your teacher\'s centre.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => context.go('/register'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Get started free'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.go(_signInRoute),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadAppSection extends StatelessWidget {
  Future<void> _openApk(BuildContext context) async {
    if (!AppConstants.hasAndroidApk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Android download will be available soon.'),
        ),
      );
      return;
    }
    final uri = Uri.parse(AppConstants.androidApkUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the download link.')),
      );
    }
  }

  void _showIosInstructions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Install on iPhone or iPad',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.navy,
              ),
            ),
            SizedBox(height: 16),
            _IosStep(number: '1', text: 'Open this page in Safari.'),
            _IosStep(
              number: '2',
              text: 'Tap Share → “Add to Home Screen”.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 24, 0, isWide ? 48 : 24, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: AppCard(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                const _Eyebrow(label: 'Get the app'),
                const SizedBox(height: 10),
                Text(
                  'Learn on your phone',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Install Easy Study on Android, or add it to your iPhone home screen from Safari.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openApk(context),
                      icon: const Icon(Icons.android),
                      label: const Text('Download for Android'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showIosInstructions(context),
                      icon: const Icon(Icons.phone_iphone),
                      label: const Text('Install on iPhone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IosStep extends StatelessWidget {
  const _IosStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.teal,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Center(
        child: Column(
          children: [
            const AppLogo(variant: AppLogoVariant.mascot, height: 40),
            const SizedBox(height: 12),
            Text(
              '${AppConstants.brandNameChinese} · ${AppConstants.brandName}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.brandTagline,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              children: [
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Register'),
                ),
                TextButton(
                  onPressed: () => context.go(_signInRoute),
                  child: const Text('Sign in'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '© ${DateTime.now().year} ${AppConstants.brandName}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Eyebrow(label: eyebrow),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: -0.4,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 10),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({
    required this.label,
    this.background,
    this.color,
  });

  final String label;
  final Color? background;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFE7F5EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color ?? AppColors.teal,
        ),
      ),
    );
  }
}
