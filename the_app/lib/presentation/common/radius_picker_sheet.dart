import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

void showRadiusPickerSheet(
  BuildContext context, {
  required double initialRadius,
  required ValueChanged<double> onRadiusChanged,
}) {
  const double minKm = 1;
  const double maxKm = 1000;

  double sliderValue = initialRadius.clamp(minKm, maxKm);
  final TextEditingController textCtrl =
      TextEditingController(text: sliderValue.toInt().toString());

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        void syncFromSlider(double val) {
          sliderValue = val;
          textCtrl.text = val.toInt().toString();
          textCtrl.selection =
              TextSelection.collapsed(offset: textCtrl.text.length);
        }

        void syncFromText(String raw) {
          final parsed = int.tryParse(raw);
          if (parsed != null) {
            final clamped = parsed.clamp(minKm.toInt(), maxKm.toInt());
            setModalState(() => sliderValue = clamped.toDouble());
          }
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radar,
                            color: AppColors.primaryColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Search Radius',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onRadiusChanged(0); // 0 = clear
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                        child: const Text('Clear',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.25),
                          ),
                        ),
                        child: TextField(
                          controller: textCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: (val) {
                            setModalState(() => syncFromText(val));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${minKm.toInt()} – ${maxKm.toInt()} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: AppColors.primaryColor,
                      inactiveTrackColor:
                          AppColors.primaryColor.withOpacity(0.15),
                      thumbColor: AppColors.primaryColor,
                      overlayColor: AppColors.primaryColor.withOpacity(0.12),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: sliderValue,
                      min: minKm,
                      max: maxKm,
                      divisions: (maxKm - minKm).toInt(),
                      onChanged: (val) {
                        setModalState(() => syncFromSlider(val));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${minKm.toInt()} km',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                        Text('250 km',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                        Text('500 km',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                        Text('${maxKm.toInt()} km',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onRadiusChanged(sliderValue);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Apply  ${sliderValue.toInt()} km',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
