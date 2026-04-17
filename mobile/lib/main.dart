import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/theme.dart';
import 'core/config/routes.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'core/utils/logger.dart';
import 'services/notification_service.dart';

void main() {
  // 1. Native bridge initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Direct-to-UI Launch (Bypasses GoRouter Deadlocks)
  runApp(
    const ProviderScope(
      child: AlzAIApp(),
    ),
  );

  // 3. Deferred background services
  _initServices();
}

Future<void> _initServices() async {
  try {
    await Future.delayed(const Duration(seconds: 1));
    await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 2));
    await NotificationService.initialize().timeout(const Duration(seconds: 2));
  } catch (e) {
    AppLogger.warn('Secondary services deferred: $e');
  }
}

class AlzAIApp extends StatelessWidget {
  const AlzAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alz-AI',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      // Force navigation map since we are not using .router for the boot phase
      routes: {
        splashRoute: (context) => const SplashScreen(),
        loginRoute: (context) => const LoginScreen(),
        homeRoute: (context) => const HomeScreen(),
      },
      initialRoute: splashRoute,
    );
  }
}
