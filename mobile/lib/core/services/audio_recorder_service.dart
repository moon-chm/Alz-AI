import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

class AudioRecorderService {
  final _recorder = AudioRecorder();
  final _isRecordingController = StreamController<bool>.broadcast();

  Stream<bool> get isRecordingStream => _isRecordingController.stream;

  Future<void> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/saathi_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        const config = RecordConfig(encoder: AudioEncoder.aacLc);

        await _recorder.start(config, path: path);
        _isRecordingController.add(true);
      } else {
        // Permission denied - handle in UI or throw
        throw Exception('Microphone permission denied');
      }
    } catch (e) {
      _isRecordingController.add(false);
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _isRecordingController.add(false);
    return path;
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
    _isRecordingController.close();
  }
}
