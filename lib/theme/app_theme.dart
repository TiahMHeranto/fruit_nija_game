import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const backgroundTop = Color(0xFF1A0A05);
  static const backgroundMid = Color(0xFF3D1808);
  static const backgroundBottom = Color(0xFF6B2D0A);
  static const woodDark = Color(0xFF2A1408);
  static const woodLight = Color(0xFF4A2810);
  static const accent = Color(0xFFE8A317);
  static const accentHot = Color(0xFFFF5A1F);
  static const leaf = Color(0xFF4CAF50);
  static const cream = Color(0xFFFFF4E0);
  static const scoreGold = Color(0xFFFFD54F);
  static const danger = Color(0xFFE53935);
  static const blade = Color(0xFFE0F7FA);
  static const bladeCore = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundTop,
      textTheme: GoogleFonts.fredokaTextTheme(base.textTheme).apply(
        bodyColor: AppColors.cream,
        displayColor: AppColors.cream,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.woodDark,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
