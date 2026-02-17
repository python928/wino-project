import 'package:flutter/foundation.dart';

class FollowChangeNotifier {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void bump() {
    version.value = version.value + 1;
  }
}
