import 'package:flutter/material.dart';
import 'package:mobile/core/config/theme.dart';

class VitalsChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String unit;
  final bool isAlert;

  const VitalsChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.red.withOpacity(0.1) : Colors.white,
        border: Border.all(
          color: isAlert ? AppColors.red : AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isAlert ? AppColors.red : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Builder(builder: (context) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: numValue, end: numValue),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          // Format to 0 decimals if it's a whole integer equivalent
                          final display = val == val.truncateToDouble() 
                              ? val.toInt().toString() 
                              : val.toStringAsFixed(1);
                          return Text(
                            display,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isAlert ? AppColors.red : AppColors.navy,
                            ),
                          );
                        },
                      );
                    }
                    return Text(
                      value, // Fallback for strings like '120/80'
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isAlert ? AppColors.red : AppColors.navy,
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 16,
                      color: isAlert ? AppColors.red : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
