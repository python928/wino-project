import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/accessibility/semantic_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_input_decorations.dart';
import '../../../core/theme/app_text_styles.dart';

class AuthFlowScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback? onBack;
  final int? currentStep;
  final int? totalSteps;
  final String? progressLabel;
  final double headerHeight;

  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.onBack,
    this.currentStep,
    this.totalSteps,
    this.progressLabel,
    this.headerHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Column(
          children: [
            _AuthHeader(
              title: title,
              subtitle: subtitle,
              icon: icon,
              onBack: onBack,
              currentStep: currentStep,
              totalSteps: totalSteps,
              progressLabel: progressLabel,
              headerHeight: headerHeight,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppConstants.spacing16,
                  0,
                  AppConstants.spacing16,
                  AppConstants.spacing24 + bottomInset,
                ),
                child: Transform.translate(
                  offset: const Offset(0, -AppConstants.spacing24),
                  child: AuthSurfaceCard(child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppConstants.spacing20,
      AppConstants.spacing20,
      AppConstants.spacing20,
      AppConstants.spacing24,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class AuthSectionIntro extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? eyebrow;

  const AuthSectionIntro({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacing8),
        ],
        Text(
          title,
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing8),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class AuthDateFieldGroup extends StatelessWidget {
  final String label;
  final String dayLabel;
  final String monthLabel;
  final String yearLabel;
  final String dayHint;
  final String monthHint;
  final String yearHint;
  final TextEditingController dayController;
  final TextEditingController monthController;
  final TextEditingController yearController;
  final FocusNode? dayFocusNode;
  final FocusNode? monthFocusNode;
  final FocusNode? yearFocusNode;
  final String? helperText;
  final String? errorText;
  final VoidCallback? onChanged;

  const AuthDateFieldGroup({
    super.key,
    required this.label,
    required this.dayLabel,
    required this.monthLabel,
    required this.yearLabel,
    required this.dayHint,
    required this.monthHint,
    required this.yearHint,
    required this.dayController,
    required this.monthController,
    required this.yearController,
    this.dayFocusNode,
    this.monthFocusNode,
    this.yearFocusNode,
    this.helperText,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _AuthDatePartField(
                label: dayLabel,
                hint: dayHint,
                controller: dayController,
                focusNode: dayFocusNode,
                nextFocusNode: monthFocusNode,
                maxLength: 2,
                autofillHints: const [AutofillHints.birthdayDay],
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              flex: 2,
              child: _AuthDatePartField(
                label: monthLabel,
                hint: monthHint,
                controller: monthController,
                focusNode: monthFocusNode,
                nextFocusNode: yearFocusNode,
                maxLength: 2,
                autofillHints: const [AutofillHints.birthdayMonth],
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            Expanded(
              flex: 3,
              child: _AuthDatePartField(
                label: yearLabel,
                hint: yearHint,
                controller: yearController,
                focusNode: yearFocusNode,
                maxLength: 4,
                autofillHints: const [AutofillHints.birthdayYear],
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        if (errorText != null || helperText != null) ...[
          const SizedBox(height: AppConstants.spacing10),
          AuthInlineMessage(
            text: errorText ?? helperText!,
            isError: errorText != null,
          ),
        ],
      ],
    );
  }
}

class AuthChoiceCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const AuthChoiceCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? AppColors.primaryColor : AppColors.borderPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        child: AnimatedContainer(
          duration: AppConstants.shortDuration,
          padding: const EdgeInsets.all(AppConstants.spacing16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLightShade
                : AppColors.surfacePrimary,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryColor.withValues(alpha: 0.12)
                      : AppColors.surfaceSecondary,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.primaryColor
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppConstants.spacing4),
                      Text(
                        description!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                    selected ? AppColors.primaryColor : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthSelectionField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final String? helperText;
  final String? errorText;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const AuthSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.value,
    this.helperText,
    this.errorText,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing10),
        Semantics(
          button: true,
          enabled: onTap != null,
          label: label,
          value: hasValue ? value : hint,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            child: AnimatedContainer(
              duration: AppConstants.shortDuration,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(
                  color: errorText != null
                      ? AppColors.errorRed
                      : hasValue
                          ? AppColors.primaryColor.withValues(alpha: 0.4)
                          : AppColors.borderPrimary,
                  width: errorText != null ? 1.4 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasValue
                          ? AppColors.primaryLightShade
                          : AppColors.surfaceSecondary,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(AppConstants.spacing10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            icon,
                            color: hasValue
                                ? AppColors.primaryColor
                                : AppColors.textSecondary,
                          ),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: Text(
                      hasValue ? value! : hint,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: hasValue
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            hasValue ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null || helperText != null) ...[
          const SizedBox(height: AppConstants.spacing10),
          AuthInlineMessage(
            text: errorText ?? helperText!,
            isError: errorText != null,
          ),
        ],
      ],
    );
  }
}

class AuthSelectionPreviewChips extends StatelessWidget {
  final List<String> labels;
  final ValueChanged<int>? onRemoveAt;

  const AuthSelectionPreviewChips({
    super.key,
    required this.labels,
    this.onRemoveAt,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppConstants.spacing8,
      runSpacing: AppConstants.spacing8,
      children: List.generate(labels.length, (index) {
        final label = labels[index];

        return Container(
          padding: const EdgeInsetsDirectional.only(
            start: AppConstants.spacing12,
            end: AppConstants.spacing8,
            top: AppConstants.spacing8,
            bottom: AppConstants.spacing8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLightShade,
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onRemoveAt != null) ...[
                const SizedBox(width: AppConstants.spacing6),
                InkWell(
                  onTap: () => onRemoveAt!(index),
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(AppConstants.spacing2),
                    child: Icon(
                      Icons.close_rounded,
                      size: AppConstants.iconSmall,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class AuthInlineMessage extends StatelessWidget {
  final String text;
  final bool isError;

  const AuthInlineMessage({
    super.key,
    required this.text,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.errorRed : AppColors.textSecondary;
    final icon =
        isError ? Icons.error_outline_rounded : Icons.info_outline_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppConstants.spacing6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: isError ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;
  final int? currentStep;
  final int? totalSteps;
  final String? progressLabel;
  final double headerHeight;

  const _AuthHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
    required this.progressLabel,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    final hasProgress = currentStep != null && totalSteps != null;

    return Container(
      height: headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
      child: Stack(
        children: [
          const Positioned(
              top: -56, right: -48, child: _HeaderCircle(188, 0.08)),
          const Positioned(top: 8, right: 18, child: _HeaderCircle(104, 0.10)),
          const Positioned(top: 58, left: -34, child: _HeaderCircle(120, 0.06)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacing12,
                AppConstants.spacing8,
                AppConstants.spacing12,
                AppConstants.spacing20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: SemanticHelpers.minTouchTargetSize,
                    child: Row(
                      children: [
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 156;
                        final isExtraCompact = constraints.maxHeight < 136;
                        final iconBoxSize =
                            isExtraCompact ? 52.0 : (isCompact ? 60.0 : 68.0);
                        final iconSize =
                            isExtraCompact ? 26.0 : (isCompact ? 30.0 : 34.0);
                        final titleSpacing = isExtraCompact
                            ? AppConstants.spacing8
                            : (isCompact
                                ? AppConstants.spacing12
                                : AppConstants.spacing16);
                        final subtitleSpacing = isCompact
                            ? AppConstants.spacing6
                            : AppConstants.spacing8;
                        final titleStyle =
                            (isCompact ? AppTextStyles.h3 : AppTextStyles.h2)
                                .copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        );
                        final subtitleStyle = (isCompact
                                ? AppTextStyles.bodySmall
                                : AppTextStyles.bodyMedium)
                            .copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        );

                        return Center(
                          child: SizedBox(
                            width: constraints.maxWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacing8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: iconBoxSize,
                                    height: iconBoxSize,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radiusLarge),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                  SizedBox(height: titleSpacing),
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                  SizedBox(height: subtitleSpacing),
                                  Text(
                                    subtitle,
                                    textAlign: TextAlign.center,
                                    maxLines: isCompact ? 2 : 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: subtitleStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasProgress)
                    Semantics(
                      label: progressLabel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progressLabel ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing10),
                          Row(
                            children: List.generate(totalSteps!, (index) {
                              final isActive = index < currentStep!;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    end: index == totalSteps! - 1
                                        ? 0
                                        : AppConstants.spacing8,
                                  ),
                                  child: AnimatedContainer(
                                    duration: AppConstants.shortDuration,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.spacing8),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthDatePartField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLength;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final Iterable<String>? autofillHints;
  final VoidCallback? onChanged;

  const _AuthDatePartField({
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.autofillHints,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacing6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: nextFocusNode != null
              ? TextInputAction.next
              : TextInputAction.done,
          textAlign: TextAlign.center,
          maxLength: maxLength,
          autofillHints: autofillHints,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          decoration: AppInputDecorations.form(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing10,
              vertical: AppConstants.spacing14,
            ),
          ).copyWith(counterText: ''),
          onChanged: (value) {
            if (value.length >= maxLength && nextFocusNode != null) {
              nextFocusNode!.requestFocus();
            }
            onChanged?.call();
          },
        ),
      ],
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeaderCircle(this.size, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
