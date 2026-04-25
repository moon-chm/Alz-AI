import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/family/repositories/family_repository.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/features/patient/family/models/family_photo.dart';
import 'package:alz_ai/features/patient/games/repositories/games_repository.dart';
import 'package:alz_ai/shared/widgets/empty_state_widget.dart';

class PhotoRecognitionScreen extends ConsumerStatefulWidget {
  const PhotoRecognitionScreen({super.key});

  @override
  ConsumerState<PhotoRecognitionScreen> createState() => _PhotoRecognitionScreenState();
}

class _PhotoRecognitionScreenState extends ConsumerState<PhotoRecognitionScreen> {
  List<FamilyPhoto> _photos = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _selectedName;
  bool _isShowingResult = false;
  int _correctCount = 0;
  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    if (patientId == null) return;

    final result = await ref.read(familyRepositoryProvider).fetchPhotos(patientId);
    result.fold(
      (l) => setState(() => _isLoading = false),
      (list) {
        setState(() {
          _photos = list..shuffle();
          _isLoading = false;
        });
      },
    );
  }

  void _onNameSelect(String name) {
    if (_isShowingResult) return;
    
    final isCorrect = name == _photos[_currentIndex].relationship;
    setState(() {
      _selectedName = name;
      _isShowingResult = true;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (_currentIndex < _photos.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedName = null;
            _isShowingResult = false;
          });
        } else {
          _showSummary();
        }
      }
    });
  }

  void _showSummary() {
    // Calculate Score: Accuracy based
    int total = _correctCount + _wrongCount;
    int calculatedScore = total > 0 ? ((_correctCount / total) * 100).round() : 0;
    calculatedScore = calculatedScore.clamp(5, 100);

    // Record achievement to backend
    ref.read(gamesRepositoryProvider).recordMetric(
      metricType: 'cognitive',
      value: calculatedScore,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(calculatedScore > 70 ? 'Wonderful!' : 'Keep Practicing!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recall: $_correctCount / ${(_correctCount + _wrongCount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Text('Cognitive Score: $calculatedScore%', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Return Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Recall')),
        body: const EmptyStateWidget(message: 'Ask your family to add photos to play this game!'),
      );
    }

    final photo = _photos[_currentIndex];
    // Generate dummy options including the correct name
    final List<String> options = [photo.relationship];
    final others = ['Son', 'Daughter', 'Doctor', 'Friend', 'Brother', 'Sister']
        ..remove(photo.relationship)
        ..shuffle();
    options.addAll(others.take(3));
    options.shuffle();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who is this?'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                image: DecorationImage(
                  image: NetworkImage(photo.photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Identify the relationship:',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 3,
            child: GridView.count(
              padding: const EdgeInsets.all(24),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2,
              children: options.map((name) {
                final isSelected = _selectedName == name;
                final isCorrect = name == photo.relationship;
                
                Color color = Colors.white;
                if (isSelected) {
                  color = isCorrect ? Colors.green : Colors.red;
                } else if (_isShowingResult && isCorrect) {
                  color = Colors.green.withValues(alpha: 0.3);
                }

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: isSelected ? Colors.white : Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  onPressed: () => _onNameSelect(name),
                  child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
