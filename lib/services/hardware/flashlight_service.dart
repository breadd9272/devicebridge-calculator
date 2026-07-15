import 'dart:async';

import 'package:torch_light/torch_light.dart';

import '../../core/utils/logger.dart';
import '../../models/command_result_model.dart';

class FlashlightService {
  static final FlashlightService _instance = FlashlightService._();
  factory FlashlightService() => _instance;
  FlashlightService._();

  bool _isOn = false;
  Timer? _blinkTimer;

  bool get isOn => _isOn;

  Future<CommandResult> turnOn(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    try {
      await TorchLight.enableTorch();
      _isOn = true;
      return CommandResult.success({
        'commandId': commandId,
        'status': 'on',
        'brightness': 100,
      });
    } catch (e) {
      AppLogger.e('FlashlightService', 'Turn on failed', e);
      return CommandResult.failure(commandId, 'flash_error: ${e.toString()}');
    }
  }

  Future<CommandResult> turnOff(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    try {
      await TorchLight.disableTorch();
      _isOn = false;
      return CommandResult.success({
        'commandId': commandId,
        'status': 'off',
      });
    } catch (e) {
      AppLogger.e('FlashlightService', 'Turn off failed', e);
      return CommandResult.failure(commandId, 'flash_error: ${e.toString()}');
    }
  }

  Future<CommandResult> toggle(Map<String, dynamic> payload) async {
    if (_isOn) {
      return turnOff(payload);
    } else {
      return turnOn(payload);
    }
  }

  Future<CommandResult> blink(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    final durationMs = payload['duration_ms'] as int? ?? 5000;
    final intervalMs = payload['interval_ms'] as int? ?? 500;
    int elapsed = 0;

    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      elapsed += intervalMs;
      if (elapsed >= durationMs) {
        timer.cancel();
        await TorchLight.disableTorch();
        _isOn = false;
        return;
      }
      if (_isOn) {
        await TorchLight.disableTorch();
        _isOn = false;
      } else {
        await TorchLight.enableTorch();
        _isOn = true;
      }
    });

    return CommandResult.success({
      'commandId': commandId,
      'pattern': 'blinking',
      'duration_ms': durationMs,
      'interval_ms': intervalMs,
    });
  }

  Future<CommandResult> sos(Map<String, dynamic> payload) async {
    final commandId = payload['commandId'] as String? ?? '';
    // SOS: ... --- ... (3 short, 3 long, 3 short)
    const pattern = <int>[
      200, 200, 200, 200, 200,
      600, 200, 600, 200, 600,
      200, 200, 200, 200, 200,
      1000, // final pause
    ];

    _blinkTimer?.cancel();
    int idx = 0;

    void runPattern() async {
      if (idx >= pattern.length) {
        await TorchLight.disableTorch();
        _isOn = false;
        return;
      }
      if (idx.isEven) {
        await TorchLight.enableTorch();
        _isOn = true;
      } else {
        await TorchLight.disableTorch();
        _isOn = false;
      }
      idx++;
      _blinkTimer = Timer(Duration(milliseconds: pattern[idx - 1]), runPattern);
    }

    runPattern();

    return CommandResult.success({
      'commandId': commandId,
      'pattern': 'SOS',
    });
  }

  void dispose() {
    _blinkTimer?.cancel();
    if (_isOn) {
      TorchLight.disableTorch();
    }
  }
}