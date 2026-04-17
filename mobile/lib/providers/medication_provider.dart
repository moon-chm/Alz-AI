import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/medication_service.dart';
import 'package:mobile/models/medication.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class MedicationState {
  final List<Medication> medications;
  final bool isLoading;
  final String? error;
  
  const MedicationState({
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });
  
  MedicationState copyWith({
    List<Medication>? medications,
    bool? isLoading,
    String? error,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MedicationNotifier extends StateNotifier<MedicationState> {
  final MedicationService _medicationService;
  final String? _patientId;
  
  MedicationNotifier(this._medicationService, this._patientId) : super(const MedicationState()) {
    if (_patientId != null) {
      fetchMedications();
    }
  }
  
  Future<void> fetchMedications() async {
    if (_patientId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final meds = await _medicationService.getTodaysMedications(_patientId);
      state = state.copyWith(medications: meds, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> confirmTaken(String medicationId) async {
    try {
      await _medicationService.confirmMedicationTaken(medicationId);
      final updatedMeds = state.medications.map((m) {
        if (m.id == medicationId) {
          m.isTaken = true;
        }
        return m;
      }).toList();
      state = state.copyWith(medications: updatedMeds);
    } catch (_) {
      // Handle error gracefully
    }
  }
  
  List<Medication> get dueNow => _medicationService.getMedicationsDueNow(state.medications);
}

final medicationServiceProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  return MedicationService(api);
});

final medicationProvider = StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  final service = ref.watch(medicationServiceProvider);
  final patientId = ref.watch(authProvider).identifier;
  return MedicationNotifier(service, patientId ?? '');
});
