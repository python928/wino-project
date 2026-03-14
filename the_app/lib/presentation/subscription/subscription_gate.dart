import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'subscription_plans_screen.dart';

Future<void> showSubscriptionRequiredWindow(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline,
                color: AppColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Subscription Required'),
        ],
      ),
      content: const Text(
        'You reached the free limit (5 posts).\n\n'
        'Subscribe to publish more posts, run ads, and unlock priority exposure.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Later'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SubscriptionPlansScreen()),
            );
          },
          child: const Text('View Plans'),
        ),
      ],
    ),
  );
}
