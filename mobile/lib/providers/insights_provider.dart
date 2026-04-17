import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/vitals_provider.dart';
import 'package:mobile/services/notification_service.dart' as import_notification_service;

enum InsightSeverity { normal, warning, critical }

class InsightState {
  final String message;
  final InsightSeverity severity;
  
  InsightState(this.message, this.severity);
}

class InsightsNotifier extends StateNotifier<InsightState> {
  Timer? _debounceTimer;
  
  InsightsNotifier() : super(InsightState('Gathering baseline...', InsightSeverity.normal));

  void processNewVitals(VitalsState vitals) {
    if (vitals.hrHistory.isEmpty) return;
    
    // Throttle fast evaluation streams so UI doesn't judder unexpectedly
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _evaluate(vitals);
    });
  }

  void _evaluate(VitalsState vitals) {
    final hr = vitals.hr;
    
    if (hr == 0) return;

    InsightState nextState;
    if (hr < 50) {
      nextState = InsightState('Low heart rate detected', InsightSeverity.warning);
    } else if (hr > 100) {
      nextState = InsightState('Elevated heart rate', InsightSeverity.critical);
    } else {
      nextState = InsightState('Heart rate stable', InsightSeverity.normal);
    }
    
    if (nextState.severity != state.severity) {
       // Only push local notifications if we jumped severity boundaries (no spam)
       if (nextState.severity == InsightSeverity.critical) {
         import_notification_service.NotificationService.showHealthAlert('⚠️ Health Alert', nextState.message);
       } else if (nextState.severity == InsightSeverity.warning) {
         import_notification_service.NotificationService.showHealthAlert('Health Advisory', nextState.message);
       }
    }
    state = nextState;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// Watch the vitalsProvider and push updates into our insights state.
// We use a Provider that listens to vitalsState changes and drives the Notifier.
final insightsProvider = StateNotifierProvider<InsightsNotifier, InsightState>((ref) {
  final notifier = InsightsNotifier();
  
  ref.listen<VitalsState>(vitalsProvider, (previous, next) {
    notifier.processNewVitals(next);
  });
  
  // Trigger initial if values already exist
  notifier.processNewVitals(ref.read(vitalsProvider));
  
  return notifier;
});
