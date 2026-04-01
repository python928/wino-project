import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wallet_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';

class CoinPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> pack;

  const CoinPaymentScreen({
    super.key,
    required this.pack,
  });

  @override
  State<CoinPaymentScreen> createState() => _CoinPaymentScreenState();
}

class _CoinPaymentScreenState extends State<CoinPaymentScreen> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _proofImages = [];
  bool _submitting = false;

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _pickProofImages() async {
    try {
      final remaining = 3 - _proofImages.length;
      if (remaining <= 0) return;
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() {
          _proofImages.addAll(picked.take(remaining));
        });
        return;
      }

      // Fallback for environments where multi-pick is unreliable.
      final single = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (single == null) return;
      setState(() {
        _proofImages.add(single);
      });
    } catch (_) {
      if (mounted) {
        Helpers.showSnackBar(context, context.tr('Could not select images'),
            isError: true);
      }
    }
  }

  Widget _buildPreview(XFile image) {
    return FutureBuilder<Uint8List>(
      future: image.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: 92,
            height: 92,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_proofImages.isEmpty) {
      Helpers.showSnackBar(
          context, context.tr('Please upload at least one payment proof.'));
      return;
    }
    setState(() => _submitting = true);
    try {
      final resp = await context.read<WalletProvider>().buyPack(
            packId: (widget.pack['id'] ?? '').toString(),
            images: List<XFile>.from(_proofImages),
            paymentNote: _noteController.text.trim(),
          );

      if (!mounted) return;
      final purchase = (resp['purchase'] as Map?)?.cast<String, dynamic>();
      final requestId = purchase?['id']?.toString() ?? '-';
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('Request submitted')),
          content: Text(
            '${context.tr('Payment request')} #$requestId ${context.tr('is pending server approval.')}\n'
            '${context.tr('Coins are added after approval.')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('OK')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = _asInt(widget.pack['coins']);
    final price = (widget.pack['price'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Coin Payment')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Coins'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('$coins ${context.tr('coins')}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$price ${context.tr('DZD')}',
                    style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Payment note (optional)'),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: context.tr('Transfer reference / notes'),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Payment proof images'),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Upload 1 to 3 images. Your request will be reviewed by admin.',
                  ),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._proofImages.asMap().entries.map(
                          (entry) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildPreview(entry.value),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _proofImages.removeAt(entry.key)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    if (_proofImages.length < 3)
                      OutlinedButton.icon(
                        onPressed: _pickProofImages,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(context.tr('Add images')),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(context.tr('Submit payment request')),
          ),
        ],
      ),
    );
  }
}
