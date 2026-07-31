import 'dart:math';
import 'dart:ui';

import '../models/game_models.dart';

class GameConfig {
  static const gravity = 980.0;
  static const maxLives = 3;
  static const bladeTrailMs = 140;
  static const comboWindowMs = 700;
  static const maxBladePoints = 18;
  static const fruitSpawnIntervalStart = 1.05;
  static const fruitSpawnIntervalMin = 0.42;
  static const bombChanceStart = 0.08;
  static const bombChanceMax = 0.28;
}

enum PlayPhase { idle, playing, paused, gameOver }

class GameSnapshot {
  const GameSnapshot({
    required this.objects,
    required this.particles,
    required this.blade,
    required this.popups,
    required this.score,
    required this.highScore,
    required this.lives,
    required this.combo,
    required this.maxCombo,
    required this.phase,
    required this.elapsed,
    required this.flashAlpha,
    required this.waveLabel,
  });

  final List<GameObject> objects;
  final List<Particle> particles;
  final List<BladePoint> blade;
  final List<ScorePopup> popups;
  final int score;
  final int highScore;
  final int lives;
  final int combo;
  final int maxCombo;
  final PlayPhase phase;
  final double elapsed;
  final double flashAlpha;
  final String? waveLabel;
}

class GameEngine {
  GameEngine({required this.size, this.highScore = 0}) {
    _rng = Random();
  }

  Size size;
  int highScore;
  late Random _rng;

  final List<GameObject> objects = [];
  final List<Particle> particles = [];
  final List<BladePoint> blade = [];
  final List<ScorePopup> popups = [];

  int score = 0;
  int lives = GameConfig.maxLives;
  int combo = 0;
  int maxCombo = 0;
  int _nextId = 1;
  double elapsed = 0;
  double _spawnTimer = 0;
  double _flashAlpha = 0;
  DateTime? _lastSliceAt;
  String? _waveLabel;
  double _waveLabelTimer = 0;
  PlayPhase phase = PlayPhase.idle;
  bool _wasSlicing = false;

  double get difficulty => (elapsed / 60).clamp(0.0, 1.0);

  double get spawnInterval {
    final t = GameConfig.fruitSpawnIntervalStart -
        (GameConfig.fruitSpawnIntervalStart - GameConfig.fruitSpawnIntervalMin) *
            difficulty;
    return t;
  }

  double get bombChance =>
      GameConfig.bombChanceStart +
      (GameConfig.bombChanceMax - GameConfig.bombChanceStart) * difficulty;

  GameSnapshot snapshot() => GameSnapshot(
        objects: List.unmodifiable(objects),
        particles: List.unmodifiable(particles),
        blade: List.unmodifiable(blade),
        popups: List.unmodifiable(popups),
        score: score,
        highScore: highScore,
        lives: lives,
        combo: combo,
        maxCombo: maxCombo,
        phase: phase,
        elapsed: elapsed,
        flashAlpha: _flashAlpha,
        waveLabel: _waveLabel,
      );

  void start() {
    objects.clear();
    particles.clear();
    blade.clear();
    popups.clear();
    score = 0;
    lives = GameConfig.maxLives;
    combo = 0;
    maxCombo = 0;
    elapsed = 0;
    _spawnTimer = 0.35;
    _flashAlpha = 0;
    _lastSliceAt = null;
    _waveLabel = 'SLICE!';
    _waveLabelTimer = 1.4;
    phase = PlayPhase.playing;
    _wasSlicing = false;
  }

  void pause() {
    if (phase == PlayPhase.playing) phase = PlayPhase.paused;
  }

  void resume() {
    if (phase == PlayPhase.paused) phase = PlayPhase.playing;
  }

  void update(double dt) {
    if (phase != PlayPhase.playing) return;

    elapsed += dt;
    _flashAlpha = (_flashAlpha - dt * 2.2).clamp(0.0, 1.0);

    if (_waveLabelTimer > 0) {
      _waveLabelTimer -= dt;
      if (_waveLabelTimer <= 0) _waveLabel = null;
    }

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnWave();
      _spawnTimer = spawnInterval * (0.75 + _rng.nextDouble() * 0.5);
    }

