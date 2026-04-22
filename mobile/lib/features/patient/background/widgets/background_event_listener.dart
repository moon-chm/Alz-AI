import 'package:alz_ai/core/providers/language_provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:alz_ai/core/services/tts_service.dart';
import 'package:alz_ai/features/patient/background/models/background_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackgroundEventListener extends ConsumerStatefulWidget {
  final Widget child;
  const BackgroundEventListener({super.key, required this.child});

  @override
  ConsumerState<BackgroundEventListener> createState() => _BackgroundEventListenerState();
}

class _BackgroundEventListenerState extends ConsumerState<BackgroundEventListener> {
  OverlayEntry? _fallOverlay;
  String? _behaviorMessage;
  bool _geofenceBreached = false;

  @override
  void initState() {
    super.initState();
    _listenToEvents();
  }

  void _listenToEvents() {
    final service = FlutterBackgroundService();
    
    service.on('geofence_event').listen((event) {
      if (event != null) {
        final backgroundEvent = BackgroundEvent.fromJson(event);
        if (backgroundEvent is GeofenceBreached) {
          setState(() => _geofenceBreached = true);
        } else if (backgroundEvent is GeofenceRestored) {
          setState(() => _geofenceBreached = false);
        }
      }
    });

    service.on('fall_event').listen((event) {
      if (event != null) {
        _showFallOverlay();
      }
    });

    service.on('behavior_event').listen((event) {
      if (event != null) {
        final backgroundEvent = BackgroundEvent.fromJson(event);
        if (backgroundEvent is BehaviorDeviation) {
          setState(() => _behaviorMessage = backgroundEvent.message);
        }
      }
    });

    service.on('connectivity_restored').listen((event) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Back online')),
      );
    });
  }

  void _showFallOverlay() {
    if (_fallOverlay != null) return;

    final lang = ref.read(languageProvider);
    final tts = ref.read(ttsServiceProvider);
    
    final msgs = {
      'hi': 'Aai, kya aap theek hain? Main family ko bata rahi hoon.',
      'mr': 'Aai, tumhi thik ahat ka? Mi family la sangte.',
      'en': 'Are you okay? I am alerting your family.',
    };

    tts.setLanguage(lang);
    tts.speak(msgs[lang] ?? msgs['en']!);

    _fallOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D21),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Fall Detected',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  msgs[lang] ?? msgs['en']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _dismissFallOverlay,
                        child: const Text('I AM FINE', style: TextStyle(color: Colors.green)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _dismissFallOverlay();
                          // Trigger SOS
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('HELP'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_fallOverlay!);
  }

  void _dismissFallOverlay() {
    _fallOverlay?.remove();
    _fallOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_behaviorMessage != null) {
          setState(() => _behaviorMessage = null);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_geofenceBreached)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildBanner(
                ref.read(languageProvider) == 'hi' 
                  ? 'Aai, aap ghar se door ja rahi hain.' 
                  : (ref.read(languageProvider) == 'mr' ? 'Aai, tumi ghara pasun dur challat ahat.' : 'You are moving away from home.'),
                Colors.orange,
              ),
            ),
          if (_behaviorMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildBanner(_behaviorMessage!, Colors.blue),
            ),
        ],
      ),
    );
  }

  Widget _buildBanner(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: color,
      child: SafeArea(
        bottom: false,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
