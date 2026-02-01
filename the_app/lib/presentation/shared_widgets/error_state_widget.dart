import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    this.message = 'An error occurred',
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: AppColors.errorRed.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Message
            Text(
              message,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),

            if (details != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                details!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Retry Button
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              AppSecondaryButton(
                text: 'Retry',
                onPressed: onRetry,
                icon: Icons.refresh,
                width: 150,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network error state
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.wifi_off_rounded,
      message: 'No internet connection',
      details: 'Please check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

/// Server error state
class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const ServerErrorWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      icon: Icons.cloud_off_rounded,
      message: 'Server error',
      details: 'Sorry, something went wrong. Please try again later.',
      onRetry: onRetry,
    );
  }
}
