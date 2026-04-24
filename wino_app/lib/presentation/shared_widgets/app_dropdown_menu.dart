import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppDropdownAction<T> {
  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
  final bool showDividerAbove;
  final Color? iconColor;
  final Color? textColor;

  const AppDropdownAction({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
    this.showDividerAbove = false,
    this.iconColor,
    this.textColor,
  });
}

class AppDropdownMenuButton<T> extends StatelessWidget {
  final List<AppDropdownAction<T>> actions;
  final ValueChanged<T>? onSelected;
  final Offset offset;
  final Widget? child;
  final Widget? icon;
  final String? tooltip;
  final double minWidth;

  const AppDropdownMenuButton({
    super.key,
    required this.actions,
    this.onSelected,
    this.offset = const Offset(0, 40),
    this.child,
    this.icon,
    this.tooltip,
    this.minWidth = 248,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      offset: offset,
      elevation: 18,
      padding: EdgeInsets.zero,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      surfaceTintColor: Colors.white,
      splashRadius: 22,
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: minWidth + 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: AppColors.borderPrimary.withValues(alpha: 0.9)),
      ),
      itemBuilder: (context) => _buildEntries(context),
      icon: child == null
          ? icon ??
              const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textPrimary,
              )
          : null,
      child: child,
    );
  }

  List<PopupMenuEntry<T>> _buildEntries(BuildContext context) {
    final entries = <PopupMenuEntry<T>>[];
    for (final action in actions) {
      if (action.showDividerAbove) {
        entries.add(
          PopupMenuDivider(
            height: 1,
            color: AppColors.borderPrimary.withValues(alpha: 0.9),
          ),
        );
      }
      entries.add(
        PopupMenuItem<T>(
          value: action.value,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _DropdownMenuRow<T>(action: action),
        ),
      );
    }
    return entries;
  }
}

class _DropdownMenuRow<T> extends StatelessWidget {
  final AppDropdownAction<T> action;

  const _DropdownMenuRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final danger = action.destructive;
    final iconColor = action.iconColor ??
        (danger ? AppColors.errorRed : AppColors.primaryColor);
    final textColor = action.textColor ??
        (danger ? AppColors.errorRed : AppColors.textPrimary);

    return Row(
      children: [
        Icon(action.icon, size: 20, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: danger ? FontWeight.w700 : FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class AppDropdownFieldItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppDropdownFieldItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppDropdownField<T> extends StatelessWidget {
  final T value;
  final String label;
  final ValueChanged<T?>? onChanged;
  final List<AppDropdownFieldItem<T>> items;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      onChanged: onChanged,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.primaryLightShade,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primaryColor,
          size: 18,
        ),
      ),
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(24),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 1.5,
          ),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18, color: AppColors.primaryColor),
                    const SizedBox(width: 10),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
