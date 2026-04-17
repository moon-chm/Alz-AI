import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:mobile/models/patient.dart';
import 'auth_provider.dart';
import 'core_providers.dart';

class PatientState {
  final Patient? patient;
  final bool isLoading;
  final String? error;
  
  const PatientState({
    this.patient,
    this.isLoading = false,
    this.error,
  });
  
  PatientState copyWith({
    Patient? patient,
    bool? isLoading,
    String? error,
  }) {
    return PatientState(
      patient: patient ?? this.patient,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  final ApiService _api;
  final String? _patientId;
  
  PatientNotifier(this._api, this._patientId) : super(const PatientState()) {
    if (_patientId != null) {
      fetchPatient();
    }
  }
  
  Future<void> fetchPatient() async {
    if (_patientId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.get('/patient/profile', params: {'patient_id': _patientId});
      final patient = Patient.fromJson(response.data);
      state = state.copyWith(patient: patient, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final patientId = ref.watch(authProvider).identifier;
  return PatientNotifier(api, patientId);
});
