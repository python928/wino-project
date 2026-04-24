import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final bool isMerchant;

  const CustomHeader({
    Key? key,
    required this.title,
    required this.isMerchant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMerchant
              ? [AppColors.merchantStart, AppColors.merchantEnd]
              : [AppColors.userStart, AppColors.userEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isMerchant ? Icons.store : Icons.person,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
