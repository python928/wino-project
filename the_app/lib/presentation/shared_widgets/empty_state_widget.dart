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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryTightHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight <= 130;
        final isTightHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight <= 150;

        final padding = isVeryTightHeight
            ? 4.0
            : (isTightHeight
                ? 8.0
                : (compact ? AppTheme.spacing16 : AppTheme.spacing32));
        final iconSize = isVeryTightHeight
            ? 18.0
            : (isTightHeight ? 24.0 : (compact ? 40.0 : 60.0));
        final titleStyle = isVeryTightHeight
            ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)
            : (isTightHeight
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
                : (compact ? AppTextStyles.h3 : AppTextStyles.h2));
        final titleSpacing = isVeryTightHeight
            ? 4.0
            : (isTightHeight
                ? 8.0
                : (compact ? AppTheme.spacing16 : AppTheme.spacing24));
        final messageSpacing = isVeryTightHeight
            ? 2.0
            : (isTightHeight
                ? 4.0
                : (compact ? AppTheme.spacing8 : AppTheme.spacing12));
        final actionSpacing = isVeryTightHeight
            ? 4.0
            : (isTightHeight
                ? 8.0
                : (compact ? AppTheme.spacing16 : AppTheme.spacing24));
        final effectiveIconContainerSize = isVeryTightHeight
            ? 36.0
            : (isTightHeight ? 48.0 : (compact ? 80.0 : 120.0));
        final effectiveActionWidth =
            isVeryTightHeight ? 140.0 : (isTightHeight ? 160.0 : 200.0);
        final hideIconForVeryTight = compact && isVeryTightHeight;

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hideIconForVeryTight)
                    Container(
                      width: effectiveIconContainerSize,
                      height: effectiveIconContainerSize,
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
                  SizedBox(height: hideIconForVeryTight ? 0 : titleSpacing),
                  Text(
                    title,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                    maxLines: isTightHeight ? 1 : null,
                    overflow: isTightHeight ? TextOverflow.ellipsis : null,
                  ),
                  SizedBox(height: messageSpacing),
                  Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize:
                          isVeryTightHeight ? 11 : (isTightHeight ? 12 : null),
                    ),
                    textAlign: TextAlign.center,
                    maxLines:
                        isVeryTightHeight ? 3 : (isTightHeight ? 2 : null),
                    overflow: isTightHeight ? TextOverflow.ellipsis : null,
                  ),
                  if (actionText != null && onActionPressed != null) ...[
                    SizedBox(height: actionSpacing),
                    AppPrimaryButton(
                      text: actionText!,
                      onPressed: onActionPressed,
                      width: effectiveActionWidth,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
