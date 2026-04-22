import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/family/models/family_models.dart';
import 'package:alz_ai/features/patient/family/repositories/family_repository.dart';
import 'package:alz_ai/features/patient/family/widgets/family_photo_card.dart';
import 'package:alz_ai/core/storage/storage_service.dart';

class MemberPhotosScreen extends ConsumerWidget {
  final FamilyMember member;
  const MemberPhotosScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A18),
      appBar: AppBar(
        title: Text('${member.name}\'s Photos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _fetchMemberPhotos(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00C8FF)));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load photos', style: TextStyle(color: Colors.redAccent)));
          }

          final photos = snapshot.data!;
          if (photos.isEmpty) {
            return const Center(child: Text('No photos yet', style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: photos.length,
            itemBuilder: (context, index) => FamilyPhotoCard(photo: photos[index]),
          );
        },
      ),
    );
  }

  Future<dynamic> _fetchMemberPhotos(WidgetRef ref) async {
    final patientId = await ref.read(storageServiceProvider).getPatientId();
    if (patientId == null) return [];
    
    // We reuse fetchPhotos which returns Either<AppFailure, List<FamilyPhoto>>
    final result = await ref.read(familyRepositoryProvider).fetchPhotos(patientId);
    return result.fold((l) => [], (r) => r);
  }
}
