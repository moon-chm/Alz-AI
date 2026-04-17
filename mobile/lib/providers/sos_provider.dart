import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/websocket_provider.dart';
import 'package:mobile/models/websocket_event.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/providers/core_providers.dart';

enum SOSStatus { idle, sending, awaitingAck, success, retrying, failed }

class SOSState {
  final SOSStatus status;
  final int retryCount;
  final String? errorMessage;

  SOSState({this.status = SOSStatus.idle, this.retryCount = 0, this.errorMessage});

  SOSState copyWith({SOSStatus? status, int? retryCount, String? errorMessage}) {
    return SOSState(
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  final ApiService _api;
  final AsyncValue<WebSocketEvent>? _wsEvent;
  final String? _patientId;
  static const int maxRetries = 3;

  // Track the current active SOS trigger to debounce or avoid overlap
  bool _isProcessing = false;

  SOSNotifier(this._api, this._wsEvent, this._patientId) : super(SOSState()) {
    _listenForWebSocketAck();
  }

  void _listenForWebSocketAck() {
    if (state.status == SOSStatus.awaitingAck && _wsEvent?.hasValue == true) {
      final event = _wsEvent!.value!;
      if (event.type == WebSocketEventType.sosAlert) {
        AppLogger.info('SOS WebSockets: Acknowledgment received from backend for patient $_patientId.');
        state = state.copyWith(status: SOSStatus.success);
        NotificationService.showEmergencySOSConfirmation();
        _isProcessing = false;
      }
    }
  }

  Future<void> trigger({bool isRetry = false}) async {
    if (_isProcessing && !isRetry) {
      AppLogger.warn('SOS: Ignored trigger block, already processing.');
      return;
    }
    
    _isProcessing = true;
    int attempt = isRetry ? state.retryCount + 1 : 0;
    
    if (attempt > 0) {
      state = state.copyWith(status: SOSStatus.retrying, retryCount: attempt);
      AppLogger.info('SOS: Retrying attempt $attempt...');
    } else {
      state = state.copyWith(status: SOSStatus.sending, retryCount: 0, errorMessage: null);
      AppLogger.info('SOS: Trigger sequence started.');
    }

    try {
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 3), // Ensure fast timeout
          );
        }
      } catch (e) {
        AppLogger.warn('SOS: GPS fetch failed or timed out. Falling back to 0.0.');
      }

      final payload = {
        'lat': position?.latitude ?? 0.0,
        'lng': position?.longitude ?? 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'patient_id': _patientId,
      };

      AppLogger.info('SOS API: Sending payload to backend...');
      final response = await _api.post('/patient/sos', data: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('SOS API: Trigger successfully pushed. Transitioning -> awaitingAck.');
        state = state.copyWith(status: SOSStatus.awaitingAck);
        
        // Timeout for ACK
        Timer(const Duration(seconds: 8), () {
          if (mounted && state.status == SOSStatus.awaitingAck) {
            AppLogger.error('SOS WebSockets: Timeout waiting for ACK!', null);
            _handleFailure();
          }
        });
      } else {
        throw Exception('Non-200 API Status: ${response.statusCode}');
      }
    } catch (error) {
      AppLogger.error('SOS API: Network failure', error);
      _handleFailure();
    }
  }

  void _handleFailure() {
    if (state.retryCount < maxRetries) {
      final delaySeconds = (1 << state.retryCount) * 2; // 2s, 4s, 8s
      state = state.copyWith(status: SOSStatus.retrying, retryCount: state.retryCount + 1);
      AppLogger.info('SOS: Scheduled retry ${state.retryCount} in $delaySeconds seconds.');
      
      Timer(Duration(seconds: delaySeconds), () {
        if (mounted && state.status == SOSStatus.retrying) {
           trigger(isRetry: true);
        }
      });
    } else {
      AppLogger.error('SOS: Trigger FAILED permanently after $maxRetries retries.', null);
      state = state.copyWith(status: SOSStatus.failed);
      _isProcessing = false;
    }
  }

  void reset() {
    state = SOSState();
    _isProcessing = false;
  }
}

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final patientId = ref.watch(authProvider).identifier;
  AsyncValue<WebSocketEvent>? wsEvent;
  try {
     wsEvent = ref.watch(webSocketEventStreamProvider);
  } catch (_) {}
  
  return SOSNotifier(api, wsEvent, patientId);
});
