import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_role.dart';
import 'package:mobile/core/config/routes.dart';
import 'package:mobile/core/config/theme.dart';
import '../../core/widgets/motions.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers = 
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = 
      List.generate(6, (index) => FocusNode());
      
  // Hardcoded to patient as per user requirement: "Mobile app is only for patient"
  final UserRole _selectedRole = UserRole.patient;
  bool _otpSent = false;
  String _errorMsg = '';
  
  // Timer for Resend OTP
  Timer? _resendTimer;
  int _secondsRemaining = 0;
  
  void _startResendTimer() {
    setState(() => _secondsRemaining = 30); // Start with 30s
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  void _requestOTP() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _errorMsg = 'Please enter your Patient ID');
      return;
    }

    setState(() => _errorMsg = '');
    
    try {
      await ref.read(authProvider.notifier).requestOTP(identifier, _selectedRole);
      setState(() {
        _otpSent = true;
        _startResendTimer();
      });
    } catch (e) {
      setState(() => _errorMsg = 'Failed to find Patient ID. Please check and try again.');
    }
  }
  
  void _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) return; // Wait for full entry
    
    final identifier = _identifierController.text.trim();
    
    try {
      await ref.read(authProvider.notifier).login(identifier, otp, _selectedRole);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(homeRoute);
      }
    } catch (e) {
      setState(() => _errorMsg = 'Invalid verification code. Please try again.');
      // Clear OTP fields on error
      for (var c in _otpControllers) { c.clear(); }
      _otpFocusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _identifierController.dispose();
    for (var c in _otpControllers) { c.dispose(); }
    for (var n in _otpFocusNodes) { n.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: !_otpSent ? _buildLoginView(isLoading) : _buildVerificationView(isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(bool isLoading) {
    return StaggeredColumn(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 40),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Welcome Back', 
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), 
          textAlign: TextAlign.center
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your Patient Account', 
          style: TextStyle(fontSize: 16, color: Colors.grey[600]), 
          textAlign: TextAlign.center
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Patient ID',
            hintText: 'e.g. ALZ-MH-2026-...',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 32),
        ScaleTap(
          onTap: isLoading ? null : _requestOTP,
          child: ElevatedButton(
            onPressed: null,
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Request OTP', style: TextStyle(fontSize: 20)),
          ),
        ),
        _buildErrorMessage(),
        const SizedBox(height: 32),
        Text(
          'Security code will be sent to your registered caretaker\'s mobile number.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerificationView(bool isLoading) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smartphone_rounded, color: AppColors.primary, size: 32),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Code', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 8),
            Text(
              'Sent to your registered caretaker', 
              style: TextStyle(fontSize: 16, color: Colors.grey[600]), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOTPField(index)),
            ),
            const SizedBox(height: 32),
            ScaleTap(
              onTap: isLoading ? null : _verifyOTP,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90CAF9), 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify & Proceed', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _secondsRemaining > 0
                  ? Text(
                      'Resend OTP in ${_secondsRemaining}s',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                    )
                  : TextButton(
                      onPressed: _requestOTP,
                      child: const Text('Resend OTP Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ),
            _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 45,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(counterText: '', border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          if (otpFull) _verifyOTP();
        },
      ),
    );
  }

  bool get otpFull => _otpControllers.every((c) => c.text.isNotEmpty);

  Widget _buildErrorMessage() {
    if (_errorMsg.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(_errorMsg, style: const TextStyle(color: AppColors.red, fontSize: 14), textAlign: TextAlign.center),
    );
  }
}
