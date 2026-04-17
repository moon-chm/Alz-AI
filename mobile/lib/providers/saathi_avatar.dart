import 'dart:math';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saathi_avatar.g.dart';

class SaathiAvatarPainter extends CustomPainter {
  final double breathPhase;
  final List<double> amplitudes;

  SaathiAvatarPainter(this.breathPhase, this.amplitudes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 3;

    // Breath rings
    final phaseOffsets = [0.0, 0.3, 0.6];
    for (var i = 0; i < phaseOffsets.length; i++) {
      final shiftedPhase = (breathPhase + phaseOffsets[i]) % 1.0;
      final radius = baseRadius + (sin(shiftedPhase * 2 * pi) * 15);
      final opacity = (1.0 - shiftedPhase).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = const Color(0xFF1A73E8).withOpacity(opacity * 0.4)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(center, radius, paint);
    }

    // Decibel visualizer (max 30 bars)
    if (amplitudes.isEmpty) return;
    final maxBars = 30;
    final sweepAngle = (2 * pi) / maxBars;
    final gap = 0.05;

    for (var i = 0; i < amplitudes.length && i < maxBars; i++) {
      final dynamicStroke = 2.0 + (amplitudes[i].clamp(0.0, 1.0) * 12.0);
      
      final arcPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = dynamicStroke
        ..strokeCap = StrokeCap.round;

      final startAngle = (i * sweepAngle) - (pi / 2); // Start at top
      final rect = Rect.fromCircle(center: center, radius: baseRadius + 25);
      canvas.drawArc(rect, startAngle + gap, sweepAngle - (gap * 2), false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SaathiAvatarPainter oldDelegate) {
    return oldDelegate.breathPhase != breathPhase || oldDelegate.amplitudes != amplitudes;
  }
}

@riverpod
class SaathiAvatarController extends _$SaathiAvatarController {
  @override
  List<double> build() => List.filled(30, 0.0);

  void addDecibelSample(double normalizedDecibel) {
    if (state.length >= 30) {
      state = [...state.skip(1), normalizedDecibel];
    } else {
      state = [...state, normalizedDecibel];
    }
  }
}
