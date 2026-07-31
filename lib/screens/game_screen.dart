import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/engine/game_engine.dart';
import '../game/high_score_store.dart';
import '../game/painters/game_painter.dart';
import '../theme/app_theme.dart';
import '../widgets/game_hud.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.highScore = 0});

  final int highScore;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  GameEngine? _engine;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  bool _navigatedToGameOver = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _ensureEngine(Size size) {
    if (_engine != null) {
      _engine!.size = size;
      return;
    }
    _engine = GameEngine(size: size, highScore: widget.highScore)..start();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final engine = _engine;
    if (engine == null) return;

    final dt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final clamped = dt.clamp(0.0, 1 / 20);

    engine.update(clamped);

    if (engine.phase == PlayPhase.gameOver && !_navigatedToGameOver) {
      _navigatedToGameOver = true;
      _ticker?.stop();
      _persistHighScore(engine.highScore);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => GameOverScreen(
              score: engine.score,
              highScore: engine.highScore,
              maxCombo: engine.maxCombo,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      });
    }

    if (mounted) setState(() {});
  }

  Future<void> _persistHighScore(int value) async {
    await HighScoreStore.save(value);
  }

  void _togglePause() {
    final engine = _engine;
    if (engine == null) return;
    if (engine.phase == PlayPhase.playing) {
      engine.pause();
      _ticker?.stop();
    } else if (engine.phase == PlayPhase.paused) {
      engine.resume();
      _lastTick = Duration.zero;
      _ticker?.start();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _ensureEngine(size);
          final engine = _engine!;
          final snap = engine.snapshot();

          return Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                onPointerDown: (e) => engine.onPointerDown(e.localPosition),
                onPointerMove: (e) => engine.onPointerMove(e.localPosition),
                onPointerUp: (_) => engine.onPointerUp(),
                onPointerCancel: (_) => engine.onPointerUp(),
                child: CustomPaint(
                  painter: GamePainter(snapshot: snap, now: DateTime.now()),
                  child: const SizedBox.expand(),
                ),
              ),
              GameHud(
                score: snap.score,
                highScore: snap.highScore,
                lives: snap.lives,
                combo: snap.combo,
                waveLabel: snap.waveLabel,
                onPause: _togglePause,
              ),
              if (snap.phase == PlayPhase.paused) _PauseOverlay(onResume: _togglePause),
            ],
          );
        },
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PAUSED',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.cream,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onResume,
              child: const Text('RESUME'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                'Quit to menu',
                style: TextStyle(color: AppColors.cream),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
