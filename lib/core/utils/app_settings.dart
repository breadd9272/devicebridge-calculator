import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get serverUrl =>
      _prefs.getString('server_url') ?? 'http://10.0.2.2:3000';

  static set serverUrl(String value) =>
      _prefs.setString('server_url', value);

  static bool get autoConnect =>
      _prefs.getBool('auto_connect') ?? false;

  static set autoConnect(bool value) =>
      _prefs.setBool('auto_connect', value);

  static String get deviceName =>
      _prefs.getString('device_name') ?? 'My Device';

  static set deviceName(String value) =>
      _prefs.setString('device_name', value);

  static int get heartbeatInterval =>
      _prefs.getInt('heartbeat_interval') ?? 30;

  static set heartbeatInterval(int value) =>
      _prefs.setInt('heartbeat_interval', value);

  static bool get isDarkTheme =>
      _prefs.getBool('theme') ?? true;

  static set isDarkTheme(bool value) =>
      _prefs.setBool('theme', value);

  static bool get soundEnabled =>
      _prefs.getBool('sound_enabled') ?? true;

  static set soundEnabled(bool value) =>
      _prefs.setBool('sound_enabled', value);

  static bool get vibrationEnabled =>
      _prefs.getBool('vibration_enabled') ?? true;

  static set vibrationEnabled(bool value) =>
      _prefs.setBool('vibration_enabled', value);

  static DateTime? get pinLockoutUntil {
    final val = _prefs.getInt('pin_lockout_until');
    return val != null ? DateTime.fromMillisecondsSinceEpoch(val) : null;
  }

  static set pinLockoutUntil(DateTime? value) {
    if (value != null) {
      _prefs.setInt('pin_lockout_until', value.millisecondsSinceEpoch);
    } else {
      _prefs.remove('pin_lockout_until');
    }
  }

  static int get pinAttempts => _prefs.getInt('pin_attempts') ?? 0;

  static set pinAttempts(int value) =>
      _prefs.setInt('pin_attempts', value);
}