import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_logo.dart';
import 'landing_brand.dart';

/// Debug → one-click test login; release → real login.
String get _signInRoute => kDebugMode ? '/dev-login' : '/login';

const _maxWidth = 1120.0;
const _wideBreak = 900.0;
const _midBreak = 600.0;

/// Centre WhatsApp number from the course flyer (0823-3383-6362), in the
/// international form wa.me expects.
const _whatsAppNumber = '6282333836362';
const _whatsAppGreeting =
    'Halo Easy Study, saya ingin bertanya tentang kursus Mandarin.';

Future<void> _openWhatsApp(BuildContext context) async {
  final uri = Uri.parse(
    'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(_whatsAppGreeting)}',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open WhatsApp. Message us on 0823-3383-6362.'),
      ),
    );
  }
}

/// Round WhatsApp button pinned to the bottom corner of the landing page.
class _WhatsAppFab extends StatelessWidget {
  const _WhatsAppFab();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chat with us on WhatsApp',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: LandingBrand.lift(4),
        ),
        child: Material(
          color: const Color(0xFF25D366), // WhatsApp green
          shape: const CircleBorder(
            side: BorderSide(color: LandingBrand.black, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openWhatsApp(context),
            child: const SizedBox(
              width: 58,
              height: 58,
              child: Icon(Icons.chat_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

double _gutter(double width) => width >= _wideBreak ? 48 : 20;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scroll = ScrollController();
  final _featuresKey = GlobalKey();
  final _levelsKey = GlobalKey();
  final _rolesKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _pricingKey = GlobalKey();

  /// Height of the pinned top bar (toolbar + black rule). Sections scroll to
  /// sit just below it instead of under it.
  static const _navHeight = 72.0 + 3;

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext?.findRenderObject();
    if (target == null || !_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.of(target);
    final offset = viewport.getOffsetToReveal(target, 0).offset - _navHeight;
    _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
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
    final width = MediaQuery.sizeOf(context).width;
    final showLinks = width >= 760;

    return Scaffold(
      backgroundColor: LandingBrand.white,
      floatingActionButton: const _WhatsAppFab(),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: LandingBrand.white,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 72,
            titleSpacing: _gutter(width),
            title: AppLogo(
              variant: AppLogoVariant.primary,
              height: width >= _midBreak ? 54 : 44,
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(3),
              child: ColoredBox(
                color: LandingBrand.black,
                child: SizedBox(height: 3, width: double.infinity),
              ),
            ),
            actions: [
              if (showLinks) ...[
                // Same order as the sections appear down the page.
                _NavLink('HSK levels', () => _scrollTo(_levelsKey)),
                _NavLink('About', () => _scrollTo(_aboutKey)),
                _NavLink('Classes', () => _scrollTo(_featuresKey)),
                _NavLink('For parents', () => _scrollTo(_rolesKey)),
                _NavLink('Prices', () => _scrollTo(_pricingKey)),
                _NavLink('Sign in', () => context.push(_signInRoute)),
                const SizedBox(width: 8),
              ] else
                _NavLink('Sign in', () => context.push(_signInRoute)),
              Padding(
                padding: EdgeInsets.only(right: _gutter(width)),
                child: _BrandButton(
                  label: 'Sign up',
                  compact: true,
                  onPressed: () => context.push('/register'),
                ),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: _HeroSection()),
          const SliverToBoxAdapter(child: _Scallop()),
          SliverToBoxAdapter(
            child: KeyedSubtree(key: _levelsKey, child: const _RulerSection()),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(key: _aboutKey, child: const _AboutSection()),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _featuresKey,
              child: const _FeaturesSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: KeyedSubtree(key: _rolesKey, child: const _RolesSection()),
          ),
          SliverToBoxAdapter(
            child:
                KeyedSubtree(key: _pricingKey, child: const _PricingSection()),
          ),
          if (kIsWeb) const SliverToBoxAdapter(child: _DownloadAppSection()),
          const SliverToBoxAdapter(child: _CtaSection()),
          const SliverToBoxAdapter(child: _LandingFooter()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _NavLink extends StatelessWidget {
  const _NavLink(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: LandingBrand.ink,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(
        label,
        style: LandingBrand.body(size: 15, weight: FontWeight.w500),
      ),
    );
  }
}

enum _Tone { teal, white, yellow }

class _BrandButton extends StatelessWidget {
  const _BrandButton({
    required this.label,
    required this.onPressed,
    this.tone = _Tone.teal,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final _Tone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _Tone.teal => (LandingBrand.teal, LandingBrand.white),
      _Tone.white => (LandingBrand.white, LandingBrand.teal),
      _Tone.yellow => (LandingBrand.yellow, LandingBrand.teal),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: LandingBrand.lift(compact ? 3 : 4),
      ),
      child: Material(
        color: bg,
        shape: const StadiumBorder(
          side: BorderSide(color: LandingBrand.black, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24,
              vertical: compact ? 7 : 11,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: LandingBrand.display(
                    size: compact ? 15 : 18,
                    color: fg,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.child,
    this.color = LandingBrand.white,
    this.vertical = 64,
  });

  final Widget child;
  final Color color;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _gutter(width),
          vertical: vertical,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title,
      {this.sub,
      this.color = LandingBrand.teal,
      this.subColor = LandingBrand.ink2});

  final String title;
  final String? sub;
  final Color color;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreak;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: LandingBrand.display(
                size: wide ? 40 : 30, color: color, height: 1.05)),
        if (sub != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child:
                Text(sub!, style: LandingBrand.body(size: 16, color: subColor)),
          ),
        ],
      ],
    );
  }
}

/// Lays children in equal-width columns that collapse as the width shrinks.
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    this.minItemWidth = 220,
    this.maxColumns = 4,
  });

  static const gap = 18.0;

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        var cols =
            ((w + gap) / (minItemWidth + gap)).floor().clamp(1, maxColumns);
        if (cols > children.length) cols = children.length;
        final itemW = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in children) SizedBox(width: itemW, child: c),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= _wideBreak;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Chip('HSK 1–6 · kids, teens and adults'),
        const SizedBox(height: 18),
        _Headline(size: wide ? 64 : 42),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            'Face-to-face classes at our centre, exercises written to the HSK '
            'standard, and progress parents can see in the app.',
            style: LandingBrand.body(size: 17, height: 1.55),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _BrandButton(
              label: 'Start learning',
              onPressed: () => context.push('/register'),
            ),
            _BrandButton(
              label: "I'm a parent",
              tone: _Tone.white,
              onPressed: () => context.push('/register'),
            ),
            _BrandButton(
              label: 'WhatsApp us',
              icon: Icons.chat_outlined,
              tone: _Tone.white,
              onPressed: () => _openWhatsApp(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Already a student? Ask your teacher for the link code when you register.',
          style: LandingBrand.body(size: 13, color: LandingBrand.ink2),
        ),
      ],
    );

    final art = _HeroArt(height: wide ? 420 : 280);

    return _Section(
      color: LandingBrand.yellow,
      vertical: wide ? 64 : 40,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 11, child: copy),
                const SizedBox(width: 24),
                Expanded(flex: 9, child: art),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 28), art],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: LandingBrand.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LandingBrand.black, width: 2),
      ),
      child: Text(
        label,
        style:
            LandingBrand.body(size: 14, weight: FontWeight.w500, height: 1.3),
      ),
    );
  }
}

