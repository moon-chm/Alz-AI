import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/core/config/theme.dart';
import 'package:mobile/core/widgets/glass_card.dart';
import 'package:mobile/providers/vitals_provider.dart';
import 'package:mobile/providers/insights_provider.dart';

import 'package:mobile/providers/app_lifecycle_provider.dart';

class VitalsChartCard extends ConsumerWidget {
  const VitalsChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycleState = ref.watch(appLifecycleProvider);
    final isResumed = lifecycleState == AppLifecycleState.resumed;
    
    // Skip watching history details if in background to save resources
    final hrHistory = isResumed 
      ? ref.watch(vitalsProvider.select((v) => v.hrHistory))
      : const <int>[]; 
      
    final insightState = ref.watch(insightsProvider);
    
    Color insightColor;
    IconData insightIcon;
    switch (insightState.severity) {
      case InsightSeverity.normal:
        insightColor = Colors.green;
        insightIcon = Icons.check_circle_outline;
        break;
      case InsightSeverity.warning:
        insightColor = Colors.orange;
        insightIcon = Icons.warning_amber_rounded;
        break;
      case InsightSeverity.critical:
        insightColor = AppColors.red;
        insightIcon = Icons.error_outline;
        break;
    }

    return GlassCard(
      color: Colors.white.withValues(alpha: 0.9),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Insight Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Heart Rate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  Text('Last 60 readings', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: insightColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: insightColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(insightIcon, color: insightColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      insightState.message,
                      style: TextStyle(color: insightColor, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 140,
            child: hrHistory.isEmpty
                ? const Center(child: Text("Waiting for vitals...", style: TextStyle(color: Colors.grey)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: 40,
                      maxY: 160,
                      lineBarsData: [
                        LineChartBarData(
                          spots: hrHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false), // Hide dots to keep simple
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.3),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 400), // Smooth swap anims
                    curve: Curves.easeOutCubic,
                  ),
          ),
        ],
      ),
    );
  }
}
