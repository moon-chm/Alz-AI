import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/features/patient/family/controllers/family_controller.dart';
import 'package:alz_ai/features/patient/help/controllers/help_controller.dart';
import 'package:alz_ai/features/patient/family/models/family_models.dart';
import 'package:alz_ai/features/patient/help/models/help_models.dart';
import 'package:alz_ai/core/providers/language_provider.dart';

class FaceRecognitionView extends ConsumerStatefulWidget {
  const FaceRecognitionView({super.key});

  @override
  ConsumerState<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends ConsumerState<FaceRecognitionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyControllerProvider.notifier).identifyPerson();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyControllerProvider);
    final helpState = ref.watch(helpProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060A18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Identification'),
      ),
      body: switch (state) {
        FamilyStateLoading() => const Center(child: CircularProgressIndicator(color: Color(0xFF00C8FF))),
        FamilyStateError(failure: final f) => Center(child: Text(f.message, style: const TextStyle(color: Colors.redAccent))),
        FamilyStateLoaded(members: _, identificationResult: final result) => _buildResultView(context, result, helpState, language),
      },
    );
  }

  Widget _buildResultView(BuildContext context, FamilyIdentifyResponse? result, HelpState helpState, String language) {
    if (result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text('Processing image...', style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref.read(familyControllerProvider.notifier).identifyPerson(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (result.matched) ...[
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
            const SizedBox(height: 24),
            Text(
              result.name ?? 'Family Member',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              result.relationship ?? '',
              style: const TextStyle(color: Color(0xFF00C8FF), fontSize: 20),
            ),
            const SizedBox(height: 24),
            if (result.description != null)
              Text(
                result.description!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
          ] else ...[
            const Icon(Icons.help_outline, color: Colors.orangeAccent, size: 60),
            const SizedBox(height: 24),
            Text(
              _getNoMatchLabel(language),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildHelpSection(helpState),
          ],
          const Spacer(),
          TextButton(
            onPressed: () {
              ref.read(familyControllerProvider.notifier).clearIdentification();
              Navigator.of(context).pop();
            },
            child: const Text('Close', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(HelpState helpState) {
    return switch (helpState) {
      HelpStateLoading() => const CircularProgressIndicator(),
      HelpStateError() => const SizedBox(),
      HelpStateLoaded(contacts: final contacts) => Column(
          children: contacts.take(2).map((c) => _QuickCallButton(
            name: c.name, 
            onTap: () => ref.read(helpProvider.notifier).callContact(c.phone)
          )).toList(),
        ),
    };
  }

  String _getNoMatchLabel(String lang) {
    switch (lang) {
      case 'hi': return 'पसंद नहीं आया? परिवार को कॉल करें।';
      case 'mr': return 'ओळखले नाही? फॅमिली ला कॉल करा।';
      default: return 'Could not recognize. Call family?';
    }
  }
}

class _QuickCallButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _QuickCallButton({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onTap,
        icon: const Icon(Icons.call, color: Color(0xFF00C8FF)),
        label: Text('Call $name', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
