import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/photo_provider.dart';
import 'package:mobile/core/widgets/photo_feed_card.dart';

class PhotoCollectionScreen extends ConsumerWidget {
  final String memberName;

  const PhotoCollectionScreen({super.key, required this.memberName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For simplicity, we just show all photos or filter by title if memberName matches senderName
    final allPhotos = ref.watch(photoProvider).photos;
    final photos = allPhotos.where((p) => p.senderName == memberName || memberName == 'Family').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Photos from $memberName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: photos.isEmpty
        ? Center(
            child: Text(
              'No photos from $memberName yet',
              style: const TextStyle(fontSize: 24, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return PhotoFeedCard(
                photo: photos[index],
                onTap: () {
                  // Maximize photo viewed logic could go here
                },
              );
            },
          ),
    );
  }
}
