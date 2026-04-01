import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Modern Bottom Navigation Bar with floating style
class ModernBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool showLabels;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.showLabels = true,
  });

  @override
  State<ModernBottomNavBar> createState() => _ModernBottomNavBarState();
}

class _ModernBottomNavBarState extends State<ModernBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          widget.items.length,
          (index) => _NavBarItem(
            item: widget.items[index],
            isSelected: index == widget.currentIndex,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap(index);
            },
            selectedColor: widget.selectedColor ?? AppColors.primaryColor,
            unselectedColor:
                widget.unselectedColor ?? AppColors.textSecondary,
            showLabel: widget.showLabels,
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _indicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.defaultCurve),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Selection indicator
                      if (widget.isSelected)
                        Positioned(
                          child: Transform.scale(
                            scale: _indicatorAnimation.value,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.selectedColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      // Icon
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              widget.isSelected
                                  ? widget.item.selectedIcon
                                  : widget.item.icon,
                              color: widget.isSelected
                                  ? widget.selectedColor
                                  : widget.unselectedColor,
                              size: 26,
                            ),
                            // Badge
                            if (widget.item.badge != null &&
                                widget.item.badge! > 0)
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.errorRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    widget.item.badge! > 99
                                        ? '99+'
                                        : widget.item.badge.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: AppTheme.shortAnimation,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: widget.isSelected
                            ? widget.selectedColor
                            : widget.unselectedColor,
                      ),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? badge;

  const BottomNavItem({
    required this.label,
    required this.icon,
    IconData? selectedIcon,
    this.badge,
  }) : selectedIcon = selectedIcon ?? icon;
}

/// Modern App Bar with gradient and glass effect
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Gradient? gradient;
  final double elevation;
  final bool showBorder;

  const ModernAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.showBackButton = false,
    this.onBackPressed,
    this.gradient,
    this.elevation = 0,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (backgroundColor ?? Colors.white)
            : null,
        border: showBorder
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.borderPrimary,
                  width: 1,
                ),
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : [],
      ),
      child: AppBar(
        title: titleWidget ??
            (title != null
                ? Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  )
                : null),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading ??
            (showBackButton
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    onPressed: onBackPressed ??
                        () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                  )
                : null),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Modern Tab Bar with smooth indicator
class ModernTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isScrollable;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;

  const ModernTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.isScrollable = false,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTabRow(),
            )
          : _buildTabRow(),
    );
  }

  Widget _buildTabRow() {
    return Row(
      mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
      children: List.generate(
        tabs.length,
        (index) => Expanded(
          flex: isScrollable ? 0 : 1,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTabChanged(index);
            },
            child: AnimatedContainer(
              duration: AppTheme.shortAnimation,
              curve: AppTheme.emphasizedCurve,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(
                horizontal: isScrollable ? 24 : 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: selectedIndex == index
                    ? (selectedColor ?? AppColors.primaryColor)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selectedIndex == index
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
                tabs[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selectedIndex == index
                      ? Colors.white
                      : (unselectedColor ?? AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern Search Bar for app bars
class ModernSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autoFocus;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autoFocus = false,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.primaryColor.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: AppColors.textHint.withOpacity(0.6),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
