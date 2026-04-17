import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/providers/patient_provider.dart';

part 'cognitive_theme.g.dart';

enum CognitiveLevel { mild, moderate, severe }

class CognitiveTheme extends ThemeExtension<CognitiveTheme> {
  final double surfaceContrast;
  final double iconSize;
  final bool messageSimplicity;
  final double animationScale;
  final double tapTargetSize;

  const CognitiveTheme({
    required this.surfaceContrast,
    required this.iconSize,
    required this.messageSimplicity,
    required this.animationScale,
    required this.tapTargetSize,
  });

  @override
  ThemeExtension<CognitiveTheme> copyWith({
    double? surfaceContrast,
    double? iconSize,
    bool? messageSimplicity,
    double? animationScale,
    double? tapTargetSize,
  }) {
    return CognitiveTheme(
      surfaceContrast: surfaceContrast ?? this.surfaceContrast,
      iconSize: iconSize ?? this.iconSize,
      messageSimplicity: messageSimplicity ?? this.messageSimplicity,
      animationScale: animationScale ?? this.animationScale,
      tapTargetSize: tapTargetSize ?? this.tapTargetSize,
    );
  }

  @override
  ThemeExtension<CognitiveTheme> lerp(ThemeExtension<CognitiveTheme>? other, double t) {
    if (other is! CognitiveTheme) return this;
    return CognitiveTheme(
      surfaceContrast: lerpDouble(surfaceContrast, other.surfaceContrast, t) ?? surfaceContrast,
      iconSize: lerpDouble(iconSize, other.iconSize, t) ?? iconSize,
      messageSimplicity: t < 0.5 ? messageSimplicity : other.messageSimplicity,
      animationScale: lerpDouble(animationScale, other.animationScale, t) ?? animationScale,
      tapTargetSize: lerpDouble(tapTargetSize, other.tapTargetSize, t) ?? tapTargetSize,
    );
  }

  double lerpDouble(num a, num b, double t) => a + (b - a) * t;
}

@riverpod
ThemeData cognitiveTheme(CognitiveThemeRef ref) {
  final level = CognitiveLevel.mild; // Default to mild until provider is implemented
  
  final cognitiveExt = switch (level) {
    CognitiveLevel.mild => const CognitiveTheme(
        surfaceContrast: 0.1, iconSize: 24.0, messageSimplicity: false, animationScale: 1.0, tapTargetSize: 48.0),
    CognitiveLevel.moderate => const CognitiveTheme(
        surfaceContrast: 0.2, iconSize: 32.0, messageSimplicity: true, animationScale: 1.5, tapTargetSize: 64.0),
    CognitiveLevel.severe => const CognitiveTheme(
        surfaceContrast: 0.3, iconSize: 48.0, messageSimplicity: true, animationScale: 2.5, tapTargetSize: 80.0),
  };

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
    extensions: [cognitiveExt],
    textTheme: TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, height: 1.4, letterSpacing: -0.5),
      displayMedium: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700, height: 1.4, letterSpacing: -0.2),
      displaySmall: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, height: 1.4, letterSpacing: 0),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, height: 1.5, letterSpacing: 0.1),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, height: 1.5, letterSpacing: 0.15),
      headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, height: 1.5, letterSpacing: 0.2),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0),
      titleMedium: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.15),
      titleSmall: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w400, height: 1.6, letterSpacing: 0.5),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, letterSpacing: 0.25),
      bodySmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6, letterSpacing: 0.4),
      labelLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.1),
      labelMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.5),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5, letterSpacing: 0.5),
    ),
  );
}
