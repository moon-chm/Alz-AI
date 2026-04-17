import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WatchStatus extends StatelessWidget {
  final bool isConnected;

  const WatchStatus({super.key, this.isConnected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('BLE Watch integration coming soon!', style: TextStyle(fontSize: 22)),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConnected ? Colors.green.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.orange,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: const Duration(milliseconds: 1000)),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'GPS Active' : 'Locating...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
