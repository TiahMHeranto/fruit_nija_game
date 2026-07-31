import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.highScore = 0});

  final int highScore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final result = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameScreen(highScore: widget.highScore),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(highScore: max(widget.highScore, result)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _DojoBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = Curves.easeInOut.transform(_pulse.value);
                      return Transform.translate(
                        offset: Offset(0, -6 * t),
                        child: child,
                      );
                    },
                    child: const _BrandMark(),
                  ),
                  const Spacer(),
                  Text(
                    'Swipe to slice. Avoid bombs.\nDon\'t let fruit fall!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      height: 1.4,
                      color: AppColors.cream.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.highScore > 0)
                    Text(
                      'Best score  ${widget.highScore}',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: AppColors.scoreGold,
                      ),
                    ),
                  const SizedBox(height: 28),
                  ScaleTransition(
                    scale: Tween(begin: 0.96, end: 1.04).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: ElevatedButton(
                      onPressed: _play,
                      child: const Text('PLAY'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'FRUIT NINJA',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.cream,
            height: 1,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'TiahM',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            height: 1,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        CustomPaint(
          size: const Size(220, 90),
          painter: _TitleFruitPainter(),
        ),
      ],
    );
  }
}

class _DojoBackdrop extends StatelessWidget {
  const _DojoBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DojoPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _DojoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [
            AppColors.backgroundTop,
            AppColors.backgroundMid,
            AppColors.backgroundBottom,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Soft light shaft
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.28),
          size.shortestSide * 0.7,
          [
            AppColors.accent.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
    );

    // Decorative slash
    final slash = Path()
      ..moveTo(size.width * 0.15, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.36,
        size.width * 0.88,
        size.height * 0.48,
      );
    canvas.drawPath(
      slash,
      Paint()
        ..color = AppColors.blade.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TitleFruitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Watermelon
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.55),
      28,
      Paint()..color = const Color(0xFF2E7D32),
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.55),
      18,
      Paint()..color = const Color(0xFFE91E63),
    );

    // Orange
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.4),
      22,
      Paint()..color = const Color(0xFFFF9800),
    );

    // Apple
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.58),
      20,
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.58 - 18),
      Offset(size.width * 0.8, size.height * 0.58 - 28),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
