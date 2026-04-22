import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/providers/level_provider.dart';
import 'package:alz_ai/features/patient/home/widgets/top_bar.dart';
import 'package:alz_ai/features/patient/home/widgets/saathi_companion_card.dart';
import 'package:alz_ai/features/patient/family/repositories/family_repository.dart';
import 'package:alz_ai/features/patient/family/widgets/family_photo_card.dart';
import 'package:alz_ai/shared/widgets/sos_button.dart';
import 'package:alz_ai/features/patient/family/models/family_photo.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/core/services/tts_service.dart';
import 'package:alz_ai/features/patient/family/views/face_recognition_view.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/shared/widgets/skeleton_loader.dart';
import 'package:alz_ai/shared/widgets/empty_state_widget.dart';
import 'package:alz_ai/core/providers/language_provider.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  Timer? _pollingTimer;
  List<FamilyPhoto> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
    _pollingTimer = Timer.periodic(const Duration(minutes: 3), (_) => _fetchPhotos());
  }

  Future<void> _fetchPhotos() async {
    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    
    if (patientId == null) return;

    final result = await ref.read(familyRepositoryProvider).fetchPhotos(patientId);
    result.fold(
      (l) => debugPrint('Error fetching photos: $l'),
      (newList) {
        if (mounted) {
          setState(() {
            _photos = newList;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(patientLevelProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': {'empty': 'No photos yet.', 'identify': 'WHO IS THIS?'},
      'hi': {'empty': 'Abhi koi photo nahi hai.', 'identify': 'यह कौन है?'},
      'mr': {'empty': 'आता कोणी फोटो नाही.', 'identify': 'हे कोण आहे?'},
    }[lang] ?? {'empty': 'No photos yet.', 'identify': 'WHO IS THIS?'};

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: HomeTopBar()),
              if (level == 1)
                const SliverToBoxAdapter(child: SaathiCompanionCard(isCompact: true)),
              if (level == 2)
                const SliverAppBar(
                  backgroundColor: Colors.transparent,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  expandedHeight: 280,
                  collapsedHeight: 280,
                  flexibleSpace: SaathiCompanionCard(),
                ),
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SkeletonLoader.list(itemCount: 3),
                  ),
                )
              else if (_photos.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(message: labels['empty']!),
                )
              else if (level < 3)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FamilyPhotoCard(photo: _photos[index]),
                    childCount: _photos.length,
                  ),
                )
              else
                SliverFillRemaining(
                  child: _Level3AutoCycleView(photos: _photos),
                ),
            ],
          ),
          if (level == 3)
            Positioned(
              bottom: 140, // Adjusted for larger SOS button area
              left: 24,
              right: 24,
              child: _Level3IdentifyButton(
                label: labels['identify']!,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FaceRecognitionView()),
                  );
                },
              ),
            ),
          if (level == 3)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(child: SosButton()),
            ),
        ],
      ),
    );
  }
}

class _Level3IdentifyButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _Level3IdentifyButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80, // Enforced 56+ size
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.face_retouching_natural, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22, // Minimum 20sp for headings/primary buttons
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Level3AutoCycleView extends ConsumerStatefulWidget {
  final List<FamilyPhoto> photos;
  const _Level3AutoCycleView({required this.photos});

  @override
  ConsumerState<_Level3AutoCycleView> createState() => _Level3AutoCycleViewState();
}

class _Level3AutoCycleViewState extends ConsumerState<_Level3AutoCycleView> {
  int _currentIndex = 0;
  Timer? _cycleTimer;

  @override
  void initState() {
    super.initState();
    if (widget.photos.isNotEmpty) {
      _cycleTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.photos.length;
          });
          
          // Auto-narration for Level 3
          final currentPhoto = widget.photos[_currentIndex];
          if (currentPhoto.narrationText != null) {
             ref.read(ttsServiceProvider).speak(currentPhoto.narrationText!);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const Center(child: Text('Loading memories...', style: TextStyle(color: Colors.white38)));
    }

    return FamilyPhotoCard(photo: widget.photos[_currentIndex]);
  }
}
