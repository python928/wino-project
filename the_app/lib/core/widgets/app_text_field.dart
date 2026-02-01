import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_input_decorations.dart';
import '../theme/app_text_styles.dart';

/// Style variant for AppTextField
enum AppTextFieldStyle {
  /// Standard form (filled, neutral background, outlined)
  form,
  /// Profile/edit screen style (white fill, for use inside shadow container)
  profile,
}

/// Reusable styled TextField for forms (login, register, profile, etc.)
///
/// Supports: label, hint, icon, password with visibility toggle, validation.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final TextDirection? textDirection;
  final int maxLines;
  final AppTextFieldStyle style;
  final String? suffixText;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.focusNode,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.textDirection,
    this.maxLines = 1,
    this.style = AppTextFieldStyle.form,
    this.suffixText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      textInputAction: widget.textInputAction ?? TextInputAction.next,
      obscureText: widget.obscureText && !_isPasswordVisible,
      textDirection: widget.textDirection ?? TextDirection.ltr,
      textAlign: widget.textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
      maxLines: widget.maxLines,
      style: AppTextStyles.bodyLarge.copyWith(fontSize: 18, color: AppColors.textPrimary),
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: widget.style == AppTextFieldStyle.profile
          ? AppInputDecorations.profileForm(hintText: widget.hint, prefixIcon: widget.icon)
          : AppInputDecorations.form(
              hintText: widget.hint,
              prefixIcon: widget.icon,
              suffixText: widget.suffixText,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 26,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    )
                  : null,
            ),
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
    return content;
  }
}

/// Search field variant - compact, with search icon and optional clear button.
///
/// Use for: Search bars, filter pickers, category search, profile search.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool showClearButton;
  final bool showFilterButton;
  final bool compact;

  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onClear,
    this.focusNode,
    this.showClearButton = true,
    this.showFilterButton = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    Widget? suffixWidget;
    if (showClearButton && hasText) {
      suffixWidget = IconButton(
        icon: Icon(
          compact ? Icons.close : Icons.clear,
          color: AppColors.textSecondary.withOpacity(0.3),
          size: compact ? 16 : 20,
        ),
        onPressed: () {
          controller.clear();
          onChanged?.call('');
          onClear?.call();
        },
      );
    } else if (showFilterButton && onFilterTap != null) {
      suffixWidget = IconButton(
        icon: Icon(Icons.tune_rounded, color: AppColors.textSecondary.withOpacity(0.3), size: 26),
        onPressed: onFilterTap,
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      style: AppTextStyles.bodyMedium,
      decoration: compact
          ? AppInputDecorations.searchCompact(
              hintText: hintText,
              suffixIcon: suffixWidget,
            )
          : AppInputDecorations.search(
              hintText: hintText,
              suffixIcon: suffixWidget,
            ),
    );
  }
}
