import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Modern Chip with animations and haptic feedback
class ModernChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool enableHaptic;
  final BorderRadius? borderRadius;

  const ModernChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    this.enableHaptic = true,
    this.borderRadius,
  });

  @override
  State<ModernChip> createState() => _ModernChipState();
}

class _ModernChipState extends State<ModernChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ModernChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      if (widget.enableHaptic) {
        HapticFeedback.lightImpact();
      }
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.selectedColor ?? AppColors.primaryColor;
    final unselectedColor =
        widget.unselectedColor ?? AppColors.surfaceSecondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) => setState(() {}),
          onTapUp: (_) => setState(() {}),
          onTapCancel: () => setState(() {}),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: AppTheme.shortAnimation,
              curve: AppTheme.defaultCurve,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? LinearGradient(
                        colors: [
                          selectedColor,
                          selectedColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: widget.isSelected ? null : unselectedColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isSelected
                      ? selectedColor
                      : AppColors.borderPrimary,
                  width: widget.isSelected ? 0 : 1.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withOpacity(
                            0.3 * _glowAnimation.value,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: widget.isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modern Filter Chip with count badge
class ModernFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;
  final bool showCheckmark;

  const ModernFilterChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
    this.showCheckmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        curve: AppTheme.defaultCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.borderPrimary,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            if (isSelected && showCheckmark) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Modern Chip Group with staggered animation
class ModernChipGroup extends StatelessWidget {
  final List<ChipData> chips;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;
  final bool multiSelect;
  final List<int>? selectedIndices;
  final ValueChanged<List<int>>? onMultiSelect;
  final bool scrollable;
  final EdgeInsets? padding;

  const ModernChipGroup({
    super.key,
    required this.chips,
    this.selectedIndex,
    this.onSelected,
    this.multiSelect = false,
    this.selectedIndices,
    this.onMultiSelect,
    this.scrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final chipWidgets = List.generate(chips.length, (index) {
      final chip = chips[index];
      final isSelected = multiSelect
          ? (selectedIndices?.contains(index) ?? false)
          : selectedIndex == index;

      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 200 + (index * 50)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: ModernChip(
          label: chip.label,
          icon: chip.icon,
          isSelected: isSelected,
          onTap: () {
            if (multiSelect) {
              final newSelection = List<int>.from(selectedIndices ?? []);
              if (newSelection.contains(index)) {
                newSelection.remove(index);
              } else {
                newSelection.add(index);
              }
              onMultiSelect?.call(newSelection);
            } else {
              onSelected?.call(index);
            }
          },
        ),
      );
    });

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: chipWidgets
              .map((chip) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: chip,
                  ))
              .toList(),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chipWidgets,
    );
  }
}

/// Modern Segmented Control
class ModernSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? selectedColor;
  final Color? backgroundColor;

  const ModernSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(index);
              },
              child: AnimatedContainer(
                duration: AppTheme.shortAnimation,
                curve: AppTheme.emphasizedCurve,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (selectedColor ?? AppColors.primaryColor)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (selectedColor ?? AppColors.primaryColor)
                                .withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  segments[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Data model for chips
class ChipData {
  final String label;
  final IconData? icon;
  final dynamic value;

  const ChipData({
    required this.label,
    this.icon,
    this.value,
  });
}

/// Modern Choice Chip with checkmark
class ModernChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? selectedColor;

  const ModernChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedColor ?? AppColors.primaryColor)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? AppColors.primaryColor)
                : AppColors.borderPrimary,
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (selectedColor ?? AppColors.primaryColor)
                    .withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
