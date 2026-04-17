import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'isar_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  // Normally we would initialize directory path here.
  throw UnimplementedError('Isar init runs in main() before provider is ready');
}
