import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/logger.dart';
import '../models/device_info_model.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final _dio = Dio();
  String? _cachedDeviceId;
  DeviceInfoModel? _cachedInfo;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    const uuid = Uuid();
    _cachedDeviceId = uuid.v4();
    return _cachedDeviceId!;
  }

  Future<DeviceInfoModel> getDeviceInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    final deviceId = await getDeviceId();
    final packageInfo = await PackageInfo.fromPlatform();
    String brand = 'Unknown';
    String model = 'Unknown';
    String osVersion = 'Unknown';
    String sdkVersion = 'Unknown';
    String? serialNumber;

    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      brand = android.brand;
      model = android.model;
      osVersion = 'Android ${android.version.release}';
      sdkVersion = android.version.sdkInt.toString();
    }

    _cachedInfo = DeviceInfoModel(
      deviceId: deviceId,
      brand: brand,
      model: model,
      osVersion: osVersion,
      sdkVersion: sdkVersion,
      appVersion: packageInfo.version,
      serialNumber: serialNumber,
    );

    return _cachedInfo!;
  }

  Future<String?> getPublicIp() async {
    try {
      final response = await _dio.get('https://api.ipify.org?format=json',
          options: Options(receiveTimeout: const Duration(seconds: 5)));
      return response.data['ip'] as String?;
    } catch (e) {
      AppLogger.w('DeviceInfo', 'Failed to get public IP: $e');
      return null;
    }
  }

  Future<int> getStorageUsedBytes() async {
    try {
      final dirs = [Directory.systemTemp.path];
      int total = 0;
      for (final dir in dirs) {
        final entity = await FileSystemEntity.stat(dir);
        total += entity.size;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getStorageTotalBytes() async {
    try {
      if (Platform.isAndroid) {
        final stat = await Process.run('df', ['/data']);
        final lines = (stat.stdout as String).split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length > 1) {
            return int.parse(parts[1]) * 1024;
          }
        }
      }
    } catch (_) {}
    return 0;
  }
}