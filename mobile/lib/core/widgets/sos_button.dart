import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/theme.dart';
import 'package:mobile/core/widgets/motions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'package:mobile/providers/sos_provider.dart';

class SOSButton extends ConsumerStatefulWidget {
  const SOSButton({super.key});
  
  @override
  ConsumerState<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends ConsumerState<SOSButton> with TickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isHolding = false;
  static const int _holdDurationMs = 3000;
  
  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _holdDurationMs),
    );
    _progressController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        if (await Vibration.hasVibrator() ?? false) {
           Vibration.vibrate(
             pattern: [0, 200, 100, 200, 100, 600, 100, 600, 100, 600, 100, 200, 100, 200],
             intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
           );
        }
        ref.read(sosProvider.notifier).trigger();
        _stopHolding();
      }
    });
  }
  
  void _startHolding() {
    final status = ref.read(sosProvider).status;
    if (status != SOSStatus.idle && status != SOSStatus.failed) return; // Prevent hold if already active
    
    setState(() => _isHolding = true);
    _progressController.forward(from: 0);
  }
  
  void _stopHolding() {
    setState(() => _isHolding = false);
    _progressController.reverse();
  }

  void _manualRetry() {
    ref.read(sosProvider.notifier).trigger(isRetry: true);
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final status = sosState.status;

    return ScaleTap(
      scale: 0.96,
      onTap: status == SOSStatus.failed ? _manualRetry : null,
      child: GestureDetector(
        onLongPressStart: (_) => _startHolding(),
        onLongPressEnd: (_) {
          if (_progressController.value < 1.0) {
            _stopHolding();
          }
        },
        onLongPressCancel: () => _stopHolding(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          child: _buildUIState(status),
        ),
      ),
    );
  }

  Widget _buildUIState(SOSStatus status) {
    switch (status) {
      case SOSStatus.idle:
        return _buildIdleUI();
      case SOSStatus.sending:
      case SOSStatus.retrying:
        return _buildProgressUI("Sending...", Colors.orange);
      case SOSStatus.awaitingAck:
        return _buildProgressUI("Confirming...", Colors.amber);
      case SOSStatus.success:
        return _buildSuccessUI();
      case SOSStatus.failed:
        return _buildFailedUI();
    }
  }

  Widget _buildIdleUI() {
    return AnimatedBuilder(
      key: const ValueKey('idle'),
      animation: _progressController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: _progressController.value,
                strokeWidth: 6,
                backgroundColor: AppColors.red.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.4),
                    blurRadius: _isHolding ? 20 : 10,
                    spreadRadius: _isHolding ? 4 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency, color: Colors.white, size: 28),
                  const Text('SOS', style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
                  if (_isHolding)
                    Text(
                      '${(3 - _progressController.value * 3).ceil()}',
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                    ),
                ],
              ),
            ).animate(
              onPlay: (c) => c.repeat(reverse: true),
            ).boxShadow(
              begin: const BoxShadow(color: Colors.transparent),
              end: BoxShadow(color: AppColors.red.withOpacity(0.5), blurRadius: 15, spreadRadius: 3),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOutSine,
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressUI(String text, Color color) {
    return Container(
      key: ValueKey(text),
      width: 140,
      height: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24, 
            height: 24, 
            child: CircularProgressIndicator(color: color, strokeWidth: 3)
          ),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300)).scaleXY(begin: 0.9, end: 1.0);
  }

  Widget _buildSuccessUI() {
    return Container(
      key: const ValueKey('success'),
      width: 200,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.green.shade200, blurRadius: 20),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(height: 4),
          Text('Help is on the way', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack);
  }

  Widget _buildFailedUI() {
    return Container(
      key: const ValueKey('failed'),
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(height: 4),
          const Text('Tap to Retry', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().shakeX(duration: 500.ms, amount: 5);
  }
}
