import 'package:dio/dio.dart';
import 'package:alz_ai/core/config/app_config.dart';
import 'package:alz_ai/core/error/app_failure.dart';
import 'package:alz_ai/core/network/auth_interceptor.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio);

  Future<Either<AppFailure, T>> request<T>(
    Future<Response<T>> Function(Dio dio) call,
  ) async {
    try {
      final response = await call(_dio);
      return right(response.data as T);
    } on DioException catch (e) {
      return left(_mapDioException(e));
    } catch (e) {
      return left(AppFailure.unknownFailure(e.toString()));
    }
  }

  AppFailure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppFailure.timeoutFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server Error';
        if (statusCode == 401) return const AppFailure.authFailure();
        return AppFailure.serverFailure(statusCode: statusCode, message: message);
      case DioExceptionType.connectionError:
        return const AppFailure.networkFailure();
      default:
        return AppFailure.unknownFailure(e.message);
    }
  }
}

@riverpod
DioClient dioClient(Ref ref) {
  final storage = ref.watch(storageServiceProvider);
  
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  final refreshDio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(
    storage: storage,
    refreshDio: refreshDio,
    onUnauthenticated: () {
      // Future: Navigate to login or clear auth state
    },
  ));

  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return DioClient(dio);
}
