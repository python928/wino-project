import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_button.dart';
import '../../core/providers/post_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/subscription_service.dart';
import '../../data/models/post_model.dart';
import '../../data/models/offer_model.dart';
import 'widgets/product_picker_sheet.dart';
import '../subscription/subscription_gate.dart';

class AddPromotionScreen extends StatefulWidget {
  final Offer? offer;

  const AddPromotionScreen({super.key, this.offer});

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  Post? _selectedProduct;
  Offer? _existingOffer;
  final _formKey = GlobalKey<FormState>();
  final _newPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();

    final offer = widget.offer;
    if (offer != null) {
      _selectedProduct = offer.product;
      _existingOffer = offer;
      _isEditMode = true;
      _isAvailable = offer.isAvailable;
      _discountPercentageController.text = offer.discountPercentage.toString();
      _newPriceController.text = offer.newPrice.toStringAsFixed(2);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure posts are loaded
      final provider = Provider.of<PostProvider>(context, listen: false);
      if (provider.myPosts.isEmpty) {
        // Assuming user ID is available in AuthProvider or similar,
        // but for now we rely on ProfileScreen having loaded them.
        // If empty, we might need to fetch.
      }
    });
  }

  @override
  void dispose() {
    _newPriceController.dispose();
    _discountPercentageController.dispose();
    super.dispose();
  }

  Future<void> _openProductPicker() async {
    if (_isEditMode) return;
    final provider = context.read<PostProvider>();
    final picked = await showProductPickerBottomSheet(
      context,
      products: provider.myPosts,
      title: 'Select Product',
    );
    if (picked != null) _onProductSelected(picked);
  }

  void _clearSelectedProduct() {
    setState(() {
      _selectedProduct = null;
      _existingOffer = null;
      _isEditMode = false;
      _isAvailable = true;
      _newPriceController.clear();
      _discountPercentageController.clear();
    });
  }

  void _onProductSelected(Post post) {
    final provider = Provider.of<PostProvider>(context, listen: false);

    // Check if product already has a promotion
    final existingOffer =
        provider.myOffers.where((o) => o.product.id == post.id).firstOrNull;

    if (existingOffer != null) {
      _showExistingPromotionDialog(post, existingOffer);
    } else {
      setState(() {
        _selectedProduct = post;
        _existingOffer = null;
        _isEditMode = false;
        _newPriceController.clear();
        _discountPercentageController.clear();
      });
    }
  }

  void _showExistingPromotionDialog(Post post, Offer offer) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Existing Discount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: post.image != null && post.image!.isNotEmpty
                            ? Image.network(post.image!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey[300],
                                child:
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${offer.discountPercentage}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Helpers.formatPrice(offer.newPrice),
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This product already has a discount. Do you want to edit it?',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            AppTextButton(
              onPressed: () => Navigator.pop(context),
              text: 'Cancel',
            ),
            AppPrimaryButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedProduct = post;
                  _existingOffer = offer;
                  _isEditMode = true;
                  _isAvailable = offer.isAvailable;
                  _discountPercentageController.text =
                      offer.discountPercentage.toString();
                  _newPriceController.text = offer.newPrice.toStringAsFixed(2);
                });
              },
              text: 'Edit Discount',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOffer() async {
    final offer = _existingOffer;
    if (!_isEditMode || offer == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          title: const Text('Delete Discount?'),
          content:
              const Text('This will remove the discount from this product.'),
          actions: [
            AppTextButton(
              onPressed: () => Navigator.pop(context, false),
              text: 'Cancel',
            ),
            AppPrimaryButton(
              onPressed: () => Navigator.pop(context, true),
              text: 'Delete',
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true) return;

    try {
      setState(() => _isLoading = true);
      await context.read<PostProvider>().deleteOffer(offer.id);
      if (mounted) {
        Helpers.showSnackBar(context, 'Discount deleted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to delete discount: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNewPriceChanged(String value) {
    if (_selectedProduct == null || value.isEmpty) return;

    final newPrice = double.tryParse(value);
    if (newPrice != null) {
      final originalPrice = _selectedProduct!.price;
      if (originalPrice > 0) {
        final discount = ((originalPrice - newPrice) / originalPrice) * 100;
        _discountPercentageController.text = discount.toStringAsFixed(0);
        setState(() {});
      }
    }
  }

  void _onPercentageChanged(String value) {
    if (_selectedProduct == null || value.isEmpty) return;

    final percentage = double.tryParse(value);
    if (percentage != null) {
      final originalPrice = _selectedProduct!.price;
      final newPrice = originalPrice * (1 - (percentage / 100));
      _newPriceController.text = newPrice.toStringAsFixed(2);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      if (_selectedProduct == null) {
        Helpers.showSnackBar(context, 'Please select a product');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final percentage = int.parse(_discountPercentageController.text);
      final provider = Provider.of<PostProvider>(context, listen: false);

      if (_isEditMode && _existingOffer != null) {
        // Update existing offer
        await provider.updateOffer(
          offerId: _existingOffer!.id,
          discountPercentage: percentage,
          isAvailable: _isAvailable,
        );

        if (mounted) {
          Helpers.showSnackBar(context, 'Discount edited successfully');
          Navigator.pop(context, true);
        }
      } else {
        // Create new offer
        await provider.createOffer(
          productId: _selectedProduct!.id,
          discountPercentage: percentage,
          isAvailable: _isAvailable,
        );

        if (mounted) {
          Helpers.showSnackBar(context, 'Discount added successfully');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        if (SubscriptionService.isSubscriptionRequiredError(e)) {
          await showSubscriptionRequiredWindow(context);
          return;
        }
        Helpers.showSnackBar(
            context, 'Failed to ${_isEditMode ? 'edit' : 'add'} discount: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Discount' : 'Add Discount'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isEditMode && _existingOffer != null)
              IconButton(
                onPressed: _isLoading ? null : _confirmDeleteOffer,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Product',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Product Selection Widget
                InkWell(
                  onTap: _isEditMode ? null : _openProductPicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (_selectedProduct != null)
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: (_selectedProduct!.image == null ||
                                      _selectedProduct!.image!.isEmpty)
                                  ? Container(
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image,
                                          size: 20, color: Colors.grey),
                                    )
                                  : Image.network(
                                      _selectedProduct!.image!,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.broken_image,
                                              size: 20, color: Colors.grey),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        if (_selectedProduct != null) const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedProduct?.title ??
                                'Tap to select product...',
                            style: TextStyle(
                              color: _selectedProduct == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                        if (_selectedProduct != null && !_isEditMode)
                          IconButton(
                            onPressed: _clearSelectedProduct,
                            icon: const Icon(Icons.close),
                            splashRadius: 18,
                          )
                        else if (_selectedProduct == null && !_isEditMode)
                          const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),

                if (_selectedProduct != null) ...[
                  const SizedBox(height: 24),

                  // Current Price Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Original Price:'),
                            Text(
                              Helpers.formatPrice(_selectedProduct!.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount Percentage:'),
                            Text(
                              _discountPercentageController.text.isEmpty
                                  ? '0%'
                                  : '${_discountPercentageController.text}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('New Price:'),
                            Text(
                              _newPriceController.text.isEmpty
                                  ? Helpers.formatPrice(_selectedProduct!.price)
                                  : '${_newPriceController.text} DZD',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      // Discount Percentage
                      Expanded(
                        child: AppTextField(
                          controller: _discountPercentageController,
                          label: 'Discount Percentage (%)',
                          hint: '0',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          suffixText: '%',
                          onChanged: _onPercentageChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Required';
                            final n = double.tryParse(value);
                            if (n == null || n <= 0 || n >= 100)
                              return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // New Price
                      Expanded(
                        child: AppTextField(
                          controller: _newPriceController,
                          label: 'New Price',
                          hint: '0',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          suffixText: 'DZD',
                          onChanged: _onNewPriceChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Required';
                            final n = double.tryParse(value);
                            final original = _selectedProduct!.price;
                            if (n == null || n <= 0 || n >= original)
                              return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available'),
                    subtitle: const Text('Show this discount to customers'),
                    value: _isAvailable,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _isAvailable = value);
                          },
                  ),

                  const SizedBox(height: 12),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      text: _isLoading
                          ? 'Saving...'
                          : (_isEditMode ? 'Save Changes' : 'Apply Discount'),
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
