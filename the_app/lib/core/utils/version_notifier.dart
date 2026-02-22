import 'package:flutter/foundation.dart';

/// A generic notifier that merely increments a version number to trigger UI updates.
/// Useful for signaling global data changes (like follows or favorites) without
/// passing complex state objects.
class VersionNotifier {
  final ValueNotifier<int> version = ValueNotifier<int>(0);

  void bump() {
    version.value = version.value + 1;
  }
}

/// Helper mixin or base class for specific static version notifiers.
abstract class StaticVersionNotifier {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  
  static void bump() {
    version.value = version.value + 1;
  }
}
