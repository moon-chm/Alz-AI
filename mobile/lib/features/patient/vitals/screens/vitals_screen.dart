import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/vitals/controllers/vitals_controller.dart';
import 'package:alz_ai/features/patient/vitals/models/vitals_models.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:intl/intl.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/shared/widgets/skeleton_loader.dart';
import 'package:alz_ai/shared/widgets/error_state_widget.dart';

class VitalsScreen extends ConsumerWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(vitalsControllerProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': {
        'title': 'My Vitals',
        'hr': 'Heart Rate',
        'spo2': 'Blood Oxygen',
        'steps': 'Steps Today',
        'sleep': 'Sleep',
        'hrv': 'Stress Level',
        'last_updated': 'Last updated',
        'not_wearing': 'Please wear your watch',
        'bpm': 'BPM',
        'hours': 'hrs',
      },
      'hi': {
        'title': 'मेरी सेहत',
        'hr': 'दिल की धड़कन',
        'spo2': 'ऑक्सीजन',
        'steps': 'आज के कदम',
        'sleep': 'नींद',
        'hrv': 'तनाव का स्तर',
        'last_updated': 'अंतिम अपडेट',
        'not_wearing': 'कृपया अपनी घड़ी पहनें',
        'bpm': 'बीपीएम',
        'hours': 'घंटे',
      },
      'mr': {
        'title': 'माझी प्रकृती',
        'hr': 'हृदयाचे ठोके',
        'spo2': 'ऑक्सिजन',
        'steps': 'आजची पावले',
        'sleep': 'झोप',
        'hrv': 'तणाव पातळी',
        'last_updated': 'शेवटचे अपडेट',
        'not_wearing': 'कृपया तुमची घड्याळ घाला',
        'bpm': 'BPM',
        'hours': 'तास',
      },
    }[lang] ?? {
      'en': {
        'title': 'My Vitals',
        'hr': 'Heart Rate',
        'spo2': 'Blood Oxygen',
        'steps': 'Steps Today',
        'sleep': 'Sleep',
        'hrv': 'Stress Level',
        'last_updated': 'Last updated',
        'not_wearing': 'Please wear your watch',
        'bpm': 'BPM',
        'hours': 'hrs',
      }
    }['en']!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(labels['title']!),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: vitalsAsync.when(
              data: (vitals) => _buildVitalsGrid(context, vitals, labels),
              loading: () => Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader(width: double.infinity, height: 160, borderRadius: 24)),
                        const SizedBox(width: 16),
                        Expanded(child: SkeletonLoader(width: double.infinity, height: 160, borderRadius: 24)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SkeletonLoader(width: double.infinity, height: 100, borderRadius: 24),
                  ],
                ),
              ),
              error: (err, stack) => ErrorStateWidget(
                message: err.toString(),
                onRetry: () => ref.refresh(vitalsControllerProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid(BuildContext context, VitalsReading? vitals, Map<String, String> labels) {
    if (vitals == null || vitals.heartRate == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch_off_outlined, size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              labels['not_wearing']!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _VitalCard(
                  title: labels['hr']!,
                  value: vitals.heartRate.toString(),
                  unit: labels['bpm']!,
                  icon: Icons.favorite,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VitalCard(
                  title: labels['spo2']!,
                  value: '${vitals.spo2}%',
                  unit: 'SpO2',
                  icon: Icons.bloodtype,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _VitalCard(
            title: labels['steps']!,
            value: NumberFormat('#,###').format(vitals.steps),
            unit: '',
            icon: Icons.directions_walk,
            color: AppTheme.warningColor,
            isWide: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VitalCard(
                  title: labels['sleep']!,
                  value: '${(vitals.sleepMinutes / 60).toStringAsFixed(1)}',
                  unit: labels['hours']!,
                  icon: Icons.bedtime,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VitalCard(
                  title: labels['hrv']!,
                  value: vitals.hrv != null ? vitals.hrv!.toStringAsFixed(0) : '--',
                  unit: 'ms',
                  icon: Icons.psychology,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '${labels['last_updated']}: ${DateFormat.jm().format(vitals.recordedAt)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _VitalCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isWide ? 100 : 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const Spacer(),
                Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text(unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
