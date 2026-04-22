import 'package:dio/dio.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/core/config/app_config.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storage;
  final Dio _refreshDio; // Dedicated Dio for refresh to avoid cycles
  final void Function() onUnauthenticated;

  AuthInterceptor({
    required StorageService storage,
    required Dio refreshDio,
    required this.onUnauthenticated,
  })  : _storage = storage,
        _refreshDio = refreshDio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          // Attempt refresh
          final response = await _refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200) {
            final data = response.data['data'];
            final newAccess = data['access_token'];
            final newRefresh = data['refresh_token'];

            await _storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);

            // Retry original request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccess';
            
            final retryResponse = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed
        }
      }
      
      // If we reach here, refresh failed or was not possible
      await _storage.clearAll();
      onUnauthenticated();
    }
    return handler.next(err);
  }
}
