import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Helpers {
  /// Haversine distance between two lat/lng points in kilometres.
  static double? haversineDistance(
    double? lat1, double? lng1,
    double? lat2, double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
    const R = 6371.0; // Earth radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
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
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
      debugPrint('Helpers.launchURL error: $e');
      throw Exception('Unable to open link');
    }
  }

  // Format date in Arabic style
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months months ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
