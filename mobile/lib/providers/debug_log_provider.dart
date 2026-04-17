import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/websocket_event.dart';
import 'websocket_provider.dart';

enum LogSeverity { info, warning, error }

class DebugLogEntry {
  final DateTime timestamp;
  final String title;
  final String message;
  final LogSeverity severity;
  final Map<String, dynamic>? data;

  DebugLogEntry({
    required this.timestamp,
    required this.title,
    required this.message,
    this.severity = LogSeverity.info,
    this.data,
  });
}

class DebugLogNotifier extends StateNotifier<List<DebugLogEntry>> {
  static const int maxLogs = 50;
  final Ref _ref;

  DebugLogNotifier(this._ref) : super([]) {
    _init();
  }

  void _init() {
    // Listen to WebSocket events and add to log
    _ref.listen<AsyncValue<WebSocketEvent>>(webSocketEventStreamProvider, (previous, next) {
      next.whenData((event) {
        _addLog(
          title: 'WS: ${event.type.name}',
          message: 'Received event from server',
          data: event.data,
          severity: _getSeverityForEvent(event.type),
        );
      });
      
      if (next.hasError) {
        _addLog(
          title: 'WS: ERROR',
          message: next.error.toString(),
          severity: LogSeverity.error,
        );
      }
    });

    // Initial log
    _addLog(title: 'SYSTEM', message: 'Debug logging initialized');
  }

  void _addLog({
    required String title,
    required String message,
    LogSeverity severity = LogSeverity.info,
    Map<String, dynamic>? data,
  }) {
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      title: title,
      message: message,
      severity: severity,
      data: data,
    );

    final newList = [entry, ...state];
    if (newList.length > maxLogs) {
      state = newList.sublist(0, maxLogs);
    } else {
      state = newList;
    }
  }

  LogSeverity _getSeverityForEvent(WebSocketEventType type) {
    if (type == WebSocketEventType.sosAlert) return LogSeverity.error;
    if (type == WebSocketEventType.medicationReminder) return LogSeverity.warning;
    return LogSeverity.info;
  }

  void clearLogs() {
    state = [];
    _addLog(title: 'SYSTEM', message: 'Logs cleared');
  }

  void addManualLog(String title, String message, {LogSeverity severity = LogSeverity.info}) {
    _addLog(title: title, message: message, severity: severity);
  }
}

final debugLogProvider = StateNotifierProvider<DebugLogNotifier, List<DebugLogEntry>>((ref) {
  return DebugLogNotifier(ref);
});
