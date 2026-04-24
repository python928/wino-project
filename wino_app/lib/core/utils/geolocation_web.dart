// ignore_for_file: avoid_web_libraries_in_flutter
// Web implementation using dart:html.
import 'dart:async';
import 'dart:html' as html;

Future<Map<String, double>?> getWebCurrentPosition() async {
  final geolocation = html.window.navigator.geolocation;
  final completer = Completer<html.Geoposition>();
  geolocation
      .getCurrentPosition(
        enableHighAccuracy: true,
        timeout: const Duration(seconds: 15),
      )
      .then(completer.complete)
      .catchError(completer.completeError);
  final position = await completer.future;
  return {
    'latitude': position.coords!.latitude!.toDouble(),
    'longitude': position.coords!.longitude!.toDouble(),
  };
}
