import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Ultra-modern text field with floating label and micro-animations
class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final Color? fillColor;
  final List<TextInputFormatter>? inputFormatters;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.fillColor,
    this.inputFormatters,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  bool _hasContent = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );

    _labelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: AppTheme.defaultCurve),
    );

    _borderColorAnimation = ColorTween(
      begin: AppColors.borderPrimary,
      end: AppColors.primaryColor,
    ).animate(_animController);

    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    _hasContent = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChange);
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _animController.forward();
    } else if (!_hasContent) {
      _animController.reverse();
    }
    setState(() {});
  }

  void _onTextChange() {
    final hasContent = widget.controller.text.isNotEmpty;
    if (hasContent != _hasContent) {
      setState(() => _hasContent = hasContent);
      if (hasContent && !_focusNode.hasFocus) {
        _animController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _focusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction ?? TextInputAction.next,
                obscureText: widget.obscureText && !_isPasswordVisible,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                inputFormatters: widget.inputFormatters,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: _focusNode.hasFocus
                              ? AppColors.primaryColor
                              : AppColors.textSecondary,
                          size: 22,
                        )
                      : null,
                  suffixIcon: widget.obscureText
                      ? IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                            HapticFeedback.lightImpact();
                          },
                        )
                      : widget.suffixIcon != null
                          ? IconButton(
                              icon: Icon(
                                widget.suffixIcon,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                              onPressed: widget.onSuffixTap,
                            )
                          : null,
                  filled: true,
                  fillColor: widget.fillColor ??
                      (_focusNode.hasFocus
                          ? AppColors.primaryColor.withOpacity(0.03)
                          : AppColors.surfaceSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _borderColorAnimation.value!,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.borderPrimary,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.errorRed,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.errorRed,
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: _focusNode.hasFocus
                        ? AppColors.primaryColor
                        : AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(
                    color: AppColors.textHint.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  counterText: '',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Modern Search Field with animations and voice search
class ModernSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final bool showVoiceSearch;
  final bool autoFocus;

  const ModernSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.onVoiceSearch,
    this.showVoiceSearch = false,
    this.autoFocus = false,
  });

  @override
  State<ModernSearchField> createState() => _ModernSearchFieldState();
}

class _ModernSearchFieldState extends State<ModernSearchField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.primaryColor
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.textHint.withOpacity(0.6),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _focusNode.hasFocus
                    ? AppColors.primaryColor
                    : AppColors.textSecondary,
                size: 24,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          widget.onChanged?.call('');
                          widget.onClear?.call();
                          HapticFeedback.lightImpact();
                        },
                      ),
                    ),
                  if (widget.showVoiceSearch)
                    IconButton(
                      icon: const Icon(
                        Icons.mic_outlined,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        widget.onVoiceSearch?.call();
                        HapticFeedback.mediumImpact();
                      },
                    ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modern Pin Input Field
class ModernPinField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool obscureText;

  const ModernPinField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.obscureText = false,
  });

  @override
  State<ModernPinField> createState() => _ModernPinFieldState();
}

class _ModernPinFieldState extends State<ModernPinField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final pin = _controllers.map((c) => c.text).join();
        if (pin.length == widget.length) {
          widget.onCompleted(pin);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 56,
          height: 64,
          child: TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              obscureText: widget.obscureText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => _onChanged(index, value),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: _focusNodes[index].hasFocus
                    ? AppColors.primaryColor.withOpacity(0.05)
                    : AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _focusNodes[index].hasFocus
                        ? AppColors.primaryColor
                        : AppColors.borderPrimary,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _controllers[index].text.isNotEmpty
                        ? AppColors.primaryColor.withOpacity(0.5)
                        : AppColors.borderPrimary,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
