import 'dart:convert';

enum WebSocketEventType {
  vitalsUpdate,
  locationUpdate,
  sosAlert,
  medicationReminder,
  connectionStatus,
  unknown
}

class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketEvent.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final String typeStr = map['event_type'] ?? 'unknown';
      final Map<String, dynamic> data = map['data'] ?? {};

      WebSocketEventType type;
      switch (typeStr) {
        case 'vitals_update':
          type = WebSocketEventType.vitalsUpdate;
          break;
        case 'location_update':
          type = WebSocketEventType.locationUpdate;
          break;
        case 'sos_alert':
          type = WebSocketEventType.sosAlert;
          break;
        case 'medication_reminder':
          type = WebSocketEventType.medicationReminder;
          break;
        case 'connection_status':
          type = WebSocketEventType.connectionStatus;
          break;
        default:
          type = WebSocketEventType.unknown;
      }

      return WebSocketEvent(type: type, data: data);
    } catch (e) {
      return WebSocketEvent(
        type: WebSocketEventType.unknown,
        data: {'error': e.toString(), 'raw': jsonString},
      );
    }
  }

  @override
  String toString() => 'WebSocketEvent(type: $type, data: $data)';
}
