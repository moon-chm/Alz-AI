import 'package:flutter/material.dart';
import 'package:mobile/core/config/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('How to use this app', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          
          _HelpItem(
            icon: Icons.mic, 
            color: AppColors.primary,
            title: 'Talk to SAATHI',
            description: 'Hold the big microphone button to talk. SAATHI will listen and reply back to you.',
          ),
          
          _HelpItem(
            icon: Icons.medication, 
            color: AppColors.green,
            title: 'Medicines',
            description: 'We will remind you when it is time to take your medicines. Just tap the "Taken" button.',
          ),
          
          _HelpItem(
            icon: Icons.document_scanner, 
            color: Colors.blue,
            title: 'Who is this?',
            description: 'If you forget someone, take their photo using the "Who is this?" button in the Family tab.',
          ),
          
          _HelpItem(
            icon: Icons.emergency, 
            color: AppColors.red,
            title: 'Emergency Help',
            description: 'Hold the red SOS button at the bottom of the home screen for 3 seconds to call your family.',
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 20, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
