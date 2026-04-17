import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Premium Page Transition combining a subtle fade and a gentle upward slide.
/// 
/// Specs: 
/// - Duration: 300ms
/// - Curve: easeOutCubic
/// - Motion: 20px upward slide
class PremiumPageTransition extends CustomTransitionPage<void> {
  PremiumPageTransition({
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId,
          child: child,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade Animation
            final opacityTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            final slideTween = Tween<double>(
              begin: 20.0, // 20px downward
              end: 0.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return FadeTransition(
              opacity: animation.drive(opacityTween),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, staticChild) {
                  return Transform.translate(
                    offset: Offset(0, slideTween.evaluate(animation)),
                    child: staticChild,
                  );
                },
                child: child,
              ),
            );
          },
        );
}

// Deprecated: Use PremiumPageTransition instead
@Deprecated('Use PremiumPageTransition')
class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({required super.child, super.key})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

// Deprecated: Use PremiumPageTransition instead
@Deprecated('Use PremiumPageTransition')
class SlideUpTransition extends CustomTransitionPage<void> {
  SlideUpTransition({required super.child, super.key})
      : super(
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.ease;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}
