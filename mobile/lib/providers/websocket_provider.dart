import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import 'package:mobile/models/websocket_event.dart';
import 'auth_provider.dart';
import 'package:mobile/core/utils/logger.dart';

// New Notifier to handle manual overrides and connection state
class WebSocketController extends StateNotifier<bool> {
  final WebSocketService _service;
  final AuthState _auth;

  WebSocketController(this._service, this._auth) : super(_service.isConnected) {
    if (_auth.identifier != null) {
      AppLogger.info('WebSocketController: Auto-connecting for ${_auth.identifier}');
      _service.connect(_auth.identifier!);
      state = true;
    }
  }

  void forceDisconnect() {
    _service.disconnect();
    state = false;
  }

  void reconnect() {
    if (_auth.identifier != null) {
      _service.connect(_auth.identifier!);
      state = true;
    }
  }

  bool get isConnected => _service.isConnected;
}

final webSocketControllerProvider = StateNotifierProvider<WebSocketController, bool>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  final auth = ref.watch(authProvider);
  return WebSocketController(service, auth);
});

// StreamProvider to expose the event stream to the UI
final webSocketEventStreamProvider = StreamProvider<WebSocketEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events;
});
