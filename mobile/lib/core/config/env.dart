import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Base URL for the API. 
  /// Defaults to localhost:8888 to support ADB Reverse for real device debugging.
  static String get apiBaseUrl => 
    dotenv.env['API_BASE_URL'] ?? 'http://localhost:8888/api';
  
  /// Base URL for the WebSocket.
  static String get wsBaseUrl => 
    dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8888';
  
  static bool get isProduction => 
    dotenv.env['ENVIRONMENT'] == 'production';
}
