import 'package:alz_ai/core/config/app_config.dart';

void main() {
  print('🧪 Testing AppConfig Environment Logic...');
  print('=======================================');
  
  print('API Base URL: ${AppConfig.apiBaseUrl}');
  print('WS Base URL: ${AppConfig.wsBaseUrl}');
  
  if (AppConfig.apiBaseUrl.contains('10.230.253.93') || AppConfig.apiBaseUrl.contains('localhost')) {
    print('\nℹ️  Currently using fallback/default values.');
    print('To test with environment variables, run:');
    print('flutter run --dart-define=API_BASE_URL=https://my-api.com');
  } else {
    print('\n✅ Environment variable successfully detected!');
  }
  
  print('=======================================');
}
