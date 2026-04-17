import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  static void log(String message, {LogLevel level = LogLevel.info, Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [${level.name.toUpperCase()}] $message';

    if (error != null) {
      dev.log(logLine, error: error, stackTrace: stackTrace, name: 'Alz-AI');
    } else {
      dev.log(logLine, name: 'Alz-AI');
    }
    
    // For console visibility during development
    if (kDebugMode) {
      print(logLine);
      if (error != null) print('Error: $error');
    }
  }

  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warn(String message) => log(message, level: LogLevel.warn);
  static void error(String message, [Object? error, StackTrace? stackTrace]) => 
    log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
}
