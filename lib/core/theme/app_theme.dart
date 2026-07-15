import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get calculatorDark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 48),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 36),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00f0ff),
        secondary: Color(0xFFa855f7),
        surface: Color(0xFF16213e),
      ),
    );
  }

  static ThemeData get calculatorLight {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFf5f5f5),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w300, fontSize: 48),
          displayMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w300, fontSize: 36),
          bodyLarge: TextStyle(color: Colors.black87, fontSize: 18),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4ecdc4),
        secondary: Color(0xFF44a3aa),
        surface: Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData get bridgeTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0a0a0f),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          titleLarge: TextStyle(color: Color(0xFFf0f0f5), fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: TextStyle(color: Color(0xFFf0f0f5), fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: Color(0xFFf0f0f5), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF8a8a9a), fontSize: 14),
          bodySmall: TextStyle(color: Color(0xFF6a6a7a), fontSize: 12),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00f0ff),
        secondary: Color(0xFFa855f7),
        surface: Color(0xFF12121a),
        error: Color(0xFFef4444),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF12121a),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2a2a3a)),
        ),
      ),
    );
  }
}

double degreesToRadians(double degrees) => degrees * pi / 180;