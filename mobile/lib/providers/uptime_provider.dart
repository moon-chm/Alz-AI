import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appStartTimeProvider = Provider<DateTime>((ref) => DateTime.now());

final uptimeProvider = StreamProvider<String>((ref) {
  final startTime = ref.watch(appStartTimeProvider);
  
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final diff = DateTime.now().difference(startTime);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  });
});
