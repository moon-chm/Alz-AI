import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/auth/providers/auth_state.dart';
import 'package:alz_ai/core/config/app_config.dart';
import 'package:alz_ai/features/patient/home/screens/tab_navigation_shell.dart';
import 'package:alz_ai/features/patient/background/widgets/background_event_listener.dart';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:alz_ai/features/auth/screens/login_screen.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/core/providers/language_provider.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'behavior_check') {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('patient_id');
      if (patientId == null) return Future.value(true);
      
      // We can't use Riverpod here easily, so we use a minimal implementation
      // Logic would go here to hit /caretaker/behavior
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Workmanager().initialize(callbackDispatcher);
  
  // Storage initialization
  const secureStorage = FlutterSecureStorage();
  StorageService(secureStorage);

  // Calculate next 8 AM
  final now = DateTime.now();
  var next8AM = DateTime(now.year, now.month, now.day, 8, 0);
  if (now.isAfter(next8AM)) {
    next8AM = next8AM.add(const Duration(days: 1));
  }
  final delay = next8AM.difference(now);

  await Workmanager().registerPeriodicTask(
    'behavior_task',
    'behavior_check',
    initialDelay: delay,
    frequency: const Duration(hours: 24),
  );

  runApp(
    const ProviderScope(
      child: AlzAiApp(),
    ),
  );
}

class AlzAiApp extends ConsumerWidget {
  const AlzAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateResource = ref.watch(authStateProvider);
    final lang = ref.watch(languageProvider);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(lang),
      builder: (context, child) {
        return BackgroundEventListener(child: child!);
      },
      home: authStateResource.when(
        data: (state) => state.when(
          unknown: () => const LoadingScreen(),
          authenticated: (role, level) => const TabNavigationShell(),
          unauthenticated: () => const LoginScreen(),
        ),
        loading: () => const LoadingScreen(),
        error: (err, stack) => ErrorScreen(error: err),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Object error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

