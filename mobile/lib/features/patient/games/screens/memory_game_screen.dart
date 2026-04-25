import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/features/patient/games/repositories/games_repository.dart';

class MemoryGameScreen extends ConsumerStatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  ConsumerState<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends ConsumerState<MemoryGameScreen> {
  final List<IconData> _icons = [
    Icons.favorite, Icons.star, Icons.wb_sunny, Icons.home,
    Icons.notifications, Icons.person, Icons.pets, Icons.directions_car,
  ];
  
  late List<IconData> _gameIcons;
  late List<bool> _cardFlips;
  int? _firstIndex;
  bool _isProcessing = false;
  int _matches = 0;
  int _moves = 0;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _gameIcons = [..._icons, ..._icons]..shuffle();
    _cardFlips = List.generate(16, (_) => false);
    _firstIndex = null;
    _matches = 0;
    _moves = 0;
    _isProcessing = false;
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {});
  }

  void _onCardTap(int index) {
    if (_isProcessing || _cardFlips[index] || _matches == 8) return;

    setState(() {
      _cardFlips[index] = true;
      _moves++;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _isProcessing = true;
      if (_gameIcons[_firstIndex!] == _gameIcons[index]) {
        _matches++;
        _firstIndex = null;
        _isProcessing = false;
        if (_matches == 8) {
          _stopwatch.stop();
          _showWinDialog();
        }
      } else {
        Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _cardFlips[_firstIndex!] = false;
              _cardFlips[index] = false;
              _firstIndex = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _showWinDialog() {
    // Calculate Score: Perfect is 16 moves. 
    // Penalty for extra moves and slow time.
    final int seconds = _stopwatch.elapsed.inSeconds;
    // Base score 100, -2 per move over 16, -1 per 5 seconds over 30s
    int calculatedScore = 100 - ((_moves - 16) * 2) - (seconds > 30 ? (seconds - 30) ~/ 5 : 0);
    calculatedScore = calculatedScore.clamp(10, 98); // Minimum 10, Maximum 98

    // Record achievement to backend
    ref.read(gamesRepositoryProvider).recordMetric(
      metricType: 'cognitive',
      value: calculatedScore,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Text(calculatedScore > 70 ? 'Great Job!' : 'Keep Practicing!', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Moves: $_moves • Time: ${seconds}s', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Cognitive Score: $calculatedScore%', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Play Again', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LinearProgressIndicator(
              value: _matches / 8,
              backgroundColor: Colors.grey.shade100,
              color: AppTheme.primaryColor,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _cardFlips[index] ? AppTheme.primaryColor : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!_cardFlips[index])
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                      ],
                    ),
                    child: Center(
                      child: _cardFlips[index]
                          ? Icon(_gameIcons[index], color: Colors.white, size: 30)
                          : const SizedBox(),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(
              'Matches: $_matches / 8',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
