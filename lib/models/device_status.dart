class DeviceStatus {
  final int batteryLevel;
  final bool isCharging;
  final String networkType;
  final String? ipAddress;
  final int uptimeSeconds;
  final DateTime lastHeartbeat;
  final int? storageUsedBytes;
  final int? storageTotalBytes;

  const DeviceStatus({
    this.batteryLevel = 100,
    this.isCharging = false,
    this.networkType = 'unknown',
    this.ipAddress,
    this.uptimeSeconds = 0,
    DateTime? lastHeartbeat,
    this.storageUsedBytes,
    this.storageTotalBytes,
  }) : lastHeartbeat = lastHeartbeat ?? DateTime.now();

  factory DeviceStatus.initial() => const DeviceStatus();

  DeviceStatus copyWith({
    int? batteryLevel,
    bool? isCharging,
    String? networkType,
    String? ipAddress,
    int? uptimeSeconds,
    DateTime? lastHeartbeat,
    int? storageUsedBytes,
    int? storageTotalBytes,
  }) {
    return DeviceStatus(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      networkType: networkType ?? this.networkType,
      ipAddress: ipAddress ?? this.ipAddress,
      uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      storageTotalBytes: storageTotalBytes ?? this.storageTotalBytes,
    );
  }
}