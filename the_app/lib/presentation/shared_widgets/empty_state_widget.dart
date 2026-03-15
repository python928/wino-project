import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool compact;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact ? AppTheme.spacing16 : AppTheme.spacing32;
    final iconContainerSize = compact ? 80.0 : 120.0;
    final iconSize = compact ? 40.0 : 60.0;
    final titleStyle = compact ? AppTextStyles.h3 : AppTextStyles.h2;
    final titleSpacing = compact ? AppTheme.spacing16 : AppTheme.spacing24;
    final messageSpacing = compact ? AppTheme.spacing8 : AppTheme.spacing12;
    final actionSpacing = compact ? AppTheme.spacing16 : AppTheme.spacing24;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.primaryPurple.withValues(alpha: 0.5),
              ),
            ),

            SizedBox(height: titleSpacing),
            
            // Title
            Text(
              title,
              style: titleStyle,
              textAlign: TextAlign.center,
            ),

            SizedBox(height: messageSpacing),
            
            // Message
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action Button
            if (actionText != null && onActionPressed != null) ...[
              SizedBox(height: actionSpacing),
              AppPrimaryButton(
                text: actionText!,
                onPressed: onActionPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
