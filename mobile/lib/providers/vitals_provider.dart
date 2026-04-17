import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_service.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class VitalsState {
  final int hr;
  final int spo2;
  final int steps;
  final double sleep;
  final DateTime lastUpdated;
  final List<int> hrHistory;
  
  VitalsState({
    this.hr = 0,
    this.spo2 = 0,
    this.steps = 0,
    this.sleep = 0.0,
    DateTime? lastUpdated,
    this.hrHistory = const [],
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  VitalsState copyWith({
    int? hr,
    int? spo2,
    int? steps,
    double? sleep,
    DateTime? lastUpdated,
    List<int>? hrHistory,
  }) {
    return VitalsState(
      hr: hr ?? this.hr,
      spo2: spo2 ?? this.spo2,
      steps: steps ?? this.steps,
      sleep: sleep ?? this.sleep,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hrHistory: hrHistory ?? this.hrHistory,
    );
  }
}

class VitalsNotifier extends StateNotifier<VitalsState> {
  final HealthService _healthService;
  final String? _patientId;
  Timer? _timer;
  
  VitalsNotifier(this._healthService, this._patientId) : super(VitalsState()) {
    if (_patientId != null) {
      _init();
    }
  }
  
  Future<void> _init() async {
    final granted = await _healthService.requestPermissions();
    if (granted) {
      await fetchAndUpdate();
      // Fetch every 15 mins
      _timer = Timer.periodic(const Duration(minutes: 15), (_) => fetchAndUpdate());
    }
  }
  
  Future<void> fetchAndUpdate() async {
    if (_patientId == null) return;
    final vitals = await _healthService.fetchVitals();
    
    final int newHr = vitals['hr'] ?? 0;
    List<int> newHistory = List.from(state.hrHistory);
    if (newHr > 0) {
      newHistory.add(newHr);
      if (newHistory.length > 60) {
        newHistory.removeAt(0);
      }
    }
    
    state = state.copyWith(
      hr: newHr,
      spo2: vitals['spo2'] ?? 0,
      steps: vitals['steps'] ?? 0,
      sleep: vitals['sleep'] ?? 0.0,
      lastUpdated: DateTime.now(),
      hrHistory: newHistory,
    );
    await _healthService.pushVitalsToBackend(_patientId, vitals);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final healthServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  return HealthService(api);
});

final vitalsProvider = StateNotifierProvider<VitalsNotifier, VitalsState>((ref) {
  final service = ref.watch(healthServiceProvider);
  final patientId = ref.watch(authProvider).identifier;
  return VitalsNotifier(service, patientId);
});
