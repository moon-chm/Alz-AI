class FamilyMember {
  final String id;
  final String name;
  final String relationship;
  final String? phone;
  final String? faceEncodingPath;
  
  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.faceEncodingPath,
  });
  
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'],
      faceEncodingPath: json['face_encoding_path'],
    );
  }
}
