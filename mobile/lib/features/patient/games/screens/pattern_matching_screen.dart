import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/features/patient/games/repositories/games_repository.dart';

class PatternMatchingScreen extends ConsumerStatefulWidget {
  const PatternMatchingScreen({super.key});

  @override
  ConsumerState<PatternMatchingScreen> createState() => _PatternMatchingScreenState();
}

class _PatternMatchingScreenState extends ConsumerState<PatternMatchingScreen> {
  final List<IconData> _shapes = [
    Icons.circle, Icons.square, Icons.change_history, Icons.star, Icons.pentagon, Icons.diamond
  ];
  
  late IconData _targetShape;
  late List<IconData> _options;
  int _score = 0;
  int _totalAttempts = 0;
  bool _isShowingResult = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _nextLevel();
  }

  void _nextLevel() {
    _targetShape = (_shapes..shuffle()).first;
    _options = [_targetShape];
    final others = _shapes.where((s) => s != _targetShape).toList()..shuffle();
    _options.addAll(others.take(3));
    _options.shuffle();
    _isShowingResult = false;
    _selectedIndex = null;
    setState(() {});
  }

  void _onOptionTap(int index) {
    if (_isShowingResult) return;

    final isCorrect = _options[index] == _targetShape;
    setState(() {
      _selectedIndex = index;
      _isShowingResult = true;
      _totalAttempts++;
      if (isCorrect) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_score < 5) { // Reduced to 5 rounds for faster feedback
          _nextLevel();
        } else {
          _showWin();
        }
      }
    });
  }

  void _showWin() {
    // Calculate Score: (Correct / Total Attempts) * 100
    int calculatedScore = ((_score / _totalAttempts) * 100).round();
    calculatedScore = calculatedScore.clamp(10, 100);

    // Record achievement to backend
    ref.read(gamesRepositoryProvider).recordMetric(
      metricType: 'cognitive',
      value: calculatedScore,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(calculatedScore > 70 ? 'Shape Master!' : 'Keep Focused!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Accuracy: $_score/${_totalAttempts}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Text('Cognitive Score: $calculatedScore%', style: const TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Finished'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Match'), elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text('Find the Matching Shape:', style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(_targetShape, size: 60, color: Colors.red),
          ),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                final isCorrect = _options[index] == _targetShape;
                
                Color bgColor = Colors.white;
                if (isSelected) {
                  bgColor = isCorrect ? Colors.green : Colors.red;
                } else if (_isShowingResult && isCorrect) {
                  bgColor = Colors.green.withValues(alpha: 0.1);
                }

                return GestureDetector(
                  onTap: () => _onOptionTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Icon(
                      _options[index],
                      size: 40,
                      color: isSelected ? Colors.white : Colors.blueGrey,
                    ),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text('Progress: $_score / 10', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
