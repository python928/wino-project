import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';

class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool compact;
  final bool animate;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.compact = false,
    this.animate = true,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.defaultCurve),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                : (widget.compact ? AppTheme.spacing16 : AppTheme.spacing32));
        final iconSize = isVeryTightHeight
            ? 18.0
            : (isTightHeight ? 24.0 : (widget.compact ? 40.0 : 60.0));
        final titleStyle = isVeryTightHeight
            ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)
            : (isTightHeight
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)
                : (widget.compact ? AppTextStyles.h3 : AppTextStyles.h2));
        final titleSpacing = isVeryTightHeight
            ? 4.0
            : (isTightHeight
                ? 8.0
                : (widget.compact ? AppTheme.spacing16 : AppTheme.spacing24));
        final messageSpacing = isVeryTightHeight
            ? 2.0
            : (isTightHeight
                ? 4.0
                : (widget.compact ? AppTheme.spacing8 : AppTheme.spacing12));
        final actionSpacing = isVeryTightHeight
            ? 4.0
            : (isTightHeight
                ? 8.0
                : (widget.compact ? AppTheme.spacing16 : AppTheme.spacing24));
        final effectiveIconContainerSize = isVeryTightHeight
            ? 36.0
            : (isTightHeight ? 48.0 : (widget.compact ? 80.0 : 120.0));
        final effectiveActionWidth =
            isVeryTightHeight ? 140.0 : (isTightHeight ? 160.0 : 200.0);
        final hideIconForVeryTight = widget.compact && isVeryTightHeight;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!hideIconForVeryTight)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: effectiveIconContainerSize,
                            height: effectiveIconContainerSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.iconBackgroundColor ??
                                      AppColors.primaryColor.withOpacity(0.15),
                                  widget.iconBackgroundColor ??
                                      AppColors.primaryColor.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.iconBackgroundColor ??
                                          AppColors.primaryColor)
                                      .withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: iconSize,
                              color: widget.iconColor ??
                                  AppColors.primaryColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                      SizedBox(height: hideIconForVeryTight ? 0 : titleSpacing),
                      Text(
                        widget.title,
                        style: titleStyle,
                        textAlign: TextAlign.center,
                        maxLines: isTightHeight ? 1 : null,
                        overflow: isTightHeight ? TextOverflow.ellipsis : null,
                      ),
                      SizedBox(height: messageSpacing),
                      Text(
                        widget.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize:
                              isVeryTightHeight ? 11 : (isTightHeight ? 12 : null),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines:
                            isVeryTightHeight ? 3 : (isTightHeight ? 2 : null),
                        overflow: isTightHeight ? TextOverflow.ellipsis : null,
                      ),
                      if (widget.actionText != null && widget.onActionPressed != null) ...[
                        SizedBox(height: actionSpacing),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 400),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: AppPrimaryButton(
                            text: widget.actionText!,
                            onPressed: widget.onActionPressed,
                            width: effectiveActionWidth,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
