// lib/services/voice_recorder_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    try {
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${directory.path}/voice_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      //   print('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      //  print('Error stopping recording: $e');
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _isRecording = false;

      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _recordingPath = null;
    } catch (e) {
      //  print('Error canceling recording: $e');
    }
  }

  Future<Duration?> getRecordingDuration(String path) async {
    return null;
  }

  /// Dispose
  void dispose() {
    _audioRecorder.dispose();
  }
}
