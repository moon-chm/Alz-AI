import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/routes.dart';
import '../../providers/auth_provider.dart';
import 'package:mobile/core/config/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // Restore the public call to auth initialization
    await ref.read(authProvider.notifier).initialize();
    
    if (!mounted) return;

    final authState = ref.read(authProvider);
    final isAuth = authState.isAuthenticated;
    final hasPatientId = authState.patientId != null && authState.patientId!.isNotEmpty;

    if (isAuth && hasPatientId) {
      Navigator.of(context).pushReplacementNamed(homeRoute);
    } else {
      Navigator.of(context).pushReplacementNamed(loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF1557B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: AppColors.primary, size: 60),
              ),
              const SizedBox(height: 32),
              const Text(
                'Alz-AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your SAATHI is here',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
