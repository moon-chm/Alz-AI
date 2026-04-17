import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/models/medication.dart';
import 'package:mobile/core/config/theme.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onConfirmTaken;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onConfirmTaken,
  });

  bool _isPastAnyTime() {
    if (medication.isTaken) return false;
    final now = DateTime.now();
    for (var t in medication.scheduledTimes) {
      final parts = t.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        if (now.hour > h || (now.hour == h && now.minute > m)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTaken = medication.isTaken;
    final bool isMissed = _isPastAnyTime();
    
    final Color borderColor = isTaken 
        ? AppColors.green 
        : (isMissed ? AppColors.red : Colors.grey.shade300);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 6)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💊 ${medication.name}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(medication.dosage, style: const TextStyle(fontSize: 22, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: medication.scheduledTimes.map((time) => Chip(
                          label: Text(time, style: const TextStyle(fontSize: 20)),
                          backgroundColor: AppColors.bg,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                if (medication.tabletPhotoUrl != null && medication.tabletPhotoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: medication.tabletPhotoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isTaken ? null : onConfirmTaken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTaken ? AppColors.green : AppColors.primary,
                  disabledBackgroundColor: AppColors.green.withOpacity(0.5),
                ),
                child: Text(
                  isTaken ? 'Taken ✓' : 'Confirm Taken',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
