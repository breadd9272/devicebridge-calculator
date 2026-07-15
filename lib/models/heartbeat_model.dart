class HeartbeatModel {
  final String deviceId;
  final int timestamp;
  final int batteryLevel;
  final bool isCharging;
  final String networkType;
  final int? signalStrength;
  final double? memoryUsagePercent;
  final int? storageUsedBytes;
  final int? storageTotalBytes;
  final List<String> activeCapabilities;
  final String deviceName;

  const HeartbeatModel({
    required this.deviceId,
    required this.timestamp,
    required this.batteryLevel,
    required this.isCharging,
    required this.networkType,
    this.signalStrength,
    this.memoryUsagePercent,
    this.storageUsedBytes,
    this.storageTotalBytes,
    this.activeCapabilities = const [],
    required this.deviceName,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'timestamp': timestamp,
    'batteryLevel': batteryLevel,
    'isCharging': isCharging,
    'networkType': networkType,
    'signalStrength': signalStrength,
    'memoryUsagePercent': memoryUsagePercent,
    'storageUsedBytes': storageUsedBytes,
    'storageTotalBytes': storageTotalBytes,
    'activeCapabilities': activeCapabilities,
    'deviceName': deviceName,
  };
}