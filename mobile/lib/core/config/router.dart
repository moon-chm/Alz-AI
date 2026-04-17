import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/auth/splash_screen.dart';
import 'package:mobile/screens/auth/login_screen.dart';
import 'package:mobile/screens/home/home_screen.dart';
import 'package:mobile/screens/conversation/conversation_screen.dart';
import 'package:mobile/screens/medicines/medicine_screen.dart';
import 'package:mobile/screens/medicines/medication_alert_screen.dart';
import 'package:mobile/screens/family/family_screen.dart';
import 'package:mobile/screens/family/face_recognition_screen.dart';
import 'package:mobile/screens/family/photo_collection_screen.dart';
import 'package:mobile/screens/help/help_screen.dart';
import 'package:mobile/screens/debug/debug_screen.dart';
import 'package:mobile/core/utils/transitions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Selectively watch only the isAuthenticated logic to minimize noise
  final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
  
  return GoRouter(
    initialLocation: splashRoute,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final hasPatientId = authState.patientId != null && authState.patientId!.isNotEmpty;
      
      final isSplash = state.uri.path == splashRoute;
      final isLogin = state.uri.path == loginRoute;
      
      // During the initial 2-second boot window, stay on splash
      if (isSplash) return null;
      
      if ((!isAuth || !hasPatientId) && !isLogin) return loginRoute;
      if (isAuth && hasPatientId && isLogin) return homeRoute;
      
      return null;
    },
    routes: [
      GoRoute(
        path: splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: loginRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: homeRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: conversationRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const ConversationScreen(),
        ),
      ),
      GoRoute(
        path: medicineRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const MedicineScreen(),
        ),
      ),
      GoRoute(
        path: medicationAlertRoute,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PremiumPageTransition(
            key: state.pageKey,
            child: MedicationAlertScreen(
              medicationName: extra['name'] ?? 'Medicine',
              dosage: extra['dosage'] ?? '',
              time: extra['time'] ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: familyRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const FamilyScreen(),
        ),
      ),
      GoRoute(
        path: faceRecognitionRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const FaceRecognitionScreen(),
        ),
      ),
      GoRoute(
        path: photoCollectionRoute,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PremiumPageTransition(
            key: state.pageKey,
            child: PhotoCollectionScreen(memberName: extra['name'] ?? 'Family'),
          );
        },
      ),
      GoRoute(
        path: helpRoute,
        pageBuilder: (context, state) => PremiumPageTransition(
          key: state.pageKey,
          child: const HelpScreen(),
        ),
      ),
      if (kDebugMode)
        GoRoute(
          path: debugRoute,
          pageBuilder: (context, state) => PremiumPageTransition(
            key: state.pageKey,
            child: const DebugScreen(),
          ),
        ),
    ],
  );
});
