import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF1A73E8);
  static const Color accent = Color(0xFFF57C00);
  static const Color green = Color(0xFF0F9D58);
  static const Color red = Color(0xFFE53935);
  static const Color navy = Color(0xFF0A0F2C);
  static const Color bg = Color(0xFFF8FAFF);
  static const Color card = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData light() {
    // NUCLEAR FIX: Removing GoogleFonts entirely to eliminate network painting blocks.
    // We will use standard system fonts for guaranteed stability.
    
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        color: AppColors.card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        labelStyle: const TextStyle(fontSize: 22),
        hintStyle: const TextStyle(fontSize: 22, color: Colors.grey),
      ),
    );
  }
}
