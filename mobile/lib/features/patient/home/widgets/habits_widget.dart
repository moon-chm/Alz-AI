import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alz_ai/features/patient/games/repositories/games_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/home/models/habit.dart';
import 'package:alz_ai/features/patient/home/repositories/habit_repository.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HabitsWidget extends ConsumerStatefulWidget {
  const HabitsWidget({super.key});

  @override
  ConsumerState<HabitsWidget> createState() => _HabitsWidgetState();
}

class _HabitsWidgetState extends ConsumerState<HabitsWidget> {
  List<Habit>? _habits;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    if (patientId == null) return;
    
    final result = await ref.read(habitRepositoryProvider).fetchHabits(patientId);
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedKey = 'habits_completed_$today';
    final completedIds = prefs.getStringList(storedKey) ?? [];

    if (mounted) {
      setState(() {
        _habits = result.fold((l) => [], (r) => r.map((h) {
          h.isCompleted = completedIds.contains(h.id);
          return h;
        }).toList());
        _isLoading = false;
      });
    }
  }

  Future<void> _onHabitToggle(int index) async {
    if (_habits == null) return;
    
    setState(() {
      _habits![index].isCompleted = !_habits![index].isCompleted;
    });

    // Persistent storage
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedKey = 'habits_completed_$today';
    final completedIds = _habits!
        .where((h) => h.isCompleted)
        .map((h) => h.id)
        .toList();
    await prefs.setStringList(storedKey, completedIds);

    // Record progress to backend for Caretaker
    final completedCount = _habits!.where((h) => h.isCompleted).length;
    final totalCount = _habits!.length;
    final percent = (completedCount / totalCount * 100).toInt();

    ref.read(gamesRepositoryProvider).recordMetric(
      metricType: 'habits',
      value: percent,
    );

    if (completedCount == totalCount) {
       _showSuccessFeedback();
    }
  }

  void _showSuccessFeedback() {
    final lang = ref.read(languageProvider);
    final msg = {
      'en': 'Great job! Routine complete.',
      'hi': 'बहुत अच्छे! दिनचर्या पूरी हुई।',
      'mr': 'खूप छान! दिनचर्या पूर्ण झाली.',
    }[lang] ?? 'Great job!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_habits == null || _habits!.isEmpty) return const SizedBox.shrink();

    final lang = ref.watch(languageProvider);
    final title = {
      'en': 'YOUR ROUTINE',
      'hi': 'आपकी दिनचर्या',
      'mr': 'तुमची दिनचर्या',
    }[lang] ?? 'YOUR ROUTINE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _habits!.length,
          itemBuilder: (context, index) {
            return _HabitItem(
              habit: _habits![index],
              onTap: () => _onHabitToggle(index),
            ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
          },
        ),
      ],
    );
  }
}

class _HabitItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  
  const _HabitItem({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.glassDecoration(
          baseColor: habit.isCompleted ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white
        ).copyWith(
          border: Border.all(
            color: habit.isCompleted ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: habit.isCompleted ? AppTheme.primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: habit.isCompleted ? AppTheme.primaryColor : AppTheme.textTertiary,
                  width: 2,
                ),
              ),
              child: habit.isCompleted 
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                habit.content,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: habit.isCompleted ? FontWeight.w500 : FontWeight.w700,
                  color: habit.isCompleted ? AppTheme.textTertiary : AppTheme.textPrimary,
                  decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
