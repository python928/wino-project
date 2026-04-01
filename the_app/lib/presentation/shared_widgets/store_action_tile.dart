import 'package:flutter/material.dart';

class StoreActionTile extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final double verticalPadding;

  const StoreActionTile({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.isLoading = false,
    this.verticalPadding = 12,
  });

  bool get _isEnabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final effectiveForeground =
        _isEnabled ? foregroundColor : foregroundColor.withValues(alpha: 0.55);
    final effectiveBackground =
        _isEnabled ? backgroundColor : backgroundColor.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  (borderColor ?? effectiveForeground).withValues(alpha: 0.14),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 22,
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: effectiveForeground,
                            ),
                          )
                        : Icon(
                            icon,
                            size: 22,
                            color: effectiveForeground,
                          ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveForeground,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
