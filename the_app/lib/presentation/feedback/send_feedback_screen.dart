import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import '../../core/services/api_service.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  final TextEditingController _deviceController = TextEditingController();
  String _type = 'problem';
  bool _isSubmitting = false;
  XFile? _screenshot;

  @override
  void dispose() {
    _messageController.dispose();
    _appVersionController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    setState(() => _screenshot = file);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackWriteMessageRequired)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final fields = {
        'type': _type,
        'message': message,
        'app_version': _appVersionController.text.trim(),
        'platform': Platform.operatingSystem,
        'device_info': _deviceController.text.trim(),
      };
      if (_screenshot != null) {
        await ApiService.postMultipart(ApiConfig.feedback, fields, _screenshot!, 'screenshot');
      } else {
        await ApiService.post(ApiConfig.feedback, fields);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackSubmitSuccess)),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackSubmitError)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedbackTitleSend)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: [
              DropdownMenuItem(
                value: 'problem',
                child: Text(l10n.feedbackTypeProblem),
              ),
              DropdownMenuItem(
                value: 'suggestion',
                child: Text(l10n.feedbackTypeSuggestion),
              ),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'problem'),
            decoration: InputDecoration(labelText: l10n.feedbackTypeLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: l10n.feedbackMessageLabel,
              hintText: l10n.feedbackMessageHint,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _appVersionController,
            decoration: InputDecoration(labelText: l10n.feedbackAppVersionOptional),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deviceController,
            decoration: InputDecoration(labelText: l10n.feedbackDeviceInfoOptional),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickScreenshot,
            icon: const Icon(Icons.image_outlined),
            label: Text(
              _screenshot == null
                  ? l10n.feedbackAttachScreenshotOptional
                  : l10n.feedbackScreenshotSelected,
            ),
          ),
          if (_screenshot != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_screenshot!.path),
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(
              _isSubmitting ? l10n.feedbackSending : l10n.feedbackTitleSend,
            ),
          ),
        ],
      ),
    );
  }
}