/// "Mandarin made easy." with the last word outlined in teal on white.
class _Headline extends StatelessWidget {
  const _Headline({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final base = LandingBrand.display(size: size, height: 0.95);
    final stroke = base.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = LandingBrand.teal,
    );
    final fill = base.copyWith(color: LandingBrand.white);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mandarin', style: base),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('made ', style: base),
            Stack(
              children: [
                Text('easy.', style: fill),
                Text('easy.', style: stroke),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Big brush 易 (cropped from the logo calligraphy), pencil mascot, bubble.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final hanHeight = height * 0.78;
    final pencilHeight = height * 0.8;
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Big 易 ("easy", the first character of 易华). Drawn as text in the
          // app's CJK font: the logo's cursive 易 looks like a fragment on its own.
          Positioned(
            left: 0,
            right: height * 0.18,
            child: Center(
              child: Text(
                '易',
                style: LandingBrand.han(
                        size: hanHeight * 0.92, color: LandingBrand.green)
                    .copyWith(fontWeight: FontWeight.w900, height: 1),
              ),
            ),
          ),
          Positioned(
            right: height * 0.02,
            bottom: 0,
            child: Transform.rotate(
              angle: 8 * math.pi / 180,
              child: Image.asset(
                'assets/brand/mascot_pencil.png',
                height: pencilHeight,
                fit: BoxFit.fitHeight,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Positioned(
            top: height * 0.02,
            left: height * 0.04,
            child: const _SpeechBubble(),
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
          decoration: LandingBrand.card(radius: 22, liftBy: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('你好!', style: LandingBrand.han(size: 30)),
              Text(
                'nǐ hǎo',
                style: LandingBrand.body(
                    size: 13, color: LandingBrand.ink2, height: 1.2),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -11,
          right: 24,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: LandingBrand.white,
                border: Border(
                  right: BorderSide(color: LandingBrand.black, width: 3),
                  bottom: BorderSide(color: LandingBrand.black, width: 3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The wavy line between the pencil's yellow body and its teal tip.
class _Scallop extends StatelessWidget {
  const _Scallop();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 26,
      width: double.infinity,
      child: CustomPaint(painter: _ScallopPainter()),
    );
  }
}

class _ScallopPainter extends CustomPainter {
  const _ScallopPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = LandingBrand.teal);
    final yellow = Paint()..color = LandingBrand.yellow;
    const step = 34.0;
    for (var x = step / 2; x < size.width + step; x += step) {
      canvas.drawCircle(Offset(x, 0), 13, yellow);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// HSK ruler
// ---------------------------------------------------------------------------

const _hskLevels = [
  ('HSK 1', '150 words'),
  ('HSK 2', '300 words'),
  ('HSK 3', '600 words'),
  ('HSK 4', '1,200 words'),
  ('HSK 5', '2,500 words'),
  ('HSK 6', '5,000 words'),
];

class _RulerSection extends StatelessWidget {
  const _RulerSection();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreak;
    return _Section(
      color: LandingBrand.teal,
      vertical: wide ? 56 : 44,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            'Measure your Mandarin',
            sub: 'Six HSK levels. Each one roughly doubles the words you know, '
                'and every lesson and exercise is tagged with its level.',
            color: LandingBrand.white,
            subColor: LandingBrand.tealTint,
          ),
          const SizedBox(height: 30),
          _RulerBar(columns: wide ? 6 : 3),
        ],
      ),
    );
  }
}

class _RulerBar extends StatelessWidget {
  const _RulerBar({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <List<(String, String)>>[];
    for (var i = 0; i < _hskLevels.length; i += columns) {
      rows.add(_hskLevels.sublist(i, math.min(i + columns, _hskLevels.length)));
    }
    const line = BorderSide(color: LandingBrand.black, width: 3);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration:
          LandingBrand.card(color: LandingBrand.yellow, radius: 10, liftBy: 6),
      child: Column(
        children: [
          const SizedBox(
            height: 16,
            width: double.infinity,
            child: CustomPaint(painter: _TickPainter()),
          ),
          Table(
            border:
                const TableBorder(verticalInside: line, horizontalInside: line),
            children: [
              for (final row in rows)
                TableRow(
                  children: [
                    for (final (level, words) in row)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(level,
                                style: LandingBrand.display(
                                    size: 24, height: 1.1)),
                            const SizedBox(height: 2),
                            Text(words,
                                style:
                                    LandingBrand.body(size: 13, height: 1.3)),
                          ],
                        ),
                      ),
                    for (var i = row.length; i < columns; i++)
                      const SizedBox.shrink(),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LandingBrand.black.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (var x = 8.0; x < size.width; x += 14) {
      final tall = ((x - 8) / 14).round() % 5 == 0;
      canvas.drawLine(Offset(x, 0),
          Offset(x, tall ? size.height : size.height * 0.55), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// About
// ---------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreak;

    final story = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ABOUT EASY STUDY',
              style: LandingBrand.body(
                      size: 12,
                      weight: FontWeight.w700,
                      color: LandingBrand.teal)
                  .copyWith(letterSpacing: 1.6),
            ),
            const SizedBox(width: 10),
            Text('易华文教中心',
                style: LandingBrand.han(size: 14, color: LandingBrand.ink2)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Built around the HSK.',
          style: LandingBrand.display(size: wide ? 40 : 30, height: 1.05),
        ),
        const SizedBox(height: 14),
        Text(
          'Easy Study is a Mandarin learning centre that teaches to the HSK '
          'standard, from HSK 1 to HSK 6. Every lesson and exercise is written '
          'for the level it serves, and practice includes past exam questions '
          'taken directly from the test itself, so students meet the real '
          'thing long before exam day.',
          style: LandingBrand.body(size: 17, height: 1.6),
        ),
        const SizedBox(height: 10),
        Text(
          'Classes are face-to-face at our centre, taught by our own teachers. '
          'The app keeps the homework, scores and attendance in one place for '
          'students and their parents.',
          style: LandingBrand.body(
              size: 17, height: 1.6, color: LandingBrand.ink2),
        ),
      ],
    );

    const proofs = [
      ('HSK 1–6', 'Lessons and exercises written to each level'),
      ('Real past papers', 'Practice with questions from actual HSK tests'),
      ('At the centre', 'Face-to-face classes, attendance counted in the app'),
    ];
    final proofColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (big, small) in proofs) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            decoration:
                LandingBrand.card(color: LandingBrand.yellowSoft, liftBy: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(big, style: LandingBrand.display(size: 26, height: 1.1)),
                const SizedBox(height: 4),
                Text(small,
                    style: LandingBrand.body(
                        size: 14, color: LandingBrand.ink2, height: 1.4)),
              ],
            ),
          ),
          if (big != proofs.last.$1) const SizedBox(height: 14),
        ],
      ],
    );

    return _Section(
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: story),
                const SizedBox(width: 48),
                Expanded(flex: 2, child: proofColumn),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [story, const SizedBox(height: 28), proofColumn],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Features
// ---------------------------------------------------------------------------

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: LandingBrand.yellowSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            'Everything your class needs',
            sub: 'One place for lessons, homework, attendance and bills.',
          ),
          const SizedBox(height: 30),
          const _ResponsiveGrid(
            children: [
              _FeatureCard(
                icon: Icons.storefront_outlined,
                title: 'Classes at the centre',
                body: 'Face-to-face lessons with our teachers. Attendance is '
                    'counted for you, session by session.',
              ),
              _FeatureCard(
                icon: Icons.edit_outlined,
                title: 'HSK practice',
                body:
                    'Reading, listening, typing and speaking exercises, sorted '
                    'by HSK level, including real past exam questions.',
              ),
              _FeatureCard(
                icon: Icons.insights_outlined,
                title: 'Progress and grades',
                body:
                    'Scores, letter grades and teacher notes, all in one view.',
              ),
              _FeatureCard(
                icon: Icons.credit_card_outlined,
                title: 'Pay online',
                body: 'Card, bank transfer or installments through Midtrans. '
                    'Sessions are added as soon as payment clears.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: LandingBrand.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: LandingBrand.yellow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LandingBrand.black, width: 2),
            ),
            child: Icon(icon, color: LandingBrand.teal, size: 26),
          ),
          const SizedBox(height: 12),
          Text(title, style: LandingBrand.display(size: 22, height: 1.1)),
          const SizedBox(height: 6),
          Text(body,
              style: LandingBrand.body(size: 14.5, color: LandingBrand.ink2)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Roles + term tickets
// ---------------------------------------------------------------------------

class _RolesSection extends StatelessWidget {
  const _RolesSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('One app for the whole family'),
          const SizedBox(height: 30),
          const _ResponsiveGrid(
            children: [
              _RoleCard('Murid', 'Students',
                  'Classes, homework and your HSK progress.'),
              _RoleCard('Guru', 'Teachers',
                  'Run classes, assign practice, record grades.'),
              _RoleCard('Orang Tua', 'Parents',
                  'Attendance, grades and bills for your child.'),
              _RoleCard(
                  'Admin', 'Centre', 'Users, vouchers, payments and reports.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard(this.who, this.en, this.body);

  final String who;
  final String en;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: LandingBrand.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            en.toUpperCase(),
            style: LandingBrand.body(
                    size: 12, weight: FontWeight.w700, color: LandingBrand.ink2)
                .copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 4),
          Text(who, style: LandingBrand.display(size: 28, height: 1.05)),
          const SizedBox(height: 8),
          Text(body,
              style: LandingBrand.body(size: 14.5, color: LandingBrand.ink2)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prices (from the centre's offline-course flyer)
// ---------------------------------------------------------------------------

class _PricingSection extends StatelessWidget {
  const _PricingSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: LandingBrand.yellowSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            'Pick a term',
            sub:
                'Face-to-face classes at our centre, 1.5 hours each, 6–8 students '
                'per class, for students aged 13 and above. Both terms are valid '
                'for 2 months.',
          ),
          const SizedBox(height: 16),
          const _Chip('One-time registration: Rp 100.000'),
          const SizedBox(height: 26),
          _ResponsiveGrid(
            minItemWidth: 300,
            maxColumns: 2,
            children: [
              _PlanCard(
                sessions: 8,
                hours: 12,
                price: 'Rp 2.450.000',
                note: 'A good start for HSK 1–2, or for a busy schedule.',
                onPressed: () => context.push('/register'),
              ),
              _PlanCard(
                sessions: 16,
                hours: 24,
                price: 'Rp 3.950.000',
                note: 'Steady progress with two classes a week.',
                highlight: true,
                tag: 'Best value',
                onPressed: () => context.push('/register'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ResponsiveGrid(
            minItemWidth: 250,
            maxColumns: 3,
            children: [
              _InfoTile(
                icon: Icons.menu_book_outlined,
                title: 'HSK materials and book',
                body: 'Rp 250.000.',
              ),
              _InfoTile(
                icon: Icons.schedule_outlined,
                title: 'Open class times (WIB)',
                body:
                    'Tue, Wed, Fri 15:00–16:30 · Sat 10:00–11:30 and 11:30–13:00.',
              ),
              _InfoTile(
                icon: Icons.credit_card_outlined,
                title: 'Pay online',
                body:
                    'Card, bank transfer or installments through Midtrans. Sessions are '
                    'added to your term as soon as payment clears.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.sessions,
    required this.hours,
    required this.price,
    required this.note,
    required this.onPressed,
    this.highlight = false,
    this.tag,
  });

  final int sessions;
  final int hours;
  final String price;
  final String note;
  final VoidCallback onPressed;
  final bool highlight;
  final String? tag;

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: LandingBrand.teal),
            const SizedBox(width: 10),
            Expanded(
                child: Text(text,
                    style: LandingBrand.body(size: 14.5, height: 1.4))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LandingBrand.card(liftBy: 6),
      // Round the content to the border's inner curve (18 − 3 px) so the
      // header fill never paints over the card's corners.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
              decoration: BoxDecoration(
                color: highlight ? LandingBrand.yellow : LandingBrand.white,
                border: const Border(
                    bottom: BorderSide(color: LandingBrand.black, width: 3)),
              ),
              child: Row(
                children: [
                  Text('$sessions sessions',
                      style: LandingBrand.display(size: 26, height: 1.1)),
                  const Spacer(),
                  if (tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: LandingBrand.black,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag!,
                        style: LandingBrand.display(
                            size: 13, color: LandingBrand.yellow, height: 1.2),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price,
                      style: LandingBrand.display(
                          size: 40, color: LandingBrand.ink, height: 1)),
                  const SizedBox(height: 4),
                  Text('per term',
                      style: LandingBrand.body(
                          size: 14, color: LandingBrand.ink2)),
                  const SizedBox(height: 16),
                  _row(Icons.event_available_outlined,
                      '$sessions meetings of 1.5 hours ($hours hours in total)'),
                  _row(Icons.calendar_month_outlined,
                      'Valid for 2 months from the first class'),
                  _row(Icons.groups_outlined, '6–8 students per class'),
                  const SizedBox(height: 8),
                  Text(note,
                      style: LandingBrand.body(
                          size: 14.5, color: LandingBrand.ink2)),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _BrandButton(
                      label: 'Start learning',
                      tone: highlight ? _Tone.teal : _Tone.white,
                      onPressed: onPressed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: LandingBrand.card(liftBy: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LandingBrand.yellow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LandingBrand.black, width: 2),
            ),
            child: Icon(icon, color: LandingBrand.teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: LandingBrand.display(size: 18, height: 1.15)),
                const SizedBox(height: 4),
                Text(body,
                    style: LandingBrand.body(
                        size: 14, color: LandingBrand.ink2, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Get the app (web only)
// ---------------------------------------------------------------------------

class _DownloadAppSection extends StatelessWidget {
  const _DownloadAppSection();

  Future<void> _openApk(BuildContext context) async {
    if (!AppConstants.hasAndroidApk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Android download will be available soon.')),
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
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Install on iPhone or iPad',
                style: LandingBrand.display(size: 22, height: 1.1)),
            const SizedBox(height: 16),
            const _IosStep(number: '1', text: 'Open this page in Safari.'),
            const _IosStep(
                number: '2', text: 'Tap Share → "Add to Home Screen".'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      vertical: 48,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: LandingBrand.card(),
        child: Column(
          children: [
            Text('Learn on your phone',
                style: LandingBrand.display(size: 30, height: 1.1)),
            const SizedBox(height: 8),
            Text(
              'Install Easy Study on Android, or add it to your iPhone home screen from Safari.',
              textAlign: TextAlign.center,
              style: LandingBrand.body(size: 15, color: LandingBrand.ink2),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: [
                _BrandButton(
                  label: 'Download for Android',
                  icon: Icons.android,
                  onPressed: () => _openApk(context),
                ),
                _BrandButton(
                  label: 'Install on iPhone',
                  icon: Icons.phone_iphone,
                  tone: _Tone.white,
                  onPressed: () => _showIosInstructions(context),
                ),
              ],
            ),
          ],
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
            radius: 13,
            backgroundColor: LandingBrand.teal,
            child: Text(
              number,
              style: LandingBrand.display(
                  size: 14, color: LandingBrand.white, height: 1.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: LandingBrand.body(size: 15))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA + footer
// ---------------------------------------------------------------------------

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _midBreak;
    final title = RichText(
      text: TextSpan(
        style: LandingBrand.display(size: wide ? 40 : 30, height: 1.05),
        children: [
          const TextSpan(text: 'Ready for your first '),
          TextSpan(
              text: '字',
              style: LandingBrand.han(
                  size: wide ? 44 : 34, color: LandingBrand.green)),
          const TextSpan(text: '?'),
        ],
      ),
    );
    final buttons = Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _BrandButton(
            label: 'Create a free account',
            onPressed: () => context.push('/register')),
        _BrandButton(
            label: 'Sign in',
            tone: _Tone.white,
            onPressed: () => context.push(_signInRoute)),
      ],
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: LandingBrand.black, width: 3)),
      ),
      child: _Section(
        color: LandingBrand.yellow,
        vertical: 44,
        child: Row(
          children: [
            Transform.rotate(
              angle: -8 * math.pi / 180,
              child: Image.asset(
                'assets/brand/mascot_pencil.png',
                height: wide ? 150 : 100,
                fit: BoxFit.fitHeight,
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 16), buttons],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    return _Section(
      color: LandingBrand.black,
      vertical: 28,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 28,
        runSpacing: 14,
        children: [
          Image.asset(
            'assets/brand/mascot_writing.png',
            height: 32,
            fit: BoxFit.fitHeight,
            semanticLabel: '易华文教中心',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jl. Manyar Tirtomoyo 7/11, Surabaya · Phone 0823-3383-6362 · Instagram @easystudy.sby',
                style:
                    LandingBrand.body(size: 13, color: const Color(0xFFE6ECE9)),
              ),
              Text(
                'Mandarin Education Center & China Education Consultant · '
                '© ${DateTime.now().year} Easy Study',
                style:
                    LandingBrand.body(size: 13, color: const Color(0xFFB8C4BE)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
