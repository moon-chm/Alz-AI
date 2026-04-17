import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PulseAnimation extends StatelessWidget {
  final Widget child;
  final Color color;
  final double size;
  final bool isPulsing;

  const PulseAnimation({
    Key? key,
    required this.child,
    required this.color,
    this.size = 100,
    this.isPulsing = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isPulsing) return child;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Center(
        child: child,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            duration: const Duration(seconds: 2))
        .fade(begin: 1.0, end: 0.0, duration: const Duration(seconds: 2));
  }
}
