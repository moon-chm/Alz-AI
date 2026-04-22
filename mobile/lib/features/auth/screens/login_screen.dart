import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/auth/controllers/login_controller.dart';
import 'package:alz_ai/features/auth/controllers/login_state.dart';
import 'package:alz_ai/core/providers/language_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _otpController = TextEditingController();
  static const String _authRole = 'patient';

  @override
  void dispose() {
    _idController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': {
        'title': 'Welcome to ALZ-AI',
        'subtitle': 'Secure authentication for your safety',
        'id_label': 'Patient ID',
        'id_hint': 'Enter your Patient ID (e.g. ALZ-2024-001)',
        'request_otp': 'Request OTP',
        'otp_sent': 'Entering OTP sent to ID: ',
        'otp_label': 'OTP Code',
        'otp_hint': '123456',
        'verify_login': 'Verify & Login',
        'change_id': 'Change Patient ID',
      },
      'hi': {
        'title': 'ALZ-AI में आपका स्वागत है',
        'subtitle': 'आपकी सुरक्षा के लिए सुरक्षित प्रमाणीकरण',
        'id_label': 'पेशेंट ID',
        'id_hint': 'Apna Patient ID dalein.',
        'request_otp': 'OTP मंगवाएं',
        'otp_sent': 'ID पर भेजा गया OTP डालें: ',
        'otp_label': 'OTP कोड',
        'otp_hint': '123456',
        'verify_login': 'सत्यापित करें और लॉगिन करें',
        'change_id': 'पेशेंट ID बदलें',
      },
      'mr': {
        'title': 'ALZ-AI मध्ये आपले स्वागत आहे',
        'subtitle': 'तुमच्या सुरक्षिततेसाठी सुरक्षित प्रमाणीकरण',
        'id_label': 'पेशंट ID',
        'id_hint': 'Tumcha Patient ID ghala.',
        'request_otp': 'OTP मागवा',
        'otp_sent': 'ID वर पाठवलेला OTP प्रविष्ट करा: ',
        'otp_label': 'OTP कोड',
        'otp_hint': '123456',
        'verify_login': 'सत्यापित करा आणि लॉगिन करा',
        'change_id': 'पेशंट ID बदला',
      },
    }[lang] ?? {
      'en': {
        'title': 'Welcome to ALZ-AI',
        'subtitle': 'Secure authentication for your safety',
        'id_label': 'Patient ID',
        'id_hint': 'Enter your Patient ID',
        'request_otp': 'Request OTP',
      }
    }['en']!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF01040D), Color(0xFF051125)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildHeader(labels['title']!, labels['subtitle']!),
                const SizedBox(height: 48),
                Expanded(
                  child: SingleChildScrollView(
                    child: state.maybeWhen(
                      otpSent: () => _buildOtpView(labels),
                      verifyingOtp: () => _buildLoadingView('Verifying OTP...'),
                      requestingOtp: () => _buildLoadingView('Requesting OTP...'),
                      success: () => _buildSuccessView(),
                      orElse: () => _buildIdView(labels),
                    ),
                  ),
                ),
                if (state.maybeWhen(failure: (_) => true, orElse: () => false))
                  _buildError(state.maybeWhen(failure: (msg) => msg, orElse: () => '')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00C8FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00C8FF).withOpacity(0.2)),
          ),
          child: const Icon(Icons.security_rounded, color: Color(0xFF00C8FF), size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildIdView(Map<String, String> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const SizedBox(height: 32),
        _textField(
          controller: _idController,
          label: labels['id_label']!,
          hint: labels['id_hint']!,
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 40),
        _actionButton(
          label: labels['request_otp']!,
          onPressed: () {
            ref.read(loginControllerProvider.notifier).requestOtp(
              _idController.text,
              _authRole,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOtpView(Map<String, String> labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labels['otp_sent']}${_idController.text}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 32),
        _textField(
          controller: _otpController,
          label: labels['otp_label']!,
          hint: labels['otp_hint']!,
          icon: Icons.lock_clock_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 40),
        _actionButton(
          label: labels['verify_login']!,
          onPressed: () {
            ref.read(loginControllerProvider.notifier).verifyOtp(
              _idController.text,
              _otpController.text,
              _authRole,
            );
          },
        ),
        TextButton(
          onPressed: () => ref.read(loginControllerProvider.notifier).reset(),
          child: Text(labels['change_id']!, style: const TextStyle(color: Color(0xFF00C8FF))),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: const Color(0xFF00C8FF), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C8FF),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoadingView(String message) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(color: Color(0xFF00C8FF)),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 60),
          Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 64),
          SizedBox(height: 24),
          Text('Login Successful', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
        ],
      ),
    );
  }
}
