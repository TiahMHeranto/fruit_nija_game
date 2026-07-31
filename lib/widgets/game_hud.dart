import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.highScore,
    required this.lives,
    required this.combo,
    required this.waveLabel,
    required this.onPause,
  });

  final int score;
  final int highScore;
  final int lives;
  final int combo;
  final String? waveLabel;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreBlock(score: score, highScore: highScore),
                const Spacer(),
                _LivesRow(lives: lives),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onPause,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                  ),
                  icon: const Icon(Icons.pause_rounded, color: AppColors.cream),
                ),
              ],
            ),
            if (combo >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'COMBO x$combo',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.scoreGold,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            if (waveLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  waveLabel!,
                  style: GoogleFonts.fredoka(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 3)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.score, required this.highScore});

  final int score;
  final int highScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCORE',
          style: GoogleFonts.fredoka(
            fontSize: 12,
            letterSpacing: 1.2,
            color: AppColors.cream.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '$score',
          style: GoogleFonts.fredoka(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.scoreGold,
            height: 1,
          ),
        ),
        Text(
          'BEST $highScore',
          style: GoogleFonts.fredoka(
            fontSize: 13,
            color: AppColors.cream.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.lives});

  final int lives;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final alive = i < lives;
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(
            Icons.favorite_rounded,
            size: 28,
            color: alive ? AppColors.danger : Colors.white24,
          ),
        );
      }),
    );
  }
}
