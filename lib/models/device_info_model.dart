class DeviceInfoModel {
  final String deviceId;
  final String brand;
  final String model;
  final String osVersion;
  final String sdkVersion;
  final String appVersion;
  final String? serialNumber;
  final String? screenResolution;

  const DeviceInfoModel({
    required this.deviceId,
    required this.brand,
    required this.model,
    required this.osVersion,
    required this.sdkVersion,
    required this.appVersion,
    this.serialNumber,
    this.screenResolution,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'brand': brand,
    'model': model,
    'osVersion': osVersion,
    'sdkVersion': sdkVersion,
    'appVersion': appVersion,
    'serialNumber': serialNumber,
    'screenResolution': screenResolution,
  };
}