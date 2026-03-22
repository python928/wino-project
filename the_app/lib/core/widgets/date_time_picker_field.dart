import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable Date & Time picker field component following app design patterns
///
/// Features:
/// - Selection of both date and time
/// - Clear display of selected datetime
/// - Optional/required state support
/// - Inline clear button
/// - Consistent with app's purple color scheme
/// - Fully customizable
class DateTimePickerField extends StatefulWidget {
  /// The selected DateTime value
  final DateTime? value;

  /// Callback when value changes
  final ValueChanged<DateTime> onChanged;

  /// Callback when value is cleared
  final VoidCallback? onCleared;

  /// Field label
  final String label;

  /// Hint text when no value selected
  final String hint;

  /// Icon to show before label
  final IconData? icon;

  /// Whether field is required (shows red *)
  final bool isRequired;

  /// Whether field is disabled
  final bool isEnabled;

  /// Date format pattern
  final String dateFormat;

  /// Time format pattern
  final String timeFormat;

  /// Minimum date allowed
  final DateTime? minDate;

  /// Maximum date allowed
  final DateTime? maxDate;

  /// Whether to show time picker (not just date)
  final bool showTime;

  /// Optional validator function
  final String? Function(DateTime?)? validator;

  const DateTimePickerField({
    super.key,
    required this.label,
    required this.onChanged,
    this.value,
    this.hint = 'Tap to select date',
    this.icon,
    this.isRequired = false,
    this.isEnabled = true,
    this.dateFormat = 'MMM dd, yyyy',
    this.timeFormat = 'hh:mm a',
    this.minDate,
    this.maxDate,
    this.showTime = true,
    this.onCleared,
    this.validator,
  });

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  static const _pickerLocale = Locale('en', 'US');

  String _formatValue(DateTime? dt) {
    if (dt == null) return widget.hint;

    try {
      String result = intl.DateFormat(widget.dateFormat, 'en').format(dt);
      if (widget.showTime) {
        result += ' at ${intl.DateFormat(widget.timeFormat, 'en').format(dt)}';
      }
      return result;
    } catch (e) {
      return widget.hint;
    }
  }

  Future<void> _pickDateTime() async {
    if (!widget.isEnabled) return;

    // Step 1: Pick date
    final initialDate = widget.value ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.minDate ?? DateTime(2000),
      lastDate: widget.maxDate ?? DateTime(2100),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return Localizations.override(
          context: context,
          locale: _pickerLocale,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: child,
          ),
        );
      },
    );

    if (pickedDate == null) return;

    // Step 2: Pick time if enabled
    if (widget.showTime) {
      final initialTime = widget.value != null
          ? TimeOfDay.fromDateTime(widget.value!)
          : TimeOfDay.now();

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return Localizations.override(
            context: context,
            locale: _pickerLocale,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: child,
            ),
          );
        },
      );

      if (pickedTime == null) return;

      final selected = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      widget.onChanged(selected);
    } else {
      widget.onChanged(pickedDate);
    }
  }

  void _clear() {
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final isDisabled = !widget.isEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Picker Field
        GestureDetector(
          onTap: isDisabled ? null : _pickDateTime,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDisabled ? AppColors.blackColor5 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    hasValue ? AppColors.primaryColor : const Color(0xFFE0E0E0),
                width: hasValue ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icon
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: hasValue
                        ? AppColors.primaryColor
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                ],
                // Text
                Expanded(
                  child: Text(
                    _formatValue(widget.value),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Clear button (if has value)
                if (hasValue && widget.isEnabled)
                  GestureDetector(
                    onTap: _clear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.clear_rounded,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Validation error message
        if (widget.validator != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Builder(
              builder: (context) {
                final errorMsg = widget.validator!(widget.value);
                if (errorMsg == null) return const SizedBox.shrink();
                return Text(
                  errorMsg,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.errorRed,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Compact version of DateTimePickerField - useful for inline/dense layouts
///
/// Simplified UI without label, for use in lists or compact layouts
class DateTimePickerButton extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;
  final String label;
  final IconData icon;
  final bool showTime;
  final String? dateFormat;
  final String? timeFormat;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool isEnabled;

  const DateTimePickerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.value,
    this.onCleared,
    this.showTime = true,
    this.dateFormat,
    this.timeFormat,
    this.minDate,
    this.maxDate,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DateTimePickerField(
      label: label,
      onChanged: onChanged,
      value: value,
      icon: icon,
      onCleared: onCleared,
      showTime: showTime,
      dateFormat: dateFormat ?? 'MMM dd, yyyy',
      timeFormat: timeFormat ?? 'hh:mm a',
      minDate: minDate,
      maxDate: maxDate,
      isEnabled: isEnabled,
      hint: 'Not set',
    );
  }
}

/// Range date picker - select start and end dates together
///
/// Useful for promotions, campaigns, subscriptions with duration
class DateRangePickerField extends StatefulWidget {
  /// Start date value
  final DateTime? startValue;

  /// End date value
  final DateTime? endValue;

  /// Callback when start date changes
  final ValueChanged<DateTime> onStartChanged;

  /// Callback when end date changes
  final ValueChanged<DateTime> onEndChanged;

  /// Section title
  final String title;

  /// Label for start date
  final String startLabel;

  /// Label for end date
  final String endLabel;

  /// Icon for start date
  final IconData startIcon;

  /// Icon for end date
  final IconData endIcon;

  /// Whether to show time picker
  final bool showTime;

  /// Minimum date allowed
  final DateTime? minDate;

  /// Maximum date allowed
  final DateTime? maxDate;

  /// Callback when start is cleared
  final VoidCallback? onStartCleared;

  /// Callback when end is cleared
  final VoidCallback? onEndCleared;

  const DateRangePickerField({
    super.key,
    required this.onStartChanged,
    required this.onEndChanged,
    this.startValue,
    this.endValue,
    this.title = 'Schedule',
    this.startLabel = 'Start Date',
    this.endLabel = 'End Date',
    this.startIcon = Icons.schedule,
    this.endIcon = Icons.timer_off_outlined,
    this.showTime = true,
    this.minDate,
    this.maxDate,
    this.onStartCleared,
    this.onEndCleared,
  });

  @override
  State<DateRangePickerField> createState() => _DateRangePickerFieldState();
}

class _DateRangePickerFieldState extends State<DateRangePickerField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        // Start date
        DateTimePickerField(
          label: widget.startLabel,
          icon: widget.startIcon,
          value: widget.startValue,
          onChanged: widget.onStartChanged,
          onCleared: widget.onStartCleared,
          showTime: widget.showTime,
          minDate: widget.minDate,
          maxDate: widget.endValue ?? widget.maxDate,
        ),
        const SizedBox(height: 16),
        // End date
        DateTimePickerField(
          label: widget.endLabel,
          icon: widget.endIcon,
          value: widget.endValue,
          onChanged: widget.onEndChanged,
          onCleared: widget.onEndCleared,
          showTime: widget.showTime,
          minDate: widget.startValue ?? widget.minDate,
          maxDate: widget.maxDate,
        ),
        // Info message if both dates selected
        if (widget.startValue != null && widget.endValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildDurationInfo(),
          ),
      ],
    );
  }

  Widget _buildDurationInfo() {
    final start = widget.startValue!;
    final end = widget.endValue!;

    if (end.isBefore(start)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.errorRed.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.errorRed,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'End date must be after start date',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final duration = end.difference(start);
    final days = duration.inDays + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Duration: $days day${days > 1 ? 's' : ''}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
