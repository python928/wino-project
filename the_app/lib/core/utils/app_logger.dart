import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    debugPrint('[+] info: $message');
  }

  static void success(String message) {
    debugPrint('[+] success: $message');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[-] error: $message');
    if (error != null) debugPrint('[-] error.detail: $error');
    if (stackTrace != null) debugPrint('[-] error.stack: $stackTrace');
  }
}
