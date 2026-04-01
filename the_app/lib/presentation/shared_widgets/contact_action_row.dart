import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';

import '../../core/utils/helpers.dart';
import 'store_action_tile.dart';

class ContactActionRow extends StatelessWidget {
  final String? phone;
  final String? whatsapp;
  final Widget? trailingAction;
  final bool showTitle;
  final String title;
  final TextStyle? titleStyle;
  final double buttonVerticalPadding;

  const ContactActionRow({
    super.key,
    this.phone,
    this.whatsapp,
    this.trailingAction,
    this.showTitle = false,
    this.title = 'Contact Store',
    this.titleStyle,
    this.buttonVerticalPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    final phoneValue = (phone ?? '').trim();
    final whatsappValue = (whatsapp ?? '').trim();
    if (phoneValue.isEmpty && whatsappValue.isEmpty && trailingAction == null) {
      return const SizedBox.shrink();
    }

    final content = Row(
      children: [
        if (phoneValue.isNotEmpty)
          Expanded(
            child: StoreActionTile(
              onTap: () => Helpers.launchURL('tel:$phoneValue'),
              icon: Icons.phone_outlined,
              label: context.tr('Call'),
              backgroundColor: const Color(0xFFF3EEFF),
              foregroundColor: const Color(0xFF6F42E5),
              verticalPadding: buttonVerticalPadding,
            ),
          ),
        if (phoneValue.isNotEmpty &&
            (whatsappValue.isNotEmpty || trailingAction != null))
          const SizedBox(width: 10),
        if (whatsappValue.isNotEmpty)
          Expanded(
            child: StoreActionTile(
              onTap: () => Helpers.launchURL(
                'https://wa.me/${_normalizeWhatsApp(whatsappValue)}',
              ),
              icon: Icons.chat_bubble_outline_rounded,
              label: context.tr('WhatsApp'),
              backgroundColor: const Color(0xFFE8F8EF),
              foregroundColor: const Color(0xFF17A34A),
              verticalPadding: buttonVerticalPadding,
            ),
          ),
        if (whatsappValue.isNotEmpty && trailingAction != null)
          const SizedBox(width: 10),
        if (trailingAction != null) Expanded(child: trailingAction!),
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
