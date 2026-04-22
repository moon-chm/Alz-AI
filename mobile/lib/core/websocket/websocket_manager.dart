import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:alz_ai/core/config/app_config.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/shared/models/websocket_events.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'websocket_manager.g.dart';

enum WebSocketStatus { connected, disconnected, reconnecting }

class WebSocketManager extends WidgetsBindingObserver {
  final StorageService _storage;
  WebSocketChannel? _channel;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  WebSocketManager(this._storage) {
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<WebSocketEvent> get events => _eventController.stream;
  Stream<WebSocketStatus> get status => _statusController.stream;
  DateTime? lastVitalsTime;

  Future<void> connect() async {
    final patientId = await _storage.getPatientId();
    if (patientId == null) {
      _updateStatus(WebSocketStatus.disconnected);
      return;
    }

    final wsUrl = Uri.parse('${AppConfig.wsBaseUrl}/$patientId');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _updateStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> json = jsonDecode(data);
            final event = WebSocketEvent.fromJson(json);
            
            if (event is VitalsUpdated) {
              lastVitalsTime = DateTime.parse(event.timestamp);
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('last_vitals_time', event.timestamp);
              });
            }
            
            _eventController.add(event);
          } catch (e) {
            debugPrint('WS Parsing Error: $e');
          }
        },
        onError: (err) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _channel = null;
    if (_status != WebSocketStatus.disconnected) {
      _updateStatus(WebSocketStatus.reconnecting);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    final delaySeconds = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      connect();
    });
  }

  void _updateStatus(WebSocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  void disconnect() {
    _updateStatus(WebSocketStatus.disconnected);
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      connect();
    } else if (state == AppLifecycleState.paused) {
      disconnect();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}

@riverpod
WebSocketManager webSocketManager(Ref ref) {
  final storage = ref.watch(storageServiceProvider);
  final manager = WebSocketManager(storage);
  
  ref.onDispose(() => manager.dispose());
  
  return manager;
}

@riverpod
Stream<WebSocketEvent> webSocketEvents(Ref ref) {
  return ref.watch(webSocketManagerProvider).events;
}
