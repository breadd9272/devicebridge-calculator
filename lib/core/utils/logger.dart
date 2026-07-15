class AppLogger {
  static const bool _enabled = true;

  static void d(String tag, String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('[$tag] [DEBUG] $message');
    }
  }

  static void i(String tag, String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('[$tag] [INFO] $message');
    }
  }

  static void w(String tag, String message) {
    if (_enabled) {
      // ignore: avoid_print
      print('[$tag] [WARN] $message');
    }
  }

  static void e(String tag, String message, [Object? error]) {
    if (_enabled) {
      // ignore: avoid_print
      print('[$tag] [ERROR] $message ${error ?? ''}');
    }
  }
}