import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/theme.dart';

class MedicationAlertScreen extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final String time;

  const MedicationAlertScreen({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary.withOpacity(0.05),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medication, size: 100, color: AppColors.primary),
              const SizedBox(height: 32),
              const Text(
                'Time for your medicine',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(medicationName, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(dosage, style: const TextStyle(fontSize: 26, color: Colors.grey)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('Scheduled at $time', style: const TextStyle(fontSize: 22)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 64),
              
              ElevatedButton(
                onPressed: () {
                  // Mark taken
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(double.infinity, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Yes, I took it ✓', style: TextStyle(fontSize: 28, color: Colors.white)),
              ),
              
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () {
                  // Remind later logic
                  context.pop();
                },
                child: const Text('Remind me in 15 min', style: TextStyle(fontSize: 24, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
