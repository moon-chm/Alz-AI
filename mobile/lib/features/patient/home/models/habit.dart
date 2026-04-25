class Habit {
  final String id;
  final String content;
  final DateTime dateAdded;
  final double confidence;
  final int mentionCount;
  bool isCompleted;

  Habit({
    required this.id,
    required this.content,
    required this.dateAdded,
    this.confidence = 1.0,
    this.mentionCount = 1,
    this.isCompleted = false,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      dateAdded: DateTime.parse(json['date_added'] ?? DateTime.now().toIso8601String()),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      mentionCount: json['mention_count'] ?? 1,
      isCompleted: false, // Always start fresh daily
    );
  }
}
