import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/features/patient/games/repositories/games_repository.dart';

class WordAssociationScreen extends ConsumerStatefulWidget {
  const WordAssociationScreen({super.key});

  @override
  ConsumerState<WordAssociationScreen> createState() => _WordAssociationScreenState();
}

class _WordAssociationScreenState extends ConsumerState<WordAssociationScreen> {
  final List<Map<String, dynamic>> _puzzles = [
    {
      'question': 'Apple',
      'options': ['Fruit', 'Car', 'Building', 'Shirt'],
      'correct': 'Fruit'
    },
    {
      'question': 'Blue',
      'options': ['Number', 'Color', 'Food', 'Tool'],
      'correct': 'Color'
    },
    {
      'question': 'Bed',
      'options': ['Outdoor', 'Sleep', 'Water', 'Sky'],
      'correct': 'Sleep'
    },
    {
      'question': 'Doctor',
      'options': ['Market', 'Library', 'Hospital', 'Kitchen'],
      'correct': 'Hospital'
    }
  ];

  int _currentIndex = 0;
  String? _selectedOption;
  bool _isCorrect = false;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;

  void _onOptionTap(String option) {
    if (_selectedOption != null) return;
    
    final isCorrect = option == _puzzles[_currentIndex]['correct'];
    setState(() {
      _selectedOption = option;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _correctAnswers++;
      } else {
        _wrongAnswers++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentIndex < _puzzles.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedOption = null;
          });
        } else {
          _showCompletion();
        }
      }
    });
  }

  void _showCompletion() {
    // Calculate Score: 100% base, -15% for each wrong answer
    int calculatedScore = 100 - (_wrongAnswers * 15);
    // Weighted by correct/total
    calculatedScore = (calculatedScore * (_correctAnswers / _puzzles.length)).round();
    calculatedScore = calculatedScore.clamp(5, 100);

    // Record achievement to backend
    ref.read(gamesRepositoryProvider).recordMetric(
      metricType: 'cognitive',
      value: calculatedScore,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text(calculatedScore > 70 ? 'Puzzle Solved!' : 'Nice Effort!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Correct: $_correctAnswers / ${_puzzles.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Text('Cognitive Score: $calculatedScore%', style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzles[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Association'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              'What do you associate with:',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                puzzle['question'],
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: (puzzle['options'] as List<String>).map((opt) {
                  final isSelected = _selectedOption == opt;
                  final color = isSelected 
                      ? (_isCorrect ? Colors.green : Colors.red)
                      : Colors.white;

                  return GestureDetector(
                    onTap: () => _onOptionTap(opt),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
