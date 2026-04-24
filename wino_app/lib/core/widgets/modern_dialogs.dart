import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'modern_buttons.dart';

/// Modern bottom sheet with smooth animations
class ModernBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModernBottomSheetContent(
        title: title,
        backgroundColor: backgroundColor,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  static Future<T?> showScrollable<T>({
    required BuildContext context,
    required List<Widget> children,
    String? title,
    bool isDismissible = true,
  }) {
    return show<T>(
      context: context,
      title: title,
      isDismissible: isDismissible,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class _ModernBottomSheetContent extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? backgroundColor;
  final double? maxHeight;

  const _ModernBottomSheetContent({
    this.title,
    required this.child,
    this.backgroundColor,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppColors.borderPrimary),
          ],
          // Content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Alert Dialog with custom animations
class ModernDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _ModernAlertDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        icon: icon,
        iconColor: iconColor,
        isDanger: isDanger,
      ),
    );
  }

  static Future<T?> showSuccess<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return show<T>(
      context: context,
      title: title,
      message: message,
      confirmText: buttonText ?? 'OK',
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.successGreen,
    );
  }

  static Future<T?> showError<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return show<T>(
      context: context,
      title: title,
      message: message,
      confirmText: buttonText ?? 'OK',
      icon: Icons.error_rounded,
      iconColor: AppColors.errorRed,
    );
  }

  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDanger = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDanger: isDanger,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
    return result ?? false;
  }
}

class _ModernAlertDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;
  final bool isDanger;

  const _ModernAlertDialog({
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.iconColor,
    this.isDanger = false,
  });

  @override
  State<_ModernAlertDialog> createState() => _ModernAlertDialogState();
}

class _ModernAlertDialogState extends State<_ModernAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    if (widget.icon != null)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (widget.iconColor ?? AppColors.primaryColor)
                                  .withOpacity(0.15),
                              (widget.iconColor ?? AppColors.primaryColor)
                                  .withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          size: 32,
                          color: widget.iconColor ?? AppColors.primaryColor,
                        ),
                      ),
                    if (widget.icon != null) const SizedBox(height: 16),
                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        if (widget.cancelText != null) ...[
                          Expanded(
                            child: ModernSecondaryButton(
                              text: widget.cancelText!,
                              onPressed: () {
                                widget.onCancel?.call();
                                Navigator.pop(context);
                              },
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ModernPrimaryButton(
                            text: widget.confirmText ?? 'OK',
                            onPressed: () {
                              widget.onConfirm?.call();
                              Navigator.pop(context);
                            },
                            height: 48,
                            gradient: widget.isDanger
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.errorRed,
                                      Color(0xFFD32F2F),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modern Loading Dialog
class ModernLoadingDialog {
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ModernLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.pop(context);
  }
}

class _ModernLoadingDialog extends StatelessWidget {
  final String? message;

  const _ModernLoadingDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryColor,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Modern Snackbar/Toast
class ModernSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: _ModernSnackbarContent(
          message: message,
          type: type,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.info);
  }
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}

class _ModernSnackbarContent extends StatelessWidget {
  final String message;
  final SnackbarType type;

  const _ModernSnackbarContent({
    required this.message,
    required this.type,
  });

  Color get _backgroundColor {
    switch (type) {
      case SnackbarType.success:
        return AppColors.successGreen;
      case SnackbarType.error:
        return AppColors.errorRed;
      case SnackbarType.warning:
        return AppColors.warningAmber;
      case SnackbarType.info:
        return AppColors.primaryColor;
    }
  }

  IconData get _icon {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_rounded;
      case SnackbarType.error:
        return Icons.error_rounded;
      case SnackbarType.warning:
        return Icons.warning_rounded;
      case SnackbarType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _backgroundColor,
            _backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _backgroundColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Action Sheet
class ModernActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required List<ActionSheetItem> actions,
    String? title,
    String? cancelText,
  }) {
    return ModernBottomSheet.show<T>(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions.map(
            (action) => _ActionSheetButton(
              item: action,
              onTap: () {
                action.onTap?.call();
                Navigator.pop(context, action.value);
              },
            ),
          ),
          if (cancelText != null) ...[
            const SizedBox(height: 8),
            _ActionSheetButton(
              item: ActionSheetItem(
                title: cancelText,
                icon: Icons.close_rounded,
                isCancel: true,
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }
}

class ActionSheetItem<T> {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDanger;
  final bool isCancel;
  final T? value;

  const ActionSheetItem({
    required this.title,
    this.icon,
    this.onTap,
    this.isDanger = false,
    this.isCancel = false,
    this.value,
  });
}

class _ActionSheetButton extends StatelessWidget {
  final ActionSheetItem item;
  final VoidCallback onTap;

  const _ActionSheetButton({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.isDanger
        ? AppColors.errorRed
        : item.isCancel
            ? AppColors.textSecondary
            : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          item.isCancel ? FontWeight.w500 : FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
