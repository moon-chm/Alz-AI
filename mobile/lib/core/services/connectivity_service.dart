import 'dart:async';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:alz_ai/core/services/sync_queue.dart';
import 'package:alz_ai/core/network/dio_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'connectivity_service.g.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final SyncQueue _syncQueue;
  final DioClient _dioClient;
  
  final _controller = StreamController<bool>.broadcast();
  
  ConnectivityService(this._connectivity, this._syncQueue, this._dioClient) {
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      _controller.add(isOnline);
      if (isOnline) {
        _processQueue();
      }
    });
  }

  Stream<bool> get isOnline => _controller.stream;

  Future<void> _processQueue() async {
    final queue = await _syncQueue.getQueue();
    if (queue.isEmpty) return;

    for (final item in queue) {
      try {
        final result = await _dioClient.request(
          (dio) => dio.request(
            item.endpoint,
            data: item.body,
            options: Options(method: item.method),
          ),
        );

        result.fold(
          (l) => null, // Keep in queue for next time
          (r) async => await _syncQueue.removeItem(item.timestamp),
        );
      } catch (e) {
        // Log error
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}

@riverpod
Future<ConnectivityService> connectivityService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final syncQueue = SyncQueue(prefs);
  final dioClient = ref.watch(dioClientProvider);
  
  final service = ConnectivityService(Connectivity(), syncQueue, dioClient);
  
  ref.onDispose(() => service.dispose());
  
  return service;
}
