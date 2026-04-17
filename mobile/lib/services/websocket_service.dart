import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/env.dart';
import 'package:mobile/models/websocket_event.dart';
import 'package:mobile/core/utils/logger.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String? _patientId;
  int _reconnectAttempt = 0;
  Timer? _heartbeatTimer;
  DateTime? _lastConnectedTime;
  
  Stream<WebSocketEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  void connect(String patientId) {
    if (_isConnected && _patientId == patientId) return;
    
    _patientId = patientId;
    _shouldReconnect = true;
    _reconnectAttempt = 0;
    _connect();
  }

  void _connect() {
    if (_patientId == null) return;

    AppLogger.info('WebSocket: Connecting to ${Env.wsBaseUrl} for patient $_patientId');

    try {
      final uri = Uri.parse('${Env.wsBaseUrl}/ws/$_patientId');
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        (data) => _onMessage(data as String),
        onError: (error) => _onConnectionLost('Error: $error'),
        onDone: () => _onConnectionLost('Stream closed'),
      );

      _isConnected = true;
      _lastConnectedTime = DateTime.now();
      _reconnectAttempt = 0;
      _startHeartbeat();
      
      _eventController.add(WebSocketEvent(
        type: WebSocketEventType.connectionStatus,
        data: {'connected': true},
      ));

      AppLogger.info('WebSocket: Connected successfully');
    } catch (e) {
      _onConnectionLost('Failed to connect: $e');
    }
  }

  void _onMessage(String data) {
    try {
      final event = WebSocketEvent.fromJson(data);
      _eventController.add(event);
    } catch (e) {
      AppLogger.warn('WebSocket: Received invalid JSON: $data');
    }
  }

  void _onConnectionLost(String reason) {
    AppLogger.warn('WebSocket: Connection lost ($reason)');
    _isConnected = false;
    _stopHeartbeat();
    _subscription?.cancel();
    
    _eventController.add(WebSocketEvent(
        type: WebSocketEventType.connectionStatus,
        data: {'connected': false, 'reason': reason},
    ));

    if (_shouldReconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectAttempt++;
    final delaySeconds = (1 << (_reconnectAttempt - 1)).clamp(1, 30);
    Timer(Duration(seconds: delaySeconds), () {
      if (_shouldReconnect && !_isConnected) _connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_isConnected) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _stopHeartbeat() => _heartbeatTimer?.cancel();

  void disconnect() {
    _shouldReconnect = false;
    _stopHeartbeat();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
  
  void dispose() {
    disconnect();
    _eventController.close();
  }
}

// Riverpod Provider
final webSocketServiceProvider = Provider((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});
