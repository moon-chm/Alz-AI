import 'package:alz_ai/features/auth/providers/auth_state.dart';
import 'package:alz_ai/core/theme/app_theme.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/features/patient/help/controllers/help_controller.dart';
import 'package:alz_ai/features/patient/help/models/help_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(helpProvider);
    final lang = ref.watch(languageProvider);

    final labels = {
      'en': {
        'title': 'Get Help',
        'contacts': 'Family Contacts',
        'calling': 'Calling...',
        'emergency': 'EMERGENCY SOS',
        'identify': 'IDENTIFY PERSON',
        'logout': 'Log Out',
      },
      'hi': {
        'title': 'मदद लें',
        'contacts': 'परिवार के सदस्य',
        'calling': 'कॉल कर रहे हैं...',
        'emergency': 'आपातकालीन SOS',
        'identify': 'व्यक्ति को पहचानें',
        'logout': 'लॉग आउट',
      },
      'mr': {
        'title': 'मदत मिळवा',
        'contacts': 'कुटुंबातील सदस्य',
        'calling': 'कॉल करत आहे...',
        'emergency': 'आणीबाणी SOS',
        'identify': 'व्यक्ती ओळखा',
        'logout': 'लॉग आउट',
      },
    }[lang] ?? {
      'en': {
        'title': 'Get Help',
        'contacts': 'Family Contacts',
        'calling': 'Calling...',
        'emergency': 'EMERGENCY SOS',
        'identify': 'IDENTIFY PERSON',
        'logout': 'Log Out',
      }
    }['en']!;

    return Scaffold(
      appBar: AppBar(
        title: Text(labels['title']!),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            sliver: SliverToBoxAdapter(
              child: _BigSosButton(
                label: labels['emergency']!,
                onTap: () => ref.read(helpProvider.notifier).triggerSOS(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                labels['contacts']!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          switch (state) {
            HelpStateLoading() => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            ),
            HelpStateLoaded(contacts: final contacts) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ContactCard(contact: contacts[index], labels: labels),
                childCount: contacts.length,
              ),
            ),
            HelpStateError(failure: final failure) => SliverFillRemaining(
              child: Center(child: Text(failure.message, style: const TextStyle(color: AppTheme.errorColor))),
            ),
          },
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, ref, labels),
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                label: Text(
                  labels['logout']!,
                  style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, Map<String, String> labels) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels['logout']!),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
            },
            child: Text(labels['logout']!, style: const TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _BigSosButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _BigSosButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
              gradient: const RadialGradient(
                colors: [AppTheme.errorColor, Color(0xFF991B1B)],
              ),
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  final ContactItem contact;
  final Map<String, String> labels;
  const _ContactCard({required this.contact, required this.labels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Semantics(
        label: 'Contact: ${contact.name}, ${contact.relationship}. Call button follows.',
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name[0] : '?',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            contact.relationship,
            style: TextStyle(
              color: contact.isPrimary ? AppTheme.successColor : AppTheme.textSecondary,
              fontWeight: contact.isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Semantics(
            button: true,
            label: 'Call ${contact.name}',
            child: SizedBox(
              width: 56,
              height: 56,
              child: IconButton(
                icon: const Icon(Icons.call, color: AppTheme.primaryColor, size: 32),
                onPressed: () => ref.read(helpProvider.notifier).callContact(contact.phone),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
