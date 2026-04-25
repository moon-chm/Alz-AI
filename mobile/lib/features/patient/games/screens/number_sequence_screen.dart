import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/features/patient/games/repositories/games_repository.dart';

class NumberSequenceScreen extends ConsumerStatefulWidget {
  const NumberSequenceScreen({super.key});

  @override
  ConsumerState<NumberSequenceScreen> createState() => _NumberSequenceScreenState();
}

class _NumberSequenceScreenState extends ConsumerState<NumberSequenceScreen> {
  List<int> _sequence = [];
  List<int> _userSequence = [];
  bool _isShowingSequence = false;
  int _level = 1;
  String _message = 'Watch carefully!';

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _sequence = List.generate(_level + 2, (_) => (1 + (DateTime.now().microsecond % 9)));
    _userSequence = [];
    _isShowingSequence = true;
    _message = 'Watch the sequence!';
    setState(() {});

    _playSequence();
  }

  Future<void> _playSequence() async {
    for (int i = 0; i < _sequence.length; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() {
            _currentIndexHighlight = i;
        });
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        setState(() {
            _currentIndexHighlight = null;
        });
    }
    setState(() {
        _isShowingSequence = false;
        _message = 'Now, repeat the numbers!';
    });
  }

  int? _currentIndexHighlight;

  void _onNumberTap(int num) {
    if (_isShowingSequence) return;

    setState(() {
        _userSequence.add(num);
    });

    if (_userSequence.last != _sequence[_userSequence.length - 1]) {
        _showGameOver();
        return;
    }

    if (_userSequence.length == _sequence.length) {
        _nextLevel();
    }
  }

  void _nextLevel() {
    setState(() {
        _level++;
        _message = 'Level Up!';
    });
    Future.delayed(const Duration(seconds: 1), _startLevel);
  }

  void _showGameOver() {
    // Record achievement to backend
    int calculatedScore = (_level * 15).clamp(5, 100);
    ref.read(gamesRepositoryProvider).recordMetric(
      metricType: 'cognitive',
      value: calculatedScore,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Try Again?'),
        content: Text('You reached Level $_level! Good effort.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _level = 1);
              _startLevel();
            },
            child: const Text('Restart'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Number Path'), elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(_message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Level: $_level', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
          const SizedBox(height: 40),
          
          // Display the sequence being shown or progress
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_sequence.length, (index) {
                bool isHighlighted = _currentIndexHighlight == index;
                bool isEntered = index < _userSequence.length;
                return Container(
                    margin: const EdgeInsets.all(4),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: isHighlighted ? Colors.green : (isEntered ? AppTheme.primaryColor : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text(
                            (isHighlighted || isEntered) ? (isHighlighted ? _sequence[index].toString() : _userSequence[index].toString()) : '?',
                            style: TextStyle(color: (isHighlighted || isEntered) ? Colors.white : Colors.black26, fontWeight: FontWeight.bold),
                        ),
                    ),
                );
            }),
          ),
          
          const Spacer(),
          
          // Number Pad
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: List.generate(9, (index) {
                    int num = index + 1;
                    return GestureDetector(
                        onTap: () => _onNumberTap(num),
                        child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                            ),
                            child: Center(
                                child: Text(num.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            ),
                        ),
                    );
                }),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