    _updatePhysics(dt);
    _updateParticles(dt);
    _pruneBlade();
    _prunePopups();
    _checkMisses();
  }

  void onPointerDown(Offset p) {
    if (phase != PlayPhase.playing) return;
    blade.clear();
    blade.add(BladePoint(p, DateTime.now()));
    _wasSlicing = true;
  }

  void onPointerMove(Offset p) {
    if (phase != PlayPhase.playing || !_wasSlicing) return;
    if (blade.isNotEmpty) {
      final last = blade.last.offset;
      if ((p - last).distance < 4) return;
    }
    blade.add(BladePoint(p, DateTime.now()));
    while (blade.length > GameConfig.maxBladePoints) {
      blade.removeAt(0);
    }
    _trySlice(p);
  }

  void onPointerUp() {
    _wasSlicing = false;
    // Keep trail briefly; pruned by age.
  }

  void _spawnWave() {
    final bombRoll = _rng.nextDouble() < bombChance;
    final count = bombRoll
        ? 1
        : 1 + _rng.nextInt(1 + (difficulty * 3).floor().clamp(0, 3));

    for (var i = 0; i < count; i++) {
      final isBomb = bombRoll && i == 0 && _rng.nextBool() ||
          (!bombRoll && _rng.nextDouble() < bombChance * 0.35);
      objects.add(_createThrowable(isBomb: isBomb, stagger: i * 0.08));
    }

    if (elapsed > 20 && (elapsed % 20) < spawnInterval) {
      _waveLabel = 'FASTER!';
      _waveLabelTimer = 1.2;
    }
  }

  GameObject _createThrowable({required bool isBomb, double stagger = 0}) {
    final margin = size.width * 0.12;
    final x = margin + _rng.nextDouble() * (size.width - margin * 2);
    final startY = size.height + 40 + stagger * 200;

    final upward = -(720 + _rng.nextDouble() * 280 + difficulty * 120);
    final towardCenter = (size.width / 2 - x) * (0.35 + _rng.nextDouble() * 0.45);
    final vx = towardCenter + (_rng.nextDouble() - 0.5) * 160;

    if (isBomb) {
      return GameObject(
        id: _nextId++,
        kind: ThrowableKind.bomb,
        position: Offset(x, startY),
        velocity: Offset(vx, upward),
        radius: 32,
        rotation: _rng.nextDouble() * pi * 2,
        angularVelocity: (_rng.nextDouble() - 0.5) * 6,
      );
    }

    final type = FruitType.random(_rng);
    return GameObject(
      id: _nextId++,
      kind: ThrowableKind.fruit,
      fruitType: type,
      position: Offset(x, startY),
      velocity: Offset(vx, upward),
      radius: type.radius,
      rotation: _rng.nextDouble() * pi * 2,
      angularVelocity: (_rng.nextDouble() - 0.5) * 8,
    );
  }

  void _updatePhysics(double dt) {
    for (final o in objects) {
      if (!o.isAlive && o.sliced) {
        o.velocity += Offset(0, GameConfig.gravity * dt);
        o.position += o.velocity * dt;
        o.halfOffset += Offset(
          (o.sliceNormal?.dy ?? 0) * 40 * dt,
          -(o.sliceNormal?.dx ?? 0) * 40 * dt,
        );
        o.rotation += o.angularVelocity * dt;
        continue;
      }
      if (!o.isAlive) continue;

      o.velocity += Offset(0, GameConfig.gravity * dt);
      o.position += o.velocity * dt;
      o.rotation += o.angularVelocity * dt;
    }

    objects.removeWhere(
      (o) => o.position.dy > size.height + 120 || (o.sliced && o.position.dy > size.height + 40),
    );
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.life -= dt;
      p.velocity += Offset(0, 420 * dt);
      p.position += p.velocity * dt;
      p.size *= 0.992;
    }
    particles.removeWhere((p) => p.isDead);
  }

  void _pruneBlade() {
    final now = DateTime.now();
    blade.removeWhere(
      (b) => now.difference(b.bornAt).inMilliseconds > GameConfig.bladeTrailMs,
    );
  }

  void _prunePopups() {
    final now = DateTime.now();
    popups.removeWhere((p) => p.ageMs(now) > 900);
  }

  void _checkMisses() {
    for (final o in objects) {
      if (!o.isAlive || !o.isFruit) continue;
      if (o.position.dy > size.height + 30 && o.velocity.dy > 0) {
        o.missed = true;
        lives = (lives - 1).clamp(0, GameConfig.maxLives);
        combo = 0;
        _flashAlpha = 0.45;
        if (lives <= 0) _endGame();
      }
    }
  }

  void _trySlice(Offset tip) {
    if (blade.length < 2) return;
    final prev = blade[blade.length - 2].offset;
    final segment = tip - prev;
    if (segment.distance < 2) return;

    for (final o in objects) {
      if (!o.isAlive) continue;
      if (!_segmentHitsCircle(prev, tip, o.position, o.radius * 0.92)) continue;

      if (o.isBomb) {
        _sliceBomb(o, segment);
        return;
      }
      _sliceFruit(o, segment);
    }
  }

  bool _segmentHitsCircle(Offset a, Offset b, Offset c, double r) {
    final ab = b - a;
    final t = ((c - a).dx * ab.dx + (c - a).dy * ab.dy) /
        (ab.dx * ab.dx + ab.dy * ab.dy).clamp(0.0001, double.infinity);
    final closest = a + ab * t.clamp(0.0, 1.0);
    return (closest - c).distance <= r;
  }

  void _sliceFruit(GameObject o, Offset slash) {
    o.sliced = true;
    final n = Offset(-slash.dy, slash.dx);
    final len = n.distance;
    o.sliceNormal = len > 0 ? n / len : const Offset(1, 0);
    o.angularVelocity = (o.angularVelocity.abs() + 8) * (o.angularVelocity >= 0 ? 1 : -1);
    o.velocity += Offset(slash.dx * 0.15, -80);

    final now = DateTime.now();
    if (_lastSliceAt != null &&
        now.difference(_lastSliceAt!).inMilliseconds < GameConfig.comboWindowMs) {
      combo += 1;
    } else {
      combo = 1;
    }
    _lastSliceAt = now;
    if (combo > maxCombo) maxCombo = combo;

    final base = o.fruitType?.points ?? 1;
    final gain = base * (combo >= 3 ? combo : 1);
    score += gain;
    if (score > highScore) highScore = score;

    popups.add(
      ScorePopup(
        position: o.position - const Offset(0, 40),
        text: combo >= 3 ? '+$gain COMBO x$combo' : '+$gain',
        bornAt: now,
      ),
    );

    _emitJuice(o);
  }

  void _sliceBomb(GameObject o, Offset slash) {
    o.sliced = true;
    final n = Offset(-slash.dy, slash.dx);
    final len = n.distance;
    o.sliceNormal = len > 0 ? n / len : const Offset(1, 0);
    _emitExplosion(o.position);
    _flashAlpha = 1;
    lives = 0;
    _endGame();
  }

  void _emitJuice(GameObject o) {
    final color = o.fruitType?.juice ?? const Color(0xFFFFEB3B);
    final fill = o.fruitType?.fill ?? const Color(0xFFE53935);
    for (var i = 0; i < 18; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 120 + _rng.nextDouble() * 280;
      particles.add(
        Particle(
          position: o.position,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - 80),
          color: i.isEven ? color : fill,
          life: 0.35 + _rng.nextDouble() * 0.45,
          maxLife: 0.8,
          size: 3 + _rng.nextDouble() * 7,
        ),
      );
    }
  }

  void _emitExplosion(Offset at) {
    for (var i = 0; i < 40; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 80 + _rng.nextDouble() * 420;
      particles.add(
        Particle(
          position: at,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: i.isEven ? const Color(0xFFFF5722) : const Color(0xFFFFEB3B),
          life: 0.4 + _rng.nextDouble() * 0.5,
          maxLife: 0.9,
          size: 4 + _rng.nextDouble() * 10,
        ),
      );
    }
  }

  void _endGame() {
    phase = PlayPhase.gameOver;
    if (score > highScore) highScore = score;
  }
}
