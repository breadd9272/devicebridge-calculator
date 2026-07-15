import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/utils/logger.dart';
import '../../models/command_result_model.dart';

class MicrophoneService {
  static final MicrophoneService _instance = MicrophoneService._();
  factory MicrophoneService() => _instance;
  MicrophoneService._();

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<CommandResult> startRecording(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    final durationSeconds = payload['duration_seconds'] as int? ?? 30;
    final sampleRate = payload['sample_rate'] as int? ?? 16000;

    try {
      if (_isRecording) {
        return CommandResult.failure(commandId, 'already_recording: Microphone is already in use');
      }

      if (!await checkPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          return CommandResult.failure(commandId, 'permission_denied: Microphone permission not granted');
        }
      }

      if (!await _recorder.hasPermission()) {
        return CommandResult.failure(commandId, 'permission_denied: Recording permission denied');
      }

      final dir = await Directory.systemTemp.createTemp('audio_');
      _currentRecordingPath = '${dir.path}/recording.m4a';

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: sampleRate,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;

      // Auto-stop after duration
      if (durationSeconds > 0) {
        Timer(Duration(seconds: durationSeconds), () async {
          if (_isRecording) {
            await stopRecording({'commandId': commandId});
          }
        });
      }

      return CommandResult.success({
        'commandId': commandId,
        'status': 'recording',
        'max_duration': durationSeconds,
      });
    } catch (e) {
      AppLogger.e('MicrophoneService', 'Start recording failed', e);
      return CommandResult.failure(commandId, 'start_failed: ${e.toString()}');
    }
  }

  Future<CommandResult> stopRecording(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';

    try {
      if (!_isRecording) {
        return CommandResult.failure(commandId, 'not_recording: No active recording');
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null || !File(path).existsSync()) {
        return CommandResult.failure(commandId, 'file_error: Recording file not found');
      }

      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64Audio = 'data:audio/mp4;base64,${_encodeBase64(bytes)}';

      // Cleanup
      try {
        if (_currentRecordingPath != null) {
          final dir = File(_currentRecordingPath!).parent;
          if (await dir.exists()) await dir.delete(recursive: true);
        }
      } catch (_) {}

      _currentRecordingPath = null;

      return CommandResult.success({
        'commandId': commandId,
        'audio_base64': base64Audio,
        'audio_size_bytes': bytes.length,
        'duration': 'unknown',
        'format': 'm4a',
      });
    } catch (e) {
      AppLogger.e('MicrophoneService', 'Stop recording failed', e);
      _isRecording = false;
      return CommandResult.failure(commandId, 'stop_failed: ${e.toString()}');
    }
  }

  String _encodeBase64(List<int> bytes) {
    return String.fromCharCodes(bytes.map((b) => b));
  }

  void dispose() {
    if (_isRecording) {
      _recorder.stop();
      _isRecording = false;
    }
    _recorder.dispose();
  }
}