import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:alz_ai/core/theme/app_theme.dart';

class ErrorStateWidget extends ConsumerWidget {
  final VoidCallback onRetry;
  final String? message;

  const ErrorStateWidget({
    super.key,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    
    final labels = {
      'en': 'Something went wrong. Please try again.',
      'hi': 'Kuch galat hua. Dobara try karein.',
      'mr': 'Kahi chukle. Parat try kara.',
    };

    final retryLabels = {
      'en': 'Retry',
      'hi': 'दोबारा कोशिश करें',
      'mr': 'पुन्हा प्रयत्न करा',
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? labels[lang] ?? labels['en']!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabels[lang] ?? retryLabels['en']!),
          ),
        ],
      ),
    ),
  );
}
}
