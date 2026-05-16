// ============================================================
// RailGuide — App Theme
// utils/app_theme.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color railwayBlue      = Color(0xFF0A2463);
  static const Color railwayBlueMid   = Color(0xFF1B4B8E);
  static const Color railwayBlueLight = Color(0xFF2E6AC8);
  static const Color safetyYellow     = Color(0xFFFFD700);
  static const Color safetyYellowSoft = Color(0xFFFFF0A0);
  static const Color scaffoldBg       = Color(0xFFF0F4FF);
  static const Color cardBg           = Color(0xFFFFFFFF);
  static const Color textPrimary      = Color(0xFF0A2463);
  static const Color textSecondary    = Color(0xFF4A5568);
  static const Color textLight        = Color(0xFF718096);
  static const Color success          = Color(0xFF22C55E);
  static const Color warning          = Color(0xFFF59E0B);
  static const Color error            = Color(0xFFEF4444);

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.rajdhani(
        fontSize: 48, fontWeight: FontWeight.w700,
        color: railwayBlue, letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.rajdhani(
        fontSize: 36, fontWeight: FontWeight.w700, color: railwayBlue,
      ),
      headlineLarge: GoogleFonts.rajdhani(
        fontSize: 28, fontWeight: FontWeight.w700, color: railwayBlue,
      ),
      headlineMedium: GoogleFonts.rajdhani(
        fontSize: 22, fontWeight: FontWeight.w600, color: railwayBlue,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: railwayBlue,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: textLight,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: railwayBlue,
        primary: railwayBlue,
        secondary: safetyYellow,
        surface: cardBg,
        // ← 'background' was removed in Flutter 3.18; use 'surface' instead
        onPrimary: Colors.white,
        onSecondary: railwayBlue,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: _buildTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: railwayBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: 0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: safetyYellow,
          foregroundColor: railwayBlue,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: railwayBlue,
          side: const BorderSide(color: railwayBlue, width: 2),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: railwayBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: GoogleFonts.inter(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),

      // ← Fixed: use CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: railwayBlue,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: safetyYellowSoft,
        labelStyle: GoogleFonts.inter(
          color: railwayBlue, fontWeight: FontWeight.w600, fontSize: 12,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}