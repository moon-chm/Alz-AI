import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/saathi_provider.dart';
import 'package:mobile/core/widgets/saathi_speaking.dart';
import 'package:mobile/core/config/theme.dart';
import 'package:mobile/core/utils/exceptions.dart';
import 'package:mobile/core/utils/logger.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen for message count changes to trigger scroll (Side Effect ONLY)
    ref.listen<int>(
      saathiProvider.select((s) => s.messages.length),
      (previous, next) {
        if (next > (previous ?? 0)) {
          AppLogger.debug('UI: New message detected. Scrolling...');
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      },
    );

    // 2. Listen for errors to show SnackBars (Side Effect ONLY)
    ref.listen<SaathiException?>(
      saathiProvider.select((s) => s.lastError),
      (previous, next) {
        if (next != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: AppColors.red,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () => ref.read(saathiProvider.notifier).clearError(),
              ),
            ),
          );
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _SaathiHeader(),
            const Expanded(
              child: Column(
                children: [
                  _SaathiAvatarSection(),
                  Expanded(child: _TranscriptList()),
                ],
              ),
            ),
            const _MicButtonSection(),
          ],
        ),
      ),
    );
  }
}

class _SaathiHeader extends ConsumerWidget {
  const _SaathiHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = ref.watch(saathiProvider.select((s) => s.lastError != null));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        children: [
          IconButton(
            iconSize: 48,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Center(child: Text('SAATHI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
          ),
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError ? Colors.orange : AppColors.green,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _SaathiAvatarSection extends ConsumerWidget {
  const _SaathiAvatarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpeaking = ref.watch(saathiProvider.select((s) => s.isSpeaking));
    final hasError = ref.watch(saathiProvider.select((s) => s.lastError is NetworkException));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isSpeaking
        ? const SAATHISpeaking()
        : Hero(
            tag: 'saathi_avatar',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: hasError ? Colors.grey.shade300 : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasError ? Icons.cloud_off : Icons.mic, 
                  size: 60, 
                  color: hasError ? Colors.grey : AppColors.primary
                ),
              ),
            ),
          ),
    );
  }
}

class _TranscriptList extends ConsumerWidget {
  const _TranscriptList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(saathiProvider.select((s) => s.messages));
    final scrollController = (context.findAncestorStateOfType<_ConversationScreenState>())?._scrollController;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                bottomLeft: !isUser ? Radius.zero : const Radius.circular(20),
              ),
              border: isUser ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              msg['text']!,
              style: TextStyle(fontSize: 22, color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        );
      },
    );
  }
}

class _MicButtonSection extends ConsumerWidget {
  const _MicButtonSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = ref.watch(saathiProvider.select((s) => s.isListening));
    final isProcessing = ref.watch(saathiProvider.select((s) => s.isProcessing));

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0, top: 16.0),
      child: Column(
        children: [
          GestureDetector(
            onLongPressStart: (_) => ref.read(saathiProvider.notifier).startListening(),
            onLongPressEnd: (_) => ref.read(saathiProvider.notifier).stopListeningAndSend(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isListening ? AppColors.red : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: isListening ? [
                  BoxShadow(color: AppColors.red.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                ] : [],
              ),
              child: isProcessing
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Icon(
                    Icons.mic, 
                    size: 48, 
                    color: isListening ? Colors.white : Colors.grey.shade600
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isProcessing ? 'Processing...' : 'Hold to speak', 
            style: const TextStyle(fontSize: 24, color: Colors.grey)
          ),
        ],
      ),
    );
  }
}
