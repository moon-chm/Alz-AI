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
        return 'http://10.14.1.177/api/';
      case AppEnvironment.prod:
        // TEMPORARY: Local demo configuration using host IP.
        // Replace with 'https://app.alz-ai.org/api/' once SSL/Domain is deployed.
        return 'http://10.14.1.177/api/';
    }
  }

  static String get wsBaseUrl {
    const envUrl = String.fromEnvironment('WS_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    switch (environment) {
      case AppEnvironment.devPhysical:
      case AppEnvironment.devEmulator:
        return 'ws://10.14.1.177/ws/';
      case AppEnvironment.prod:
        // TEMPORARY: Local demo configuration using host IP.
        // Replace with 'wss://app.alz-ai.org/ws/' once SSL/Domain is deployed.
        return 'ws://10.14.1.177/ws/';
    }
  }

  static const String appName = 'ALZ-AI';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
