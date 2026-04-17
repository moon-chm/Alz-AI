import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/config/theme.dart';

class SAATHISpeaking extends StatelessWidget {
  const SAATHISpeaking({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(), delay: (index * 200).ms)
          .scaleXY(begin: 0.5, end: 1.5, duration: 600.ms, curve: Curves.easeInOut)
          .then()
          .scaleXY(begin: 1.5, end: 0.5, duration: 600.ms, curve: Curves.easeInOut)
          .fade(begin: 0.5, end: 1.0)
          .then()
          .fade(begin: 1.0, end: 0.5);
        }),
      ),
    );
  }
}
