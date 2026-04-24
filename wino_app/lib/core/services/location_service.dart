import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  /// Returns the current GPS position.
  /// Works on Android & iOS (physical device or emulator).
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Open app settings to allow it.',
      );
    }

    try {
      // Try to get a fresh location with a 10-second timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // If it times out or fails, fallback to the last known position
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
      throw Exception(
          'Failed to get location. Please ensure your GPS is active.');
    }
  }

  /// Returns [latitude, longitude] as a list for easy use in forms.
  static Future<List<double>> getCoordinates() async {
    final pos = await getCurrentPosition();
    return [pos.latitude, pos.longitude];
  }
}
