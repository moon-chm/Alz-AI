class Patient {
  final String id;
  final String patientUniqueId;
  final String fullName;
  final String preferredName;
  final String language;
  final int level;
  final String trustedPhone;
  final DateTime? dob;
  
  Patient({
    required this.id,
    required this.patientUniqueId,
    required this.fullName,
    required this.preferredName,
    required this.language,
    required this.level,
    required this.trustedPhone,
    this.dob,
  });
  
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      patientUniqueId: json['patient_unique_id'] ?? '',
      fullName: json['full_name'] ?? '',
      preferredName: json['preferred_name'] ?? (json['full_name']?.split(' ')?.first ?? 'Friend'),
      language: json['language'] ?? 'en',
      level: json['level'] ?? 1,
      trustedPhone: json['trusted_phone'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_unique_id': patientUniqueId,
      'full_name': fullName,
      'preferred_name': preferredName,
      'language': language,
      'level': level,
      'trusted_phone': trustedPhone,
      'dob': dob?.toIso8601String(),
    };
  }
  
  int get age {
    if (dob == null) return 0;
    return DateTime.now().year - dob!.year;
  }
}
