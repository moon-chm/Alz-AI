import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/models/family_member.dart';
import 'package:mobile/core/config/theme.dart';

class FamilyGrid extends StatelessWidget {
  final List<FamilyMember> members;
  final Function(FamilyMember) onMemberTap;

  const FamilyGrid({
    super.key,
    required this.members,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Your caretaker will add family members here',
            style: TextStyle(fontSize: 22, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final member = members[index];
        return GestureDetector(
          onTap: () => onMemberTap(member),
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: member.faceEncodingPath != null && member.faceEncodingPath!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: member.faceEncodingPath!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Text(member.name[0], style: const TextStyle(fontSize: 32, color: AppColors.primary)),
                          ),
                        )
                      : Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  member.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.relationship,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
