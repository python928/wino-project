import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class PromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppColors.primaryShadow,
        ),
        child: Stack(
          children: [
            // Background Icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon ?? Icons.percent,
                size: 150,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Action Button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.mediumRadius,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  
                  const SizedBox(width: AppTheme.spacing20),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.promoTitle,
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          subtitle,
                          style: AppTextStyles.promoSubtitle,
                        ),
                      ],
                    ),
                  ),
                  
                  // Icon Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon ?? Icons.percent,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
