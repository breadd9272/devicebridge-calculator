import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../core/utils/logger.dart';

class TokenService {
  static final TokenService _instance = TokenService._();
  factory TokenService() => _instance;
  TokenService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'device_token';
  static const _keyDeviceId = 'device_id';

  Future<void> saveToken(String token, String deviceId) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyDeviceId, value: deviceId);
    AppLogger.i('TokenService', 'Token saved for device: $deviceId');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: _keyDeviceId);
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final isExpired = JwtDecoder.isExpired(token);
      return !isExpired;
    } catch (e) {
      AppLogger.e('TokenService', 'Token validation error', e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> decodeToken() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      AppLogger.e('TokenService', 'Token decode error', e);
      return null;
    }
  }

  Future<DateTime?> getTokenExpiry() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyDeviceId);
    AppLogger.i('TokenService', 'Token cleared');
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}