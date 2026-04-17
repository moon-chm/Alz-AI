import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/models/photo.dart';
import 'package:mobile/core/config/theme.dart';

class PhotoFeedCard extends StatelessWidget {
  final FamilyPhoto photo;
  final VoidCallback onTap;

  const PhotoFeedCard({super.key, required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Hero(
                  tag: 'photo_${photo.id}',
                  child: CachedNetworkImage(
                    imageUrl: photo.cloudinaryUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 50)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(photo.senderName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(
                    photo.sentAt.toString().split(' ')[0], 
                    style: const TextStyle(fontSize: 20, color: Colors.grey)
                  ),
                  if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      photo.caption!,
                      style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
