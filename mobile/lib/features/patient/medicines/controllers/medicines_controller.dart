import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/core/websocket/websocket_manager.dart';
import 'package:alz_ai/features/patient/medicines/models/medicine_models.dart';
import 'package:alz_ai/features/patient/medicines/repositories/medicines_repository.dart';
import 'package:alz_ai/core/providers/level_provider.dart';
import 'package:alz_ai/core/services/tts_service.dart';
import 'package:alz_ai/shared/models/websocket_events.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medicines_controller.g.dart';

@riverpod
class Medicines extends _$Medicines {
  Timer? _pollingTimer;
  Timer? _checkTimer;
  DateTime? _alertStartTime;

  @override
  MedicinesState build() {
    _init();
    ref.onDispose(() {
      _pollingTimer?.cancel();
      _checkTimer?.cancel();
    });
    return const MedicinesState.loading();
  }

  Future<void> _init() async {
    await fetchSchedule();
    
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) => fetchSchedule());
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) => _checkMedicationTime());

    ref.listen(webSocketEventsProvider, (previous, next) {
      final value = next.asData?.value;
      if (value != null) {
        if (value is MedicationCleared) {
          final currentState = state;
          if (currentState is MedicinesStateAlertActive) {
            if (currentState.medication.id == value.medicationId) {
              fetchSchedule(); 
            }
          }
        }
      }
    });
  }

  Future<void> fetchSchedule() async {
    final patientId = await ref.read(storageServiceProvider).getPatientId();
    if (patientId == null) return;

    final result = await ref.read(medicinesRepositoryProvider).fetchTodayMedications(patientId);
    
    final prefs = await SharedPreferences.getInstance();
    
    result.fold(
      (l) {
        // Offline Fallback: Load from cache
        final cached = prefs.getString('medications_cache');
        if (cached != null) {
          final List<dynamic> json = jsonDecode(cached);
          final list = json.map((m) => MedicationItem.fromJson(m)).toList();
          state = MedicinesState.loaded(medications: list);
        } else {
          state = MedicinesState.error(failure: l);
        }
      },
      (list) {
        // Cache successful response
        final json = jsonEncode(list.map((m) => m.toJson()).toList());
        prefs.setString('medications_cache', json);
        state = MedicinesState.loaded(medications: list);
      }
    );
  }

  Future<void> markAsTaken(String medicationId) async {
    final patientId = await ref.read(storageServiceProvider).getPatientId();
    if (patientId == null) return;

    final result = await ref.read(medicinesRepositoryProvider).markTaken(medicationId, patientId);
    
    result.fold(
      (l) => null,
      (success) {
        final currentState = state;
        if (currentState is MedicinesStateLoaded) {
          final newList = currentState.medications.map((m) {
            if (m.id == medicationId) return m.copyWith(status: 'taken');
            return m;
          }).toList();
          state = MedicinesState.loaded(medications: newList);
        } else if (currentState is MedicinesStateAlertActive) {
          fetchSchedule();
        }
      },
    );
  }

  void _checkMedicationTime() {
    final currentState = state;
    if (currentState is MedicinesStateLoaded) {
      final now = DateTime.now();
      for (final med in currentState.medications) {
        if (med.status == 'upcoming') {
          try {
            final medTime = DateTime.parse(med.time);
            if (now.isAfter(medTime) || now.isAtSameMomentAs(medTime)) {
              _triggerAlert(med);
              break;
            }
          } catch (_) {}
        }
      }
    } else if (currentState is MedicinesStateAlertActive) {
      final now = DateTime.now();
      if (_alertStartTime != null) {
        final diff = now.difference(_alertStartTime!);

        if (diff.inMinutes >= 15 && !currentState.secondReminderSent) {
          _resendReminder(currentState.medication.id);
        }

        if (diff.inMinutes >= 30) {
          _triggerCaretakerAlert(currentState.medication.id);
        }
      }
    }
  }

  void _triggerAlert(MedicationItem med) async {
    _alertStartTime = DateTime.now();
    final level = ref.read(patientLevelProvider);
    
    state = MedicinesState.alertActive(
      medication: med,
      isConfirmVisible: level < 3,
    );

    final patientId = await ref.read(storageServiceProvider).getPatientId();
    if (patientId != null) {
      final result = await ref.read(medicinesRepositoryProvider).fetchSaathiReminder(patientId, med.id);
      result.fold((l) => null, (msg) {
        ref.read(ttsServiceProvider).speak(msg);
      });
    }

    if (level == 3) {
      Future.delayed(const Duration(seconds: 30), () {
        final s = state;
        if (s is MedicinesStateAlertActive && s.medication.id == med.id) {
          state = s.copyWith(isConfirmVisible: true);
        }
      });
    }
  }

  Future<void> _resendReminder(String medId) async {
    final patientId = await ref.read(storageServiceProvider).getPatientId();
    if (patientId == null) return;

    final result = await ref.read(medicinesRepositoryProvider).fetchSaathiReminder(patientId, medId);
    result.fold((l) => null, (msg) {
      ref.read(ttsServiceProvider).speak(msg);
      final s = state;
      if (s is MedicinesStateAlertActive) {
        state = s.copyWith(secondReminderSent: true);
      }
    });
  }

  Future<void> _triggerCaretakerAlert(String medId) async {
    final patientId = await ref.read(storageServiceProvider).getPatientId();
    if (patientId == null) return;

    ref.read(medicinesRepositoryProvider).sendMissedAlert(patientId, medId);
  }
}
