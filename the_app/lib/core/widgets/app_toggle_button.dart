import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import '../theme/app_colors.dart';

/// Single toggle button with icon support
class AppToggleButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;
  final bool showBorder;

  const AppToggleButton({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedBg = showBorder ? Colors.white : AppColors.blackColor5;
    const selectedBg = AppColors.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(compact ? 20 : 24),
          border: showBorder
              ? Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : const Color(0xFFE0E0E0),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                size: compact ? 18 : 20,
              ),
              SizedBox(width: compact ? 6 : 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle button group - horizontal scrollable or wrap layout
class AppToggleButtonGroup extends StatelessWidget {
  final List<ToggleOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool scrollable;
  final bool compact;
  final bool showBorder;

  const AppToggleButtonGroup({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.scrollable = true,
    this.compact = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildButtons(context),
        ),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _buildButtons(context),
      );
    }
  }

  List<Widget> _buildButtons(BuildContext context) {
    return List.generate(options.length, (index) {
      final option = options[index];
      return Padding(
        padding: EdgeInsets.only(
          right: index < options.length - 1 ? 12 : 0,
        ),
        child: AppToggleButton(
          label: context.tr(option.label),
          icon: option.icon,
          isSelected: selectedIndex == index,
          onTap: () => onChanged(index),
          compact: compact,
          showBorder: showBorder,
        ),
      );
    });
  }
}

/// Toggle option model
class ToggleOption {
  final String label;
  final IconData? icon;
  final String value;

  const ToggleOption({
    required this.label,
    this.icon,
    required this.value,
  });
}
