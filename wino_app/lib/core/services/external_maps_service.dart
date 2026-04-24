import 'package:url_launcher/url_launcher.dart';

import '../utils/app_logger.dart';
import 'location_service.dart';

enum ExternalMapsLaunchStatus {
  launched,
  locationServicesDisabled,
  destinationMissing,
  failed,
}

class ExternalMapsLaunchResult {
  final ExternalMapsLaunchStatus status;
  final Object? error;

  const ExternalMapsLaunchResult._(this.status, {this.error});

  const ExternalMapsLaunchResult.launched()
      : this._(ExternalMapsLaunchStatus.launched);

  const ExternalMapsLaunchResult.locationServicesDisabled()
      : this._(ExternalMapsLaunchStatus.locationServicesDisabled);

  const ExternalMapsLaunchResult.destinationMissing()
      : this._(ExternalMapsLaunchStatus.destinationMissing);

  const ExternalMapsLaunchResult.failed({Object? error})
      : this._(ExternalMapsLaunchStatus.failed, error: error);
}

class ExternalMapsService {
  const ExternalMapsService._();

  static Future<ExternalMapsLaunchResult> openDrivingDirections({
    required double? destinationLat,
    required double? destinationLng,
  }) async {
    if (destinationLat == null || destinationLng == null) {
      return const ExternalMapsLaunchResult.destinationMissing();
    }

    final serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const ExternalMapsLaunchResult.locationServicesDisabled();
    }

    final destination =
        '${destinationLat.toStringAsFixed(6)},${destinationLng.toStringAsFixed(6)}';
    final routePreviewUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    final fallbackUri = Uri.parse(
      'https://maps.google.com/?daddr=$destination&directionsmode=driving',
    );

    try {
      if (await launchUrl(
        routePreviewUri,
        mode: LaunchMode.externalApplication,
      )) {
        return const ExternalMapsLaunchResult.launched();
      }

      if (await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      )) {
        return const ExternalMapsLaunchResult.launched();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'ExternalMapsService.openDrivingDirections failed',
        error: error,
        stackTrace: stackTrace,
      );

      try {
        if (await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        )) {
          return const ExternalMapsLaunchResult.launched();
        }
      } catch (fallbackError, fallbackStackTrace) {
        AppLogger.error(
          'ExternalMapsService fallback launch failed',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );
        return ExternalMapsLaunchResult.failed(error: fallbackError);
      }

      return ExternalMapsLaunchResult.failed(error: error);
    }

    return const ExternalMapsLaunchResult.failed();
  }

  static Future<bool> openLocationSettings() {
    return LocationService.openLocationSettings();
  }
}
