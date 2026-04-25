import 'package:alz_ai/core/network/dio_client.dart';
import 'package:alz_ai/features/patient/home/models/habit.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'habit_repository.g.dart';

class HabitRepository {
  final DioClient _dio;

  HabitRepository(this._dio);

  Future<Either<AppFailure, List<Habit>>> fetchHabits(String patientId) async {
    return _dio.request((dio) => dio.get(
      'patient/habits', 
      queryParameters: {'patient_id': patientId},
    )).then((result) => result.map((data) {
      if (data is List) {
        return data.map((e) => Habit.fromJson(e)).toList();
      }
      return [];
    }));
  }
}

@riverpod
HabitRepository habitRepository(Ref ref) {
  return HabitRepository(ref.watch(dioClientProvider));
}
