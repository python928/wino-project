import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class ContactActionRow extends StatelessWidget {
  final String? phone;
  final String? whatsapp;
  final bool showTitle;
  final String title;
  final TextStyle? titleStyle;
  final double buttonVerticalPadding;

  const ContactActionRow({
    super.key,
    this.phone,
    this.whatsapp,
    this.showTitle = false,
    this.title = 'Contact Store',
    this.titleStyle,
    this.buttonVerticalPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final phoneValue = (phone ?? '').trim();
    final whatsappValue = (whatsapp ?? '').trim();
    if (phoneValue.isEmpty && whatsappValue.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = Row(
      children: [
        if (phoneValue.isNotEmpty)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Helpers.launchURL('tel:$phoneValue'),
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: Text(context.tr('Call')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        if (phoneValue.isNotEmpty && whatsappValue.isNotEmpty)
          const SizedBox(width: 10),
        if (whatsappValue.isNotEmpty)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Helpers.launchURL(
                'https://wa.me/${_normalizeWhatsApp(whatsappValue)}',
              ),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text(context.tr('WhatsApp')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                side: BorderSide(color: Colors.green.shade400),
                padding: EdgeInsets.symmetric(vertical: buttonVerticalPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
      ],
    );

    if (!showTitle) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(title),
          style: titleStyle ??
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  String _normalizeWhatsApp(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+213')) return digits.substring(1);
    if (digits.startsWith('213')) return digits;
    if (digits.startsWith('0')) return '213${digits.substring(1)}';
    return digits;
  }
}
