import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLifecycleProvider = StateProvider<AppLifecycleState>((ref) => AppLifecycleState.resumed);

class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }
}
