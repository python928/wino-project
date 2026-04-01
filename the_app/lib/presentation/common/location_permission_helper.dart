import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

enum LocationEducationFlow { nearbySearch, storeGps }

class LocationPermissionHelper {
  const LocationPermissionHelper._();

  static Future<bool> ensureEducationShown(
    BuildContext context, {
    required LocationEducationFlow flow,
  }) async {
    final alreadySeen = switch (flow) {
      LocationEducationFlow.nearbySearch =>
        StorageService.hasSeenNearbyEducation(),
      LocationEducationFlow.storeGps =>
        StorageService.hasSeenStoreGpsEducation(),
    };
    if (alreadySeen) return true;

    final accepted = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => _LocationEducationSheet(flow: flow),
        ) ??
        false;

    if (!accepted) return false;

    switch (flow) {
      case LocationEducationFlow.nearbySearch:
        await StorageService.setSeenNearbyEducation();
        break;
      case LocationEducationFlow.storeGps:
        await StorageService.setSeenStoreGpsEducation();
        break;
    }

    return true;
  }

  static Future<void> handleLocationError(
    BuildContext context,
    Object error, {
    required String fallbackMessage,
  }) async {
    final message = error.toString().toLowerCase();

    if (message.contains('location services are disabled')) {
      await showLocationDisabledDialog(
        context,
        title: context.tr('Enable GPS'),
        message: context.l10n.locationDisabled,
        actionLabel: context.l10n.settingsOpenLocation,
      );
      return;
    }

    if (message.contains('permanently denied')) {
      await showSettingsDialog(
        context,
        title: context.tr('Permission Required'),
        message: context.l10n.locationPermissionDeniedForever,
        actionLabel: context.l10n.settingsOpenApp,
        openSettings: Geolocator.openAppSettings,
      );
      return;
    }

    if (message.contains('permission denied')) {
      Helpers.showSnackBar(context, context.tr('Location permission denied'));
      return;
    }

    Helpers.showSnackBar(context, fallbackMessage, isError: true);
  }

  static Future<void> showLocationDisabledDialog(
    BuildContext context, {
    String? title,
    String? message,
    String? actionLabel,
    String? closeLabel,
    Future<bool> Function() openSettings = Geolocator.openLocationSettings,
  }) {
    return showSettingsDialog(
      context,
      title: title ?? context.l10n.locationDisabledTitle,
      message: message ?? context.l10n.locationDisabledMessage,
      actionLabel: actionLabel ?? context.l10n.openSettings,
      closeLabel: closeLabel ?? context.l10n.close,
      openSettings: openSettings,
    );
  }

  static Future<void> showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    String? closeLabel,
    required Future<bool> Function() openSettings,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(closeLabel ?? context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await openSettings();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LocationEducationSheet extends StatelessWidget {
  final LocationEducationFlow flow;

  const _LocationEducationSheet({required this.flow});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (flow) {
      LocationEducationFlow.nearbySearch => l10n.locationEducationNearbyTitle,
      LocationEducationFlow.storeGps => l10n.locationEducationStoreTitle,
    };
    final description = switch (flow) {
      LocationEducationFlow.nearbySearch =>
        l10n.locationEducationNearbyDescription,
      LocationEducationFlow.storeGps => l10n.locationEducationStoreDescription,
    };

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _BulletLine(text: l10n.locationEducationRadiusHint),
              const SizedBox(height: 8),
              _BulletLine(text: l10n.locationEducationAddressHint),
              const SizedBox(height: 8),
              _BulletLine(text: l10n.locationEducationPrivacyNote),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.commonContinue),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.commonNotNow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String text;

  const _BulletLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
