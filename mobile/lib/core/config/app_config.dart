import 'package:flutter/foundation.dart';

enum AppEnvironment { devPhysical, devEmulator, prod }

class AppConfig {
  static const AppEnvironment environment = kDebugMode ? AppEnvironment.devPhysical : AppEnvironment.prod;

  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    switch (environment) {
      case AppEnvironment.devPhysical:
      case AppEnvironment.devEmulator:
        return 'http://10.230.253.93/api';
      case AppEnvironment.prod:
        return 'https://app.alz-ai.org/api';
    }
  }

  static String get wsBaseUrl {
    const envUrl = String.fromEnvironment('WS_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    switch (environment) {
      case AppEnvironment.devPhysical:
      case AppEnvironment.devEmulator:
        return 'ws://192.168.1.10/ws';
      case AppEnvironment.prod:
        return 'wss://app.alz-ai.org/ws';
    }
  }

  static const String appName = 'ALZ-AI';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
