import 'dart:math';
import 'dart:ui';

enum FruitKind { watermelon, apple, orange, banana, kiwi, strawberry, peach }

enum ThrowableKind { fruit, bomb }

class FruitType {
  const FruitType({
    required this.kind,
    required this.fill,
    required this.accent,
    required this.juice,
    required this.radius,
    required this.points,
  });

  final FruitKind kind;
  final Color fill;
  final Color accent;
  final Color juice;
  final double radius;
  final int points;

  static const List<FruitType> catalog = [
    FruitType(
      kind: FruitKind.watermelon,
      fill: Color(0xFF2E7D32),
      accent: Color(0xFF1B5E20),
      juice: Color(0xFFE91E63),
      radius: 38,
      points: 2,
    ),
    FruitType(
      kind: FruitKind.apple,
      fill: Color(0xFFE53935),
      accent: Color(0xFFB71C1C),
      juice: Color(0xFFFFCDD2),
      radius: 30,
      points: 1,
    ),
    FruitType(
      kind: FruitKind.orange,
      fill: Color(0xFFFF9800),
      accent: Color(0xFFE65100),
      juice: Color(0xFFFFE0B2),
      radius: 28,
      points: 1,
    ),
    FruitType(
      kind: FruitKind.banana,
      fill: Color(0xFFFFEB3B),
      accent: Color(0xFFF9A825),
      juice: Color(0xFFFFF9C4),
      radius: 26,
      points: 1,
    ),
    FruitType(
      kind: FruitKind.kiwi,
      fill: Color(0xFF8BC34A),
      accent: Color(0xFF827717),
      juice: Color(0xFFDCEDC8),
      radius: 26,
      points: 2,
    ),
    FruitType(
      kind: FruitKind.strawberry,
      fill: Color(0xFFFF1744),
      accent: Color(0xFFC62828),
      juice: Color(0xFFFF8A80),
      radius: 24,
      points: 3,
    ),
    FruitType(
      kind: FruitKind.peach,
      fill: Color(0xFFFFAB91),
      accent: Color(0xFFFF7043),
      juice: Color(0xFFFFCCBC),
      radius: 29,
      points: 1,
    ),
  ];

  static FruitType random(Random rng) => catalog[rng.nextInt(catalog.length)];
}

class GameObject {
  GameObject({
    required this.id,
    required this.kind,
    required this.position,
    required this.velocity,
    required this.radius,
    this.fruitType,
    this.rotation = 0,
    this.angularVelocity = 0,
    this.sliced = false,
    this.missed = false,
    this.sliceNormal,
    this.halfOffset = Offset.zero,
  });

  final int id;
  final ThrowableKind kind;
  final FruitType? fruitType;
  Offset position;
  Offset velocity;
  double radius;
  double rotation;
  double angularVelocity;
  bool sliced;
  bool missed;
  Offset? sliceNormal;
  Offset halfOffset;

  bool get isBomb => kind == ThrowableKind.bomb;
  bool get isFruit => kind == ThrowableKind.fruit;
  bool get isAlive => !sliced && !missed;

  Rect get bounds => Rect.fromCircle(center: position, radius: radius);
}

class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.maxLife,
    required this.size,
  });

  Offset position;
  Offset velocity;
  Color color;
  double life;
  final double maxLife;
  double size;

  double get progress => (1 - life / maxLife).clamp(0.0, 1.0);
  bool get isDead => life <= 0;
}

class BladePoint {
  BladePoint(this.offset, this.bornAt);

  final Offset offset;
  final DateTime bornAt;
}

class ScorePopup {
  ScorePopup({
    required this.position,
    required this.text,
    required this.bornAt,
    this.color = const Color(0xFFFFD54F),
  });

  final Offset position;
  final String text;
  final DateTime bornAt;
  final Color color;

  double ageMs(DateTime now) =>
      now.difference(bornAt).inMilliseconds.toDouble();
}
