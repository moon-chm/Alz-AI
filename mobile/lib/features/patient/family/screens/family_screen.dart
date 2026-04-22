import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/family/controllers/family_controller.dart';
import 'package:alz_ai/features/patient/family/models/family_models.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/features/patient/family/screens/member_photos_screen.dart';
import 'package:alz_ai/features/patient/family/views/face_recognition_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/shared/widgets/skeleton_loader.dart';
import 'package:alz_ai/shared/widgets/error_state_widget.dart';
import 'package:alz_ai/shared/widgets/empty_state_widget.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyControllerProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': 'No family members added yet.',
      'hi': 'Koi family member nahi juda.',
      'mr': 'कोणी फॅमिली मेंबर जोडलेला नाही.',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'mr' ? 'कुटुंब' : (lang == 'hi' ? 'परिवार' : 'My Family')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _IdentifyButton(onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaceRecognitionView()),
                );
              }, language: lang),
            ),
          ),
          switch (state) {
            FamilyStateLoading() => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const SkeletonLoader(width: double.infinity, height: 200, borderRadius: 20),
                  childCount: 4,
                ),
              ),
            ),
            FamilyStateLoaded(members: final members) => _buildGrid(context, members, labels[lang] ?? labels['en']!),
            FamilyStateError(failure: final failure) => SliverFillRemaining(
              child: ErrorStateWidget(
                message: failure.message,
                onRetry: () => ref.read(familyControllerProvider.notifier).fetchFamily(),
              ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<FamilyMember> members, String emptyMsg) {
    if (members.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          message: emptyMsg,
          icon: Icons.people_outline,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final member = members[index];
            return _MemberCard(member: member);
          },
          childCount: members.length,
        ),
      ),
    );
  }
}

class _IdentifyButton extends StatelessWidget {
  final VoidCallback onTap;
  final String language;
  const _IdentifyButton({required this.onTap, required this.language});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'en': 'Who Is This Person?',
      'hi': 'ये कौन है? (Ye kaun hai)',
      'mr': 'हे कोण आहे? (He kon ahe)',
    };

    return Semantics(
      button: true,
      label: labels[language] ?? labels['en']!,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
              const Icon(Icons.face_retouching_natural, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                labels[language] ?? labels['en']!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Family Member: ${member.name}, relationship: ${member.relationship}',
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MemberPhotosScreen(member: member)),
          );
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: member.photoUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => const SkeletonLoader(width: double.infinity, height: double.infinity),
                    errorWidget: (context, url, err) => Container(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 40),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      member.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                    Text(
                      member.relationship,
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.collectionCount} photos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
