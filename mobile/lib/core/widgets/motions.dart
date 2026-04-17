import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A wrapper that fades in its child with an optional delay.
class FadeIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic);
  }
}

/// A wrapper that slides in its child from below with a fade.
/// Supports staggerIndex for sequential animations in a list or column.
class SlideUp extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final int? staggerIndex;

  const SlideUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 30.0,
    this.staggerIndex,
  });

  @override
  Widget build(BuildContext context) {
    var effectiveDelay = delay;
    if (staggerIndex != null) {
      effectiveDelay += Duration(milliseconds: 60 * staggerIndex!);
    }

    return child
        .animate(delay: effectiveDelay)
        .fadeIn(duration: duration)
        .slideY(
          begin: offset / 100, // Normalized offset
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

/// A highly tactile feedback wrapper that scales down slightly on press.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96, // Tactile range 0.96 - 1.0
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}

/// A Column helper that automatically applies staggered animations to its children.
class StaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.asMap().entries.map((entry) {
        return SlideUp(
          staggerIndex: entry.key,
          child: entry.value,
        );
      }).toList(),
    );
  }
}
