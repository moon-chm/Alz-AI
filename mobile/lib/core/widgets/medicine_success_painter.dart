import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double radius;
  double opacity;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.opacity,
  });
}

class MedicineSuccessPainter extends CustomPainter {
  final List<Particle> particles;

  MedicineSuccessPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.position += p.velocity;
      p.velocity += const Offset(0, 0.3); // Gravity
      p.opacity -= 0.02;

      if (p.opacity <= 0) {
        particles.removeAt(i);
        continue;
      }

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MedicineSuccessPainter oldDelegate) => true;
}
