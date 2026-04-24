import 'package:wino/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPayloadDialog extends StatelessWidget {
  final String payload;
  final String title;
  final bool showPayloadText;

  const QrPayloadDialog({
    super.key,
    required this.payload,
    required this.title,
    this.showPayloadText = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 220,
            ),
            if (showPayloadText) ...[
              const SizedBox(height: 10),
              SelectableText(
                payload,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Close')),
        ),
      ],
    );
  }
}
