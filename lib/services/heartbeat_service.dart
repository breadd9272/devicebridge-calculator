import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/app_settings.dart';
import '../../models/heartbeat_model.dart';
import '../../models/device_status.dart';
import '../hardware/device_info_service.dart';
import 'socket_io_service.dart';

class HeartbeatService {
  static final HeartbeatService _instance = HeartbeatService._();
  factory HeartbeatService() => _instance;
  HeartbeatService._();

  Timer? _timer;
  final _battery = Battery();
  final _connectivity = Connectivity();
  final _deviceInfo = DeviceInfoService();

  int _uptimeSeconds = 0;
  Timer? _uptimeTimer;

  void start() {
    stop();

    final interval = AppSettings.heartbeatInterval;
    AppLogger.i('Heartbeat', 'Starting heartbeat every ${interval}s');

    _uptimeTimer?.cancel();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _uptimeSeconds++;
    });

    _timer = Timer.periodic(Duration(seconds: interval), (_) async {
      await _sendHeartbeat();
    });

    // Send first heartbeat immediately
    _sendHeartbeat();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _uptimeTimer?.cancel();
    _uptimeTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    try {
      final deviceId = await _deviceInfo.getDeviceId();
      final batteryLevel = await _battery.batteryLevel;
      final isCharging = await _battery.batteryState.then(
        (s) => s == BatteryState.charging || s == BatteryState.full,
      );

      final connectivityResult = await _connectivity.checkConnectivity();
      String networkType = 'unknown';
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        networkType = 'wifi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        networkType = 'cellular';
      }

      final heartbeat = HeartbeatModel(
        deviceId: deviceId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        networkType: networkType,
        activeCapabilities: ['camera', 'microphone', 'flashlight', 'storage', 'screen'],
        deviceName: AppSettings.deviceName,
      );

      SocketIOService().sendHeartbeat(heartbeat);
      AppLogger.d('Heartbeat', 'Sent: battery=$batteryLevel%, network=$networkType');
    } catch (e) {
      AppLogger.e('Heartbeat', 'Failed to send heartbeat', e);
    }
  }

  Future<DeviceStatus> getCurrentStatus() async {
    final batteryLevel = await _battery.batteryLevel;
    final isCharging = await _battery.batteryState.then(
      (s) => s == BatteryState.charging || s == BatteryState.full,
    );

    final connectivityResult = await _connectivity.checkConnectivity();
    String networkType = 'unknown';
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      networkType = 'wifi';
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      networkType = 'cellular';
    }

    final storageUsed = await _deviceInfo.getStorageUsedBytes();
    final storageTotal = await _deviceInfo.getStorageTotalBytes();

    return DeviceStatus(
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      networkType: networkType,
      uptimeSeconds: _uptimeSeconds,
      lastHeartbeat: DateTime.now(),
      storageUsedBytes: storageUsed,
      storageTotalBytes: storageTotal,
    );
  }
}