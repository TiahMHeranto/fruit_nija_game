import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../../theme/app_theme.dart';

class GamePainter extends CustomPainter {
  GamePainter({required this.snapshot, required this.now});

  final GameSnapshot snapshot;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintParticles(canvas);
    for (final o in snapshot.objects) {
      if (o.sliced) {
        _paintSliced(canvas, o);
      } else if (o.isAlive) {
        if (o.isBomb) {
          _paintBomb(canvas, o);
        } else {
          _paintFruit(canvas, o);
        }
      }
    }
    _paintBlade(canvas);
    _paintPopups(canvas);
    if (snapshot.flashAlpha > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = AppColors.danger.withValues(alpha: snapshot.flashAlpha * 0.55),
      );
    }
  }

  void _paintBackground(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [
          AppColors.backgroundTop,
          AppColors.backgroundMid,
          AppColors.backgroundBottom,
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bg);

    // Wooden dojo floor hint
    final floorY = size.height * 0.92;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
      Paint()..color = AppColors.woodDark.withValues(alpha: 0.55),
    );

    // Soft vignette
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height * 0.4),
          size.shortestSide * 0.85,
          [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
    );
  }

  void _paintFruit(Canvas canvas, GameObject o) {
    canvas.save();
    canvas.translate(o.position.dx, o.position.dy);
    canvas.rotate(o.rotation);

    final type = o.fruitType!;
    switch (type.kind) {
      case FruitKind.banana:
        _drawBanana(canvas, type);
      case FruitKind.strawberry:
        _drawStrawberry(canvas, type);
      case FruitKind.watermelon:
        _drawWatermelon(canvas, type);
      default:
        _drawRoundFruit(canvas, type);
    }

    canvas.restore();
  }

  void _drawRoundFruit(Canvas canvas, FruitType type) {
    final r = type.radius;
    final glow = Paint()
      ..color = type.fill.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, r + 4, glow);

    final body = Paint()
      ..shader = ui.Gradient.radial(
        Offset(-r * 0.3, -r * 0.35),
        r * 1.2,
        [Color.lerp(type.fill, Colors.white, 0.25)!, type.fill, type.accent],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(Offset.zero, r, body);

    // Leaf / stem
    final stem = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, -r + 2), Offset(2, -r - 8), stem);

    final leaf = Path()
      ..moveTo(2, -r - 4)
      ..quadraticBezierTo(16, -r - 14, 18, -r + 2)
      ..quadraticBezierTo(8, -r - 2, 2, -r - 4);
    canvas.drawPath(leaf, Paint()..color = AppColors.leaf);

    // Specular
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-r * 0.35, -r * 0.35), width: r * 0.35, height: r * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    if (type.kind == FruitKind.kiwi) {
      canvas.drawCircle(Offset.zero, r * 0.55, Paint()..color = const Color(0xFFC0CA33));
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        canvas.drawCircle(
          Offset(cos(a) * r * 0.25, sin(a) * r * 0.25),
          1.8,
          Paint()..color = const Color(0xFF3E2723),
        );
      }
    }

    if (type.kind == FruitKind.orange) {
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3;
        canvas.drawLine(
          Offset.zero,
          Offset(cos(a) * r * 0.85, sin(a) * r * 0.85),
          Paint()
            ..color = type.accent.withValues(alpha: 0.25)
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawWatermelon(Canvas canvas, FruitType type) {
    final r = type.radius;
    canvas.drawCircle(
      Offset.zero,
      r + 3,
      Paint()
        ..color = type.fill.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.25, -r * 0.3),
          r,
          [const Color(0xFF66BB6A), type.fill, type.accent],
          const [0.0, 0.45, 1.0],
        ),
    );
    for (var i = -2; i <= 2; i++) {
      final path = Path()
        ..moveTo(-r * 0.85, i * 10.0)
        ..quadraticBezierTo(0, i * 10.0 + 6, r * 0.85, i * 10.0);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF1B5E20).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawBanana(Canvas canvas, FruitType type) {
    final path = Path()
      ..moveTo(-22, 8)
      ..quadraticBezierTo(-10, -28, 18, -18)
      ..quadraticBezierTo(28, -12, 24, 4)
      ..quadraticBezierTo(8, 22, -18, 16)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(-20, -20),
          const Offset(20, 20),
          [Color.lerp(type.fill, Colors.white, 0.2)!, type.fill, type.accent],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = type.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawStrawberry(Canvas canvas, FruitType type) {
    final path = Path()
      ..moveTo(0, -22)
      ..cubicTo(22, -18, 24, 8, 0, 26)
      ..cubicTo(-24, 8, -22, -18, 0, -22)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(-6, -6),
          30,
          [Color.lerp(type.fill, Colors.white, 0.2)!, type.fill, type.accent],
          const [0.0, 0.5, 1.0],
        ),
    );
    for (var i = 0; i < 9; i++) {
      final x = ((i % 3) - 1) * 8.0;
      final y = (i ~/ 3) * 10.0 - 4;
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white70);
    }
    final leaf = Path()
      ..moveTo(0, -20)
      ..lineTo(-10, -30)
      ..lineTo(-2, -22)
      ..lineTo(0, -32)
      ..lineTo(2, -22)
      ..lineTo(10, -30)
      ..close();
    canvas.drawPath(leaf, Paint()..color = AppColors.leaf);
  }

  void _paintBomb(Canvas canvas, GameObject o) {
    canvas.save();
    canvas.translate(o.position.dx, o.position.dy);
    canvas.rotate(o.rotation);

    canvas.drawCircle(
      Offset.zero,
      o.radius + 6,
      Paint()
        ..color = Colors.red.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawCircle(
      Offset.zero,
      o.radius,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-o.radius * 0.3, -o.radius * 0.3),
          o.radius,
          [const Color(0xFF616161), const Color(0xFF212121), Colors.black],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Fuse
    final fuse = Path()
      ..moveTo(0, -o.radius + 2)
      ..quadraticBezierTo(8, -o.radius - 10, 14, -o.radius - 18);
    canvas.drawPath(
      fuse,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Spark
    final sparkAt = Offset(14, -o.radius - 18);
    final sparkPaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(sparkAt, 4, sparkPaint);
    for (var i = 0; i < 5; i++) {
      final a = i * pi * 2 / 5 + o.rotation;
      canvas.drawLine(
        sparkAt,
        Offset(sparkAt.dx + cos(a) * 10, sparkAt.dy + sin(a) * 10),
        Paint()
          ..color = const Color(0xFFFF9800)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Skull-ish mark
    canvas.drawCircle(
      const Offset(0, -2),
      8,
      Paint()..color = const Color(0xFFB0BEC5),
    );
    canvas.drawCircle(const Offset(-3.5, -3), 2, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(3.5, -3), 2, Paint()..color = Colors.black);

    canvas.restore();
  }

  void _paintSliced(Canvas canvas, GameObject o) {
    final n = o.sliceNormal ?? const Offset(1, 0);
    final half = o.halfOffset;

    canvas.save();
    canvas.translate(o.position.dx - half.dx, o.position.dy - half.dy);
    canvas.rotate(o.rotation - 0.4);
    canvas.clipPath(_halfClip(-n, o.radius + 4));
    if (o.isBomb) {
      _paintBombBodyLocal(canvas, o.radius);
    } else {
      _paintFruitLocal(canvas, o);
    }
    canvas.restore();

    canvas.save();
    canvas.translate(o.position.dx + half.dx, o.position.dy + half.dy);
    canvas.rotate(o.rotation + 0.4);
    canvas.clipPath(_halfClip(n, o.radius + 4));
    if (o.isBomb) {
      _paintBombBodyLocal(canvas, o.radius);
    } else {
      _paintFruitLocal(canvas, o);
    }
    canvas.restore();
  }

  Path _halfClip(Offset n, double r) {
    final path = Path();
    final perp = Offset(-n.dy, n.dx);
    path.moveTo(n.dx * r * 2 + perp.dx * r * 2, n.dy * r * 2 + perp.dy * r * 2);
    path.lineTo(n.dx * r * 2 - perp.dx * r * 2, n.dy * r * 2 - perp.dy * r * 2);
    path.lineTo(-n.dx * r * 3 - perp.dx * r * 2, -n.dy * r * 3 - perp.dy * r * 2);
    path.lineTo(-n.dx * r * 3 + perp.dx * r * 2, -n.dy * r * 3 + perp.dy * r * 2);
    path.close();
    return path;
  }

  void _paintFruitLocal(Canvas canvas, GameObject o) {
    final type = o.fruitType!;
    canvas.save();
    switch (type.kind) {
      case FruitKind.banana:
        _drawBanana(canvas, type);
      case FruitKind.strawberry:
        _drawStrawberry(canvas, type);
      case FruitKind.watermelon:
        _drawWatermelon(canvas, type);
      default:
        _drawRoundFruit(canvas, type);
    }
    canvas.restore();
  }

  void _paintBombBodyLocal(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(-r * 0.3, -r * 0.3),
          r,
          [const Color(0xFF616161), const Color(0xFF212121), Colors.black],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  void _paintParticles(Canvas canvas) {
    for (final p in snapshot.particles) {
      final alpha = (1 - p.progress).clamp(0.0, 1.0);
      canvas.drawCircle(
        p.position,
        p.size,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  void _paintBlade(Canvas canvas) {
    final pts = snapshot.blade;
    if (pts.length < 2) return;

    final path = Path()..moveTo(pts.first.offset.dx, pts.first.offset.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].offset.dx, pts[i].offset.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.blade.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.bladeCore.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintPopups(Canvas canvas) {
    for (final p in snapshot.popups) {
      final age = p.ageMs(now);
      final t = (age / 900).clamp(0.0, 1.0);
      final alpha = (1 - t);
      final dy = -30 * t;
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: p.color.withValues(alpha: alpha),
            fontSize: 22 + (p.text.contains('COMBO') ? 4 : 0),
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: alpha * 0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p.position + Offset(-tp.width / 2, dy));
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
