class AppAlert {
  final String id;
  final String alertType;
  final int severity;
  final String message;
  final bool isAcknowledged;
  final DateTime createdAt;
  
  AppAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.isAcknowledged,
    required this.createdAt,
  });
  
  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id'] ?? '',
      alertType: json['alert_type'] ?? '',
      severity: json['severity'] ?? 1,
      message: json['message'] ?? '',
      isAcknowledged: json['is_acknowledged'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
