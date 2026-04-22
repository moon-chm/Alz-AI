import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/saathi/controllers/saathi_controller.dart';
import 'package:alz_ai/features/patient/saathi/models/saathi_state.dart';
import 'package:alz_ai/core/providers/language_provider.dart';

class SaathiCompanionCard extends ConsumerWidget {
  final bool isCompact;
  const SaathiCompanionCard({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saathiProvider);
    final language = ref.watch(languageProvider);
    
    final labels = {
      'en': 'Talk to SAATHI',
      'hi': 'Baat Karo',
      'mr': 'Bola',
    };

    final localizedLabel = labels[language] ?? labels['en']!;
    
    return Container(
      margin: EdgeInsets.all(isCompact ? 8 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C8FF).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 24.0),
            child: Column(
              children: [
                Icon(Icons.psychology, color: const Color(0xFF00C8FF), size: isCompact ? 32 : 48),
                SizedBox(height: isCompact ? 8 : 16),
                _buildDynamicContent(state, isCompact),
              ],
            ),
          ),
          _buildActionButton(context, ref, state, localizedLabel, isCompact),
          SizedBox(height: isCompact ? 8 : 16),
        ],
      ),
    );
  }

  Widget _buildDynamicContent(SaathiState state, bool isCompact) {
    return state.when(
      idle: (msg) => Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: isCompact ? 14 : 18, height: 1.5),
      ),
      recording: () => Column(
        children: [
          Text(
            'Listening...',
            style: TextStyle(color: Colors.redAccent, fontSize: isCompact ? 14 : 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: isCompact ? 6 : 12),
          _WaveformPlaceholder(isCompact: isCompact),
        ],
      ),
      uploading: () => Column(
        children: [
          CircularProgressIndicator(color: const Color(0xFF00C8FF), strokeWidth: isCompact ? 2 : 4),
          SizedBox(height: isCompact ? 6 : 12),
          const Text('Processing...', style: TextStyle(color: Colors.white70)),
        ],
      ),
      speaking: (response) => Text(
        response,
        textAlign: TextAlign.center,
        style: TextStyle(color: const Color(0xFF00C8FF), fontSize: isCompact ? 14 : 18, height: 1.5),
      ),
      error: (msg) => Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.orangeAccent, fontSize: isCompact ? 12 : 16),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, SaathiState state, String label, bool isCompact) {
    final bool isRecording = state.maybeWhen(recording: () => true, orElse: () => false);
    final bool isUploading = state.maybeWhen(uploading: () => true, orElse: () => false);

    return GestureDetector(
      onTap: () {
        if (isUploading) return;
        if (isRecording) {
          ref.read(saathiProvider.notifier).stopAndUpload();
        } else {
          ref.read(saathiProvider.notifier).startRecording();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isRecording ? Colors.redAccent : const Color(0xFF00C8FF),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.redAccent : const Color(0xFF00C8FF)).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPlaceholder extends StatelessWidget {
  final bool isCompact;
  const _WaveformPlaceholder({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: isCompact ? 2 : 4,
        height: (isCompact ? 10 : 20) + (index % 3) * (isCompact ? 5 : 10),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(2)),
      )),
    );
  }
}
