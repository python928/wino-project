import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;
  final EdgeInsetsGeometry padding;
  final bool showContainer;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const AppSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    this.showContainer = true,
    this.backgroundColor,
    this.borderRadius,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: titleStyle ??
                    const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: subtitleStyle ??
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );

    if (!showContainer) {
      return Padding(
        padding: padding,
        child: content,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border: Border.all(
          color: value
              ? AppColors.borderPurple.withValues(alpha: 0.55)
              : AppColors.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: content,
      ),
    );
  }
}
