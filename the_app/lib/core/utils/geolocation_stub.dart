// Stub implementation for non-web platforms.
// On mobile/desktop, use the geolocator package or return null.
Future<Map<String, double>?> getWebCurrentPosition() async {
  return null;
}
