import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.maxCombo,
  });

  final int score;
  final int highScore;
  final int maxCombo;

  bool get isNewBest => score > 0 && score >= highScore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.backgroundMid,
              AppColors.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  'GAME OVER',
                  style: GoogleFonts.fredoka(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
                if (isNewBest) ...[
                  const SizedBox(height: 8),
                  Text(
                    'NEW BEST!',
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.scoreGold,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                _StatTile(label: 'Score', value: '$score'),
                const SizedBox(height: 12),
                _StatTile(label: 'Best', value: '$highScore'),
                const SizedBox(height: 12),
                _StatTile(label: 'Max combo', value: 'x$maxCombo'),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(highScore: highScore),
                      ),
                    );
                  },
                  child: const Text('PLAY AGAIN'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(highScore: highScore),
                      ),
                      (_) => false,
                    );
                  },
                  child: Text(
                    'Main menu',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      color: AppColors.cream.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              color: AppColors.cream.withValues(alpha: 0.75),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.scoreGold,
            ),
          ),
        ],
      ),
    );
  }
}
