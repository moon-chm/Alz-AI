import 'dart:async';
import 'package:alz_ai/core/storage/storage_service.dart';
import 'package:alz_ai/core/services/location_service.dart';
import 'package:alz_ai/core/services/tts_service.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/features/patient/help/models/help_models.dart';
import 'package:alz_ai/features/patient/help/repositories/help_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'help_controller.g.dart';

@riverpod
class Help extends _$Help {
  @override
  HelpState build() {
    _loadContacts();
    return const HelpState.loading();
  }

  Future<void> _loadContacts() async {
    final storage = ref.read(storageServiceProvider);
    final patientId = await storage.getPatientId();
    if (patientId == null) return;

    final result = await ref.read(helpRepositoryProvider).fetchContacts(patientId);
    result.fold(
      (l) => state = HelpState.error(failure: l),
      (list) => state = HelpState.loaded(contacts: list),
    );
  }

  Future<void> triggerSOS() async {
    final lang = ref.read(languageProvider);
    final tts = ref.read(ttsServiceProvider);

    // Step 1: Immediately start cascading calls (direct phone call) so response time is instant!
    final currentState = state;
    if (currentState is HelpStateLoaded) {
      _startCascadingCalls(currentState.contacts);
    }

    // Step 2: TTS speak (fire and forget, do not await)
    final voiceMessages = {
      'en': 'I am calling your family now. Do not worry.',
      'hi': 'माँ, मैं अभी प्रिया को कॉल कर रही हूँ। घबराइए मत।',
      'mr': 'आई, मी आता प्रियाला कॉल करतो. काळजी करू नका।',
    };
    tts.setLanguage(lang).then((_) {
      tts.speak(voiceMessages[lang] ?? voiceMessages['en']!);
    });

    // Step 3: GPS and Repository Call simultaneously (fire and forget, do not await)
    ref.read(storageServiceProvider).getPatientId().then((patientId) async {
       if (patientId == null) return;
       final locationResult = await ref.read(locationServiceProvider).getCurrentLocation();
       ref.read(helpRepositoryProvider).triggerSOS(
         patientId, 
         locationResult?.latitude, 
         locationResult?.longitude
       );
    });
  }

  Future<void> _startCascadingCalls(List<ContactItem> contacts) async {
    if (contacts.isEmpty) return;

    // Filter and sort: Primary first, then others
    final sortedContacts = [
      ...contacts.where((c) => c.isPrimary),
      ...contacts.where((c) => !c.isPrimary),
    ];

    for (var contact in sortedContacts) {
      final success = await _makePhoneCall(contact.phone);
      if (success) {
        // Wait 30 seconds to see if call is answered/concluded
        // Note: url_launcher doesn't provide answer status, so we use a fallback timer
        await Future.delayed(const Duration(seconds: 30));
      }
    }
  }

  Future<bool> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      return true;
    }
    return false;
  }

  Future<void> callContact(String phone) async {
    await _makePhoneCall(phone);
  }
}
