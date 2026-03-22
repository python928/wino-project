import 'package:flutter/foundation.dart';

class FollowChangeNotifier {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  static final Map<int, bool> _storeFollowState = {};

  static void bump() {
    version.value = version.value + 1;
  }

  static bool? getFollowState(int storeId) {
    return _storeFollowState[storeId];
  }

  static void setFollowState(int storeId, bool isFollowing) {
    _storeFollowState[storeId] = isFollowing;
  }
}
