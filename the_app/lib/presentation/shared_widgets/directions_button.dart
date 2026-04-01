import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/services/external_maps_service.dart';
import '../../core/utils/helpers.dart';
import '../common/location_permission_helper.dart';
import 'store_action_tile.dart';

class DirectionsButton extends StatefulWidget {
  final double? destinationLat;
  final double? destinationLng;
  final String? label;
  final IconData icon;

  const DirectionsButton({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    this.label,
    this.icon = Icons.map_rounded,
  });

  @override
  State<DirectionsButton> createState() => _DirectionsButtonState();
}

class _DirectionsButtonState extends State<DirectionsButton> {
  bool _isLaunching = false;

  bool get _hasDestination =>
      widget.destinationLat != null && widget.destinationLng != null;

  Future<void> _handlePressed() async {
    if (_isLaunching) return;

    if (!_hasDestination) {
      Helpers.showSnackBar(
        context,
        context.l10n.locationUnavailable,
        isError: true,
      );
      return;
    }

    setState(() => _isLaunching = true);

    final result = await ExternalMapsService.openDrivingDirections(
      destinationLat: widget.destinationLat,
      destinationLng: widget.destinationLng,
    );

    if (!mounted) return;
    setState(() => _isLaunching = false);

    switch (result.status) {
      case ExternalMapsLaunchStatus.launched:
        return;
      case ExternalMapsLaunchStatus.locationServicesDisabled:
        await LocationPermissionHelper.showLocationDisabledDialog(
          context,
          openSettings: ExternalMapsService.openLocationSettings,
        );
        return;
      case ExternalMapsLaunchStatus.destinationMissing:
        Helpers.showSnackBar(
          context,
          context.l10n.locationUnavailable,
          isError: true,
        );
        return;
      case ExternalMapsLaunchStatus.failed:
        Helpers.showSnackBar(
          context,
          context.l10n.unableToOpenGoogleMaps,
          isError: true,
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = _hasDestination;
    final label = widget.label ?? context.l10n.mapLabel;

    return StoreActionTile(
      onTap: _isLaunching ? null : _handlePressed,
      icon: widget.icon,
      label: label,
      backgroundColor:
          isAvailable ? const Color(0xFFFFF4DE) : const Color(0xFFF1F1F1),
      foregroundColor:
          isAvailable ? const Color(0xFF9A6114) : Colors.grey.shade600,
      borderColor: isAvailable ? const Color(0xFFE6C48E) : Colors.grey.shade300,
      isLoading: _isLaunching,
      verticalPadding: 10,
    );
  }
}
