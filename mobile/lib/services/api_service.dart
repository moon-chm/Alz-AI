import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:mobile/core/config/env.dart';
import 'package:mobile/core/utils/logger.dart';
import 'package:mobile/core/utils/exceptions.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  
  ApiService(this._dio, this._storage) {
    _setupInterceptors();
  }

  /// Explicitly initialize listeners that depend on platform channels.
  /// This should be called after the app is built to avoid initialization hangs.
  void initialize() {
    _setupConnectivityListener();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        AppLogger.info('🚀 API Request: [${options.method}] ${options.uri.toString()}');
        if (options.data != null) AppLogger.debug('Payload: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.info('✅ API Response: [${response.statusCode}] ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        AppLogger.error('❌ API Error: [${error.response?.statusCode}] ${error.requestOptions.path}', error);
        
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: 'auth_token');
          return handler.next(DioException(
            requestOptions: error.requestOptions,
            error: AuthException(),
          ));
        }

        // Map Dio errors to SaathiExceptions
        SaathiException saathiError;
        if (error.type == DioExceptionType.connectionError || 
            error.type == DioExceptionType.connectionTimeout) {
          saathiError = NetworkException();
          
          // Enqueue for offline sync if it's a POST
          if (error.requestOptions.method == 'POST' && error.requestOptions.data != null) {
            _enqueueOfflineRequest(error.requestOptions);
          }
        } else if (error.type == DioExceptionType.receiveTimeout || 
                   error.type == DioExceptionType.sendTimeout) {
          saathiError = TimeoutException();
        } else if (error.response?.statusCode != null && error.response!.statusCode! >= 500) {
          saathiError = ServerException();
        } else {
          saathiError = UnknownException(error.message ?? 'Network error');
        }

        handler.next(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: saathiError,
        ));
      },
    ));
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((results) {
      // connectivity_plus 6.0+ returns List<ConnectivityResult>
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        AppLogger.info('ApiService: Connectivity restored ($result). Flushing queues...');
        _flushOfflineQueue();
      }
    });
    // Initial flush attempt
    _flushOfflineQueue();
  }

  Future<void> _enqueueOfflineRequest(RequestOptions options) async {
     try {
       final isSOS = options.path.contains('/sos');
       if (isSOS) {
         await _enqueueSOS(options.data);
         return;
       }

       final queueStr = await _storage.read(key: 'offline_queue') ?? '[]';
       final List<dynamic> queue = jsonDecode(queueStr);
       queue.add({
         'path': options.path,
         'data': options.data,
         'timestamp': DateTime.now().toIso8601String(),
       });
       await _storage.write(key: 'offline_queue', value: jsonEncode(queue));
       AppLogger.warn('ApiService: Offline. Queued POST to ${options.path}');
     } catch (e) {
       AppLogger.error('ApiService: Queue failed', e);
     }
  }

  Future<void> _enqueueSOS(dynamic data) async {
    try {
      final queueStr = await _storage.read(key: 'sos_queue') ?? '[]';
      final List<dynamic> queue = jsonDecode(queueStr);
      if (queue.length >= 10) queue.removeAt(0);
      queue.add({
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _storage.write(key: 'sos_queue', value: jsonEncode(queue));
      AppLogger.warn('SOS QUEUED (Offline)');
    } catch (e) {
      AppLogger.error('ApiService: SOS Queue failed', e);
    }
  }

  Future<void> _flushOfflineQueue() async {
     await _flushGenericQueue();
     await _flushSOSQueue();
  }

  Future<void> _flushGenericQueue() async {
     try {
       final queueStr = await _storage.read(key: 'offline_queue');
       if (queueStr == null || queueStr == '[]') return;

       final List<dynamic> queue = jsonDecode(queueStr);
       final remainingQueue = [];
       for (var item in queue) {
         try {
            await _dio.post(item['path'], data: item['data']);
         } catch (e) {
            remainingQueue.add(item);
         }
       }
       await _storage.write(key: 'offline_queue', value: jsonEncode(remainingQueue));
     } catch (_) {}
  }

  Future<void> _flushSOSQueue() async {
    try {
      final queueStr = await _storage.read(key: 'sos_queue');
      if (queueStr == null || queueStr == '[]') return;

      final List<dynamic> queue = jsonDecode(queueStr);
      final remainingQueue = [];
      for (var item in queue) {
        try {
           await _dio.post('patient/sos', data: item['data']);
        } catch (e) {
           remainingQueue.add(item);
        }
      }
      await _storage.write(key: 'sos_queue', value: jsonEncode(remainingQueue));
    } catch (_) {}
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return _dio.get(path, queryParameters: params);
  }
  
  Future<Response> post(String path, {dynamic data, CancelToken? cancelToken}) async {
    return _dio.post(path, data: data, cancelToken: cancelToken);
  }
  
  Future<Response> saathiRequest(String path, FormData formData, {CancelToken? cancelToken}) async {
    return _dio.post(
      path,
      data: formData,
      cancelToken: cancelToken,
      options: Options(
        receiveTimeout: const Duration(seconds: 60), // Increased for AI
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response> uploadFile(String path, FormData formData, {int timeoutSeconds = 30}) async {
    return _dio.post(
      path,
      data: formData,
      options: Options(
        receiveTimeout: Duration(seconds: timeoutSeconds),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
  }

  Future<int> getSOSQueueSize() async {
    try {
      final queueStr = await _storage.read(key: 'sos_queue') ?? '[]';
      final List<dynamic> queue = jsonDecode(queueStr);
      return queue.length;
    } catch (_) {
      return 0;
    }
  }
}
