import 'package:flutter/material.dart';

import 'app_toggle_button.dart';

class AppCompactActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppCompactActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: AppToggleButton(
          label: label,
          icon: icon,
          isSelected: false,
          onTap: onTap ?? () {},
          compact: true,
        ),
      ),
    );
  }
}
