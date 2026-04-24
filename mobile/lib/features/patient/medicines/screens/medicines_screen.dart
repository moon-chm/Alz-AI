import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/medicines/controllers/medicines_controller.dart';
import 'package:alz_ai/features/patient/medicines/models/medicine_models.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/shared/widgets/skeleton_loader.dart';
import 'package:alz_ai/shared/widgets/error_state_widget.dart';
import 'package:alz_ai/shared/widgets/empty_state_widget.dart';

class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicinesProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': 'No medicines scheduled today.',
      'hi': 'Aaj koi dawai nahi hai.',
      'mr': 'आज कोणी औषध नाही.',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'mr' ? 'औषधे' : (lang == 'hi' ? 'दवाइयाँ' : 'Medicines')),
      ),
      body: switch (state) {
        MedicinesStateLoading() => Padding(
          padding: const EdgeInsets.all(16.0),
          child: SkeletonLoader.list(itemCount: 4),
        ),
        MedicinesStateLoaded(medications: final meds) => _buildList(context, meds, lang, labels[lang] ?? labels['en']!),
        MedicinesStateAlertActive() => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        MedicinesStateError(failure: final f) => ErrorStateWidget(
          message: f.message,
          onRetry: () => ref.read(medicinesProvider.notifier).fetchSchedule(),
        ),
      },
    );
  }

  Widget _buildList(BuildContext context, List<MedicationItem> medications, String lang, String emptyMsg) {
    if (medications.isEmpty) {
      return EmptyStateWidget(
        message: emptyMsg,
        icon: Icons.medication_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final med = medications[index];
        return _MedicationCard(med: med);
      },
    );
  }
}

class _MedicationCard extends ConsumerWidget {
  final MedicationItem med;
  const _MedicationCard({required this.med});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm');
    DateTime? scheduledTime;
    try {
      scheduledTime = DateTime.parse(med.time);
    } catch (_) {}
    
    Color statusColor;
    switch (med.status) {
      case 'taken': statusColor = AppTheme.successColor; break;
      case 'missed': statusColor = AppTheme.errorColor; break;
      default: statusColor = AppTheme.warningColor;
    }

    return Semantics(
      label: 'Medication: ${med.name}, at ${med.time}. Status: ${med.status}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: med.photoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SkeletonLoader(width: 60, height: 60),
                  errorWidget: (context, url, error) => Container(
                    width: 60,
                    height: 60,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.medication, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Text Content - Expanded to prevent overflow and mid-word breaks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      med.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scheduledTime != null ? timeFormat.format(scheduledTime) : med.time,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      med.doseInstructions,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Trailing Actions - Column with spacing to prevent overlap
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      med.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (med.status == 'upcoming') ...[
                    const SizedBox(height: 12),
                    Semantics(
                      button: true,
                      label: 'Mark as taken',
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 40),
                          onPressed: () => ref.read(medicinesProvider.notifier).markAsTaken(med.id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
