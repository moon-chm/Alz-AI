import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/ble_service.dart';
import '../core/config/env.dart';

final dioProvider = Provider((ref) => Dio(BaseOptions(
  baseUrl: Env.apiBaseUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Content-Type': 'application/json'},
)));

final storageProvider = Provider((ref) => const FlutterSecureStorage());

final apiServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(storageProvider);
  return ApiService(dio, storage);
});

final locationServiceProvider = Provider((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final audioServiceProvider = Provider((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bleServiceProvider = Provider((ref) => BLEService());
