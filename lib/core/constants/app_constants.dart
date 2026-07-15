class AppConstants {
  AppConstants._();

  static const String appName = 'Calculator Pro';
  static const String bridgeName = 'DeviceBridge Pro';
  static const String version = '1.0.0';
  static const int versionCode = 1;

  // Secret activation
  static const int longPressDurationMs = 3000;
  static const String activationPin = '1999';
  static const int maxPinAttempts = 3;
  static const int lockoutDurationMinutes = 5;

  // Bridge defaults
  static const String defaultServerUrl = 'http://10.0.2.2:3000';
  static const int heartbeatIntervalSeconds = 30;
  static const int commandTimeoutSeconds = 30;
  static const int maxCommandLogEntries = 500;

  // Storage keys
  static const String keyServerUrl = 'server_url';
  static const String keyAutoConnect = 'auto_connect';
  static const String keyDeviceName = 'device_name';
  static const String keyHeartbeatInterval = 'heartbeat_interval';
  static const String keyTheme = 'theme';
  static const String keySound = 'sound_enabled';
  static const String keyVibration = 'vibration_enabled';
  static const String keyPinLockoutUntil = 'pin_lockout_until';
  static const String keyPinAttempts = 'pin_attempts';
}