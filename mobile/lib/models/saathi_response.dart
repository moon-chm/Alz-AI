class SAATHIResponse {
  final String text;
  final String audioUrl;
  final String mood;
  
  SAATHIResponse({required this.text, required this.audioUrl, required this.mood});
  
  factory SAATHIResponse.fromJson(Map<String, dynamic> json) {
    return SAATHIResponse(
      text: json['text'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      mood: json['mood'] ?? 'neutral',
    );
  }
  
  bool get isOfflineFallback => audioUrl.startsWith('assets/');
}
