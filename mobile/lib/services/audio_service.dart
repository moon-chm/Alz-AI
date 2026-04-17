import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  String? _currentTempPath;
  
  bool get isRecording => _isRecording;
  bool get isPlaying => _player.playing;
  
  Future<void> startRecording() async {
    if (_isRecording) return;
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentTempPath = '${dir.path}/saathi_$timestamp.m4a';
    
    if (await _recorder.hasPermission()) {
      await _recorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _currentTempPath!,
      );
      _isRecording = true;
    } else {
      throw Exception('Microphone permission denied');
    }
  }
  
  Future<String> stopRecording() async {
    await _recorder.stop();
    _isRecording = false;
    return _currentTempPath!;
  }
  
  Future<void> playAudio(String urlOrAsset) async {
    await stopPlayback(); 
    
    if (urlOrAsset.startsWith('assets/')) {
      await _player.setAsset(urlOrAsset);
    } else {
      await _player.setUrl(urlOrAsset);
    }
    await _player.play();
  }
  
  Future<void> stopPlayback() async {
    if (_player.playing) {
      await _player.stop();
    }
  }
  
  Future<void> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore
    }
  }
  
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
  
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
}
