import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/home/providers/safety_provider.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SafetyStatusCard extends ConsumerWidget {
  const SafetyStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safety = ref.watch(safetyProvider);
    final lang = ref.watch(languageProvider);

    final String title;
    final String subtitle;
    final Color statusColor;
    final IconData icon;

    final texts = {
      'en': {
        'danger': 'DANGER',
        'danger_desc': 'In danger zone! Help notified.',
        'caution': 'CAUTION',
        'caution_desc': 'Moving outside safe zone',
        'safe': 'SAFE',
        'safe_desc': 'Within safe parameters',
      },
      'hi': {
        'danger': 'खतरा',
        'danger_desc': 'खतरे के क्षेत्र में! सहायता को सूचित किया गया।',
        'caution': 'सावधान',
        'caution_desc': 'सुरक्षित क्षेत्र से बाहर जा रहे हैं',
        'safe': 'सुरक्षित',
        'safe_desc': 'सुरक्षित मापदंडों के भीतर',
      },
      'mr': {
        'danger': 'धोका',
        'danger_desc': 'धोकादायक क्षेत्रात! मदतीला सूचित केले आहे।',
        'caution': 'सावधान',
        'caution_desc': 'सुरक्षित क्षेत्राबाहेर जात आहे',
        'safe': 'सुरक्षित',
        'safe_desc': 'सुरक्षित मर्यादेत',
      },
    }[lang] ?? {
      'danger': 'DANGER',
      'danger_desc': 'In danger zone! Help notified.',
      'caution': 'CAUTION',
      'caution_desc': 'Moving outside safe zone',
      'safe': 'SAFE',
      'safe_desc': 'Within safe parameters',
    };

    if (safety.isInDangerZone) {
      title = texts['danger']!;
      subtitle = texts['danger_desc']!;
      statusColor = AppTheme.errorColor;
      icon = Icons.warning_rounded;
    } else if (safety.isOutsideSafeZone) {
      title = texts['caution']!;
      subtitle = texts['caution_desc']!;
      statusColor = AppTheme.warningColor;
      icon = Icons.info_outline_rounded;
    } else {
      title = texts['safe']!;
      subtitle = texts['safe_desc']!;
      statusColor = AppTheme.successColor;
      icon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: AppTheme.glassDecoration().copyWith(
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (safety.isInDangerZone || safety.isOutsideSafeZone) 
              Icon(Icons.arrow_forward_ios_rounded, color: statusColor.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn();
  }
}
