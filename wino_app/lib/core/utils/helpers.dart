import 'dart:math' as math;

import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

class Helpers {
  /// Haversine distance between two lat/lng points in kilometres.
  static double? haversineDistance(
    double? lat1,
    double? lng1,
    double? lat2,
    double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);

  // Format large numbers (e.g., 1234 -> 1.2K)
  static String formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Alias for formatLargeNumber
  static String formatNumber(int number) {
    return formatLargeNumber(number);
  }

  // Format distance
  static String formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).toInt()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  // Format rating
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  // Format price with currency
  static String formatPrice(double price, {String currency = 'DZD'}) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} $currency';
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    final translatedMessage = _translateMessage(context, message);
    final effectiveIsError = isError || _looksLikeError(translatedMessage);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          translatedMessage,
          textAlign: TextAlign.right,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: effectiveIsError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: effectiveIsError ? 6 : 2),
      ),
    );
  }

  static bool _looksLikeError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('invalid') ||
        lower.contains('required') ||
        lower.contains('unable') ||
        lower.contains('expired') ||
        lower.contains('denied') ||
        lower.contains('not available') ||
        lower.contains('fشل') ||
        lower.contains('خطأ');
  }

  static String _translateMessage(BuildContext context, String message) {
    final normalized = formatError(message);
    final direct = context.tr(normalized);
    if (direct != normalized) return direct;

    final splitIndex = normalized.indexOf(':');
    if (splitIndex > 0) {
      final prefix = normalized.substring(0, splitIndex).trim();
      final suffix = normalized.substring(splitIndex + 1).trim();
      final translatedPrefix = context.tr(prefix);
      if (translatedPrefix != prefix) {
        return '$translatedPrefix: $suffix';
      }
    }
    return normalized;
  }

  static String formatError(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }
    return text;
  }

  static void showErrorSnackBar(BuildContext context, Object error) {
    final msg = formatError(error);
    showSnackBar(context, msg, isError: true);
  }

  // Format time remaining (for hot deals)
  static Map<String, String> formatTimeRemaining(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return {
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  // Launch external URLs safely
  static Future<void> launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      AppLogger.error('Helpers.launchURL error', error: e);
      throw Exception('Unable to open link');
    }
  }

  // Format relative date/time with optional localization context.
  static String formatDate(DateTime date, {BuildContext? context}) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return context?.tr('now') ?? 'now';
        }
        final unit = difference.inMinutes == 1
            ? (context?.tr('minute ago') ?? 'minute ago')
            : (context?.tr('minutes ago') ?? 'minutes ago');
        return '${difference.inMinutes} $unit';
      }
      final unit = difference.inHours == 1
          ? (context?.tr('hour ago') ?? 'hour ago')
          : (context?.tr('hours ago') ?? 'hours ago');
      return '${difference.inHours} $unit';
    } else if (difference.inDays == 1) {
      return context?.tr('Yesterday') ?? 'Yesterday';
    } else if (difference.inDays < 7) {
      final unit = difference.inDays == 1
          ? (context?.tr('day ago') ?? 'day ago')
          : (context?.tr('days ago') ?? 'days ago');
      return '${difference.inDays} $unit';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      final unit = weeks == 1
          ? (context?.tr('week ago') ?? 'week ago')
          : (context?.tr('weeks ago') ?? 'weeks ago');
      return '$weeks $unit';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      final unit = months == 1
          ? (context?.tr('month ago') ?? 'month ago')
          : (context?.tr('months ago') ?? 'months ago');
      return '$months $unit';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
