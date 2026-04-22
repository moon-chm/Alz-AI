import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/medicines/controllers/medicines_controller.dart';
import 'package:alz_ai/features/patient/medicines/models/medicine_models.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MedicationAlertScreen extends ConsumerWidget {
  final MedicationItem medication;
  const MedicationAlertScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicinesProvider);
    final language = ref.watch(languageProvider);

    final bool buttonVisible = switch (state) {
      MedicinesStateAlertActive(isConfirmVisible: final visible) => visible,
      _ => true,
    };

    final labels = {
      'en': 'I Took It',
      'hi': 'ले ली (Le Li)',
      'mr': 'घेतले (Ghetle)',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF060A18),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, color: Colors.amberAccent, size: 48),
              const SizedBox(height: 24),
              Text(
                'TIME FOR MEDICINE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 4,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                medication.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 40),
              _buildPhoto(medication),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  medication.doseInstructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
              const Spacer(),
              if (buttonVisible)
                _buildConfirmButton(context, ref, labels[language] ?? labels['en']!)
              else
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.amberAccent),
                    SizedBox(height: 16),
                    Text(
                      'Please wait...',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(MedicationItem med) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C8FF).withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: CachedNetworkImage(
          imageUrl: med.photoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.medication, size: 100, color: Color(0xFF00C8FF)),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, WidgetRef ref, String label) {
    return GestureDetector(
      onTap: () {
        ref.read(medicinesProvider.notifier).markAsTaken(medication.id);
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
