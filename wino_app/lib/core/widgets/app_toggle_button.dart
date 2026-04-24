import 'package:flutter/material.dart';
import 'package:wino/core/extensions/l10n_extension.dart';
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
    const unselectedBg = Color(0xFFF1EFF8);
    const selectedBg = AppColors.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? selectedBg : unselectedBg,
        borderRadius: BorderRadius.circular(compact ? 22 : 24),
        border: showBorder
            ? Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : Colors.white.withValues(alpha: 0.95),
                width: 1.1,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 22 : 24),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                    size: compact ? 18 : 19,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 160 : 220,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: compact ? 13.5 : 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
