import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../routing/routes.dart';

class DeepLinkService {
  DeepLinkService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static Uri? _pendingUri;

  static Future<void> init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handle(initial);
    }

    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handle(uri);
    });
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  static void handleFromString(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      _handle(uri);
    }
  }

  static void flushPendingLink() {
    final pending = _pendingUri;
    if (pending == null) return;
    _pendingUri = null;
    _handle(pending);
  }

  static void _handle(Uri uri) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingUri = uri;
      return;
    }

    final segments = uri.pathSegments;

    // Handle path-based links first (http(s)://host/s/1/, /s/1/, /p/1/).
    if (_handlePathSegments(nav, segments)) {
      return;
    }

    // Custom scheme fallback: wino://store/12 (legacy: toprice://store/12)
    if (uri.scheme == 'wino' || uri.scheme == 'toprice') {
      final host = uri.host.toLowerCase();
      final firstPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (host == 'store' || host == 's' || firstPath == 'store' || firstPath == 's') {
        final raw = uri.pathSegments.length >= 2
            ? uri.pathSegments[1]
            : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
        final id = int.tryParse(raw);
        if (id != null) {
          nav.pushNamed(Routes.store, arguments: id);
        }
        return;
      }
      if (host == 'product' || host == 'p' || firstPath == 'product' || firstPath == 'p') {
        final raw = uri.pathSegments.length >= 2
            ? uri.pathSegments[1]
            : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
        final id = int.tryParse(raw);
        if (id != null) {
          nav.pushNamed(Routes.productDetails, arguments: id);
        }
      }
    }
  }

  static bool _handlePathSegments(NavigatorState nav, List<String> segments) {
    if (segments.length < 2) return false;

    final type = segments[0].toLowerCase();
    final id = int.tryParse(segments[1]);
    if (id == null) return false;

    if (type == 's' || type == 'store') {
      nav.pushNamed(Routes.store, arguments: id);
      return true;
    }
    if (type == 'p' || type == 'product') {
      nav.pushNamed(Routes.productDetails, arguments: id);
      return true;
    }
    return false;
  }
}
