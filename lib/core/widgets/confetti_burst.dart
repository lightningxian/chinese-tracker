import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A short burst of falling confetti, drawn once when the widget appears.
/// Put it in a [Stack] over the content; it ignores pointer events and
/// fades out by itself after about two seconds.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 70});

  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _pieces = List.generate(widget.pieces, (_) => _Piece.random(random));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.teal,
      AppColors.brandYellow,
      AppColors.brandGreen,
      AppColors.navy,
      AppColors.success,
    ];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(
            pieces: _pieces,
            progress: _controller.value,
            colors: colors,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.colorIndex,
    required this.delay,
  });

  /// Start position across the width, 0 to 1.
  final double x;

  /// Launch direction in radians (up is -pi/2).
  final double angle;
  final double speed;
  final double spin;
  final double size;
  final int colorIndex;

  /// Fraction of the animation before this piece appears.
  final double delay;

  factory _Piece.random(Random random) => _Piece(
        x: 0.2 + random.nextDouble() * 0.6,
        angle: -pi / 2 + (random.nextDouble() - 0.5) * pi * 0.9,
        speed: 0.5 + random.nextDouble() * 0.7,
        spin: (random.nextDouble() - 0.5) * 12,
        size: 6 + random.nextDouble() * 6,
        colorIndex: random.nextInt(5),
        delay: random.nextDouble() * 0.15,
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.colors,
  });

  final List<_Piece> pieces;
  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final t = (progress - piece.delay) / (1 - piece.delay);
      if (t <= 0) continue;
      final launch = piece.speed * size.height * 0.9;
      final dx = cos(piece.angle) * launch * t;
      // Thrown up, then gravity wins.
      final dy = sin(piece.angle) * launch * t + size.height * 1.4 * t * t;
      final x = piece.x * size.width + dx;
      final y = size.height * 0.45 + dy;
      if (y > size.height + 20) continue;
      final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
      paint.color =
          colors[piece.colorIndex % colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.6,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
