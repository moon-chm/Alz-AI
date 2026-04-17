import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/providers/saathi_provider.dart';
import 'package:mobile/core/config/theme.dart';
import 'package:mobile/core/widgets/glass_card.dart';
import 'package:mobile/core/utils/exceptions.dart';

class SAATHICard extends ConsumerWidget {
  final VoidCallback onTap;
  
  const SAATHICard({super.key, required this.onTap});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saathiState = ref.watch(saathiProvider);
    final isNetworkDown = saathiState.lastError is NetworkException;
    
    return GestureDetector(
      onTap: isNetworkDown ? null : onTap,
      child: GlassCard(
        color: isNetworkDown ? Colors.grey.withOpacity(0.8) : AppColors.primary.withOpacity(0.85),
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'saathi_avatar',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAATHI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      isNetworkDown ? 'Offline' : 'Your Companion',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            if (saathiState.isListening)
              Text('Listening...', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 22))
                .animate().fadeIn().then().shimmer()
            else if (saathiState.isProcessing)
              Text('Thinking...', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 22))
            else if (isNetworkDown)
              Text('Disconnected', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 22))
            else
              const Text('Tap to Talk 🎙️', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
