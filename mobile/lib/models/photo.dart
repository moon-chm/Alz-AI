class FamilyPhoto {
  final String id;
  final String cloudinaryUrl;
  final String? caption;
  final String senderName;
  final DateTime sentAt;
  final bool isViewed;
  
  FamilyPhoto({
    required this.id,
    required this.cloudinaryUrl,
    this.caption,
    required this.senderName,
    required this.sentAt,
    required this.isViewed,
  });
  
  factory FamilyPhoto.fromJson(Map<String, dynamic> json) {
    return FamilyPhoto(
      id: json['id'] ?? '',
      cloudinaryUrl: json['cloudinary_url'] ?? '',
      caption: json['caption'],
      senderName: json['sender_name'] ?? 'Family',
      sentAt: DateTime.tryParse(json['sent_at'] ?? '') ?? DateTime.now(),
      isViewed: json['is_viewed'] ?? false,
    );
  }
}
