import 'dart:async';
import 'package:alz_ai/core/websocket/websocket_manager.dart';
import 'package:alz_ai/shared/models/websocket_events.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_status_provider.g.dart';

@Riverpod(keepAlive: true)
class WatchStatus extends _$WatchStatus {
  DateTime? _lastHeartbeat;
  Timer? _checkTimer;
  StreamSubscription? _subscription;

  @override
  bool build() {
    final wsManager = ref.watch(webSocketManagerProvider);
    
    _subscription = wsManager.events.listen((event) {
      // In Riverpod 3.x, if event is VitalsUpdated...
      if (event is VitalsUpdated) {
        _lastHeartbeat = DateTime.now();
        state = true;
      }
    });

    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkStatus());

    ref.onDispose(() {
      _subscription?.cancel();
      _checkTimer?.cancel();
    });

    return false;
  }

  void _checkStatus() {
    if (_lastHeartbeat == null) {
      state = false;
      return;
    }

    final diff = DateTime.now().difference(_lastHeartbeat!);
    if (diff.inMinutes >= 5) {
      state = false;
    } else {
      state = true;
    }
  }
}
