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
  final String initialKind;
  final Post? initialProduct;

  const AddPromotionScreen({
    super.key,
    this.offer,
    this.initialKind = 'promotion',
    this.initialProduct,
  });

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  Post? _selectedProduct;
  Offer? _existingOffer;
  final _formKey = GlobalKey<FormState>();
  final _newPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _maxImpressionsController = TextEditingController();
  final _priorityBoostController = TextEditingController();
  final _targetWilayasController = TextEditingController();
  final _targetUsersController = TextEditingController();
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isAvailable = true;
  String _kind = 'promotion';
  String _placement = 'home_top';
  String _audienceMode = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic> _planFeatures = const {};
  Map<String, dynamic> _adInventory = const {};

  bool get _isAdOnlyFlow =>
      widget.initialKind == 'advertising' || widget.offer?.kind == 'advertising';

  bool get _isAdMode => _kind == 'advertising';

    String get _entityLabel => _isAdMode ? 'Sponsored Ad' : 'Discount';

    String get _screenTitle => _isEditMode ? 'Edit $_entityLabel' : (_isAdMode ? 'Create Sponsored Ad' : 'Add Discount');

    String get _productSelectionTitle => _isAdMode ? 'Select Product to Sponsor' : 'Select Product';

    String get _productSelectionHint =>
      _isAdMode ? 'Tap to select product to sponsor...' : 'Tap to select product...';

    String get _availabilityTitle => _isAdMode ? 'Ad Active' : 'Available';

    String get _availabilitySubtitle =>
      _isAdMode ? 'Show this sponsored ad to customers' : 'Show this discount to customers';

    String get _submitButtonText {
    if (_isLoading) return 'Saving...';
    if (_isEditMode) return 'Save Changes';
    return _isAdMode ? 'Launch Sponsored Ad' : 'Apply Discount';
    }

    String get _deleteTitle => _isAdMode ? 'Delete Sponsored Ad?' : 'Delete Discount?';

    String get _deleteDescription => _isAdMode
      ? 'This will remove the sponsored ad from this product.'
      : 'This will remove the discount from this product.';

    String get _deleteSuccessMessage =>
      _isAdMode ? 'Sponsored ad deleted successfully' : 'Discount deleted successfully';

    String get _deleteFailurePrefix => _isAdMode ? 'Failed to delete sponsored ad' : 'Failed to delete discount';

    String get _saveSuccessMessage =>
      _isAdMode ? 'Sponsored ad updated successfully' : 'Discount edited successfully';

    String get _createSuccessMessage =>
      _isAdMode ? 'Sponsored ad created successfully' : 'Discount added successfully';

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
      _kind = offer.kind;
      _placement = offer.placement;
      _audienceMode = offer.audienceMode;
      _maxImpressionsController.text =
          offer.maxImpressions?.toString() ?? '';
      _priorityBoostController.text = offer.priorityBoost.toString();
      _targetWilayasController.text = offer.targetWilayas.join(', ');
      _targetUsersController.text = offer.targetUserIds.join(', ');
    } else {
      _kind = widget.initialKind;
      _selectedProduct = widget.initialProduct;
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

    _loadPlanData();
  }

  Future<void> _loadPlanData() async {
    try {
      final data = await SubscriptionService.fetchMerchantDashboard();
      if (!mounted) return;
      setState(() {
        _planFeatures =
            (data['plan_features'] as Map?)?.cast<String, dynamic>() ?? const {};
        _adInventory =
            (data['ad_inventory'] as Map?)?.cast<String, dynamic>() ?? const {};
        if (_kind == 'advertising' &&
            _maxImpressionsController.text.trim().isEmpty) {
          final limit = _adInventory['ad_max_impressions'] ??
              _planFeatures['ad_max_impressions'];
          if (limit != null) {
            _maxImpressionsController.text = '$limit';
          }
        }
      });
    } catch (_) {
      // Best effort only.
    }
  }

  int? get _planImpressionLimit {
    final key = _kind == 'advertising'
        ? 'ad_max_impressions'
        : 'promotion_max_impressions';
    final raw = _adInventory[key] ?? _planFeatures[key];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  @override
  void dispose() {
    _newPriceController.dispose();
    _discountPercentageController.dispose();
    _maxImpressionsController.dispose();
    _priorityBoostController.dispose();
    _targetWilayasController.dispose();
    _targetUsersController.dispose();
    super.dispose();
  }

  Future<void> _openProductPicker() async {
    if (_isEditMode) return;
    final provider = context.read<PostProvider>();
    final picked = await showProductPickerBottomSheet(
      context,
      products: provider.myPosts,
      title: _productSelectionTitle,
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

    // Check if product already has an offer of the selected kind.
    final existingOffer = provider.myOffers
        .where((o) => o.product.id == post.id && o.kind == _kind)
        .firstOrNull;

    if (existingOffer != null) {
      _showExistingPromotionDialog(post, existingOffer);
    } else {
      setState(() {
        _selectedProduct = post;
        _existingOffer = null;
        _isEditMode = false;
        if (!_isAdMode) {
          _newPriceController.clear();
          _discountPercentageController.clear();
        }
      });
    }
  }

  Offer? _promotionForSelectedProduct(PostProvider provider) {
    final productId = _selectedProduct?.id;
    if (productId == null) return null;
    return provider.myOffers
        .where((offer) =>
            offer.product.id == productId && offer.kind == 'promotion')
        .firstOrNull;
  }

  int _resolvePercentage(Offer? selectedPromotion) {
    if (_isAdMode) {
      return selectedPromotion?.discountPercentage ??
          int.tryParse(_discountPercentageController.text) ??
          0;
    }
    return int.parse(_discountPercentageController.text);
  }

  String? _validateAdImpressionLimit(int? maxImpressions) {
    final planLimit = _planImpressionLimit;
    if (!_isAdMode || planLimit == null) {
      return null;
    }
    if ((maxImpressions ?? 0) <= 0) {
      return 'Please enter the number of ad impressions';
    }
    if (maxImpressions! > planLimit) {
      return 'Your plan allows up to $planLimit impressions for one ad';
    }
    return null;
  }

  void _showExistingPromotionDialog(Post post, Offer offer) {
    final isAdvertising = offer.kind == 'advertising';
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
              Expanded(
                child: Text(
                  isAdvertising ? 'Existing Sponsored Ad' : 'Existing Discount',
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
              Text(
                isAdvertising
                    ? 'This product already has an ad campaign. Do you want to edit it?'
                    : 'This product already has a discount. Do you want to edit it?',
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
                  _kind = offer.kind;
                  _placement = offer.placement;
                  _audienceMode = offer.audienceMode;
                  _discountPercentageController.text =
                      offer.discountPercentage.toString();
                  _newPriceController.text = offer.newPrice.toStringAsFixed(2);
                  _maxImpressionsController.text =
                      offer.maxImpressions?.toString() ?? '';
                  _priorityBoostController.text = offer.priorityBoost.toString();
                  _targetWilayasController.text = offer.targetWilayas.join(', ');
                  _targetUsersController.text = offer.targetUserIds.join(', ');
                });
              },
              text: isAdvertising ? 'Edit Sponsored Ad' : 'Edit Discount',
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
          title: Text(_deleteTitle),
          content: Text(_deleteDescription),
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
        Helpers.showSnackBar(context, _deleteSuccessMessage);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, '$_deleteFailurePrefix: $e');
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 7));
        }
      } else {
        _endDate = picked;
      }
    });
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
      final provider = Provider.of<PostProvider>(context, listen: false);
      final selectedPromotion = _promotionForSelectedProduct(provider);
      final percentage = _resolvePercentage(selectedPromotion);
      final maxImpressions =
          int.tryParse(_maxImpressionsController.text.trim());
      final priorityBoost =
          int.tryParse(_priorityBoostController.text.trim());
      final targetWilayas = _targetWilayasController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final targetUsers = _targetUsersController.text
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
      final impressionValidationError = _validateAdImpressionLimit(maxImpressions);
      if (impressionValidationError != null) {
        Helpers.showSnackBar(context, impressionValidationError);
        return;
      }

      if (_isEditMode && _existingOffer != null) {
        // Update existing offer
        await provider.updateOffer(
          offerId: _existingOffer!.id,
          discountPercentage: percentage,
          isAvailable: _isAvailable,
          kind: _kind,
          placement: _placement,
          audienceMode: _audienceMode,
          targetWilayas: targetWilayas,
          targetUserIds: targetUsers,
          priorityBoost: priorityBoost,
          maxImpressions: maxImpressions,
          startDate: _startDate,
          endDate: _endDate,
        );

        if (mounted) {
          Helpers.showSnackBar(context, _saveSuccessMessage);
          Navigator.pop(context, true);
        }
      } else {
        // Create new offer
        await provider.createOffer(
          productId: _selectedProduct!.id,
          discountPercentage: percentage,
          isAvailable: _isAvailable,
          kind: _kind,
          placement: _placement,
          audienceMode: _audienceMode,
          targetWilayas: targetWilayas,
          targetUserIds: targetUsers,
          priorityBoost: priorityBoost,
          maxImpressions: maxImpressions,
          startDate: _startDate,
          endDate: _endDate,
        );

        if (mounted) {
          Helpers.showSnackBar(context, _createSuccessMessage);
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
          context,
          'Failed to ${_isEditMode ? 'save' : 'create'} ${_isAdMode ? 'sponsored ad' : 'discount'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final selectedPromotion = _promotionForSelectedProduct(provider);
    final planImpressionLimit = _planImpressionLimit;
    final impressionPresets = planImpressionLimit == null
      ? <int>[]
      : <int>{
        (planImpressionLimit * 0.25).round(),
        (planImpressionLimit * 0.5).round(),
        (planImpressionLimit * 0.75).round(),
        planImpressionLimit,
        }.where((value) => value > 0).toList(growable: true)
      ..sort();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_screenTitle),
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
                Text(
                  _productSelectionTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                        if (loadingProgress == null) {
                                          return child;
                                        }
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
                            _selectedProduct?.title ?? _productSelectionHint,
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

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAdMode ? 'Sponsored Product Summary' : 'Current Price',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_isAdMode ? 'Product Price:' : 'Original Price:'),
                            Text(
                              Helpers.formatPrice(_selectedProduct!.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (_isAdMode && selectedPromotion != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Linked Promotion:'),
                              Text(
                                '-${selectedPromotion.discountPercentage}% • ${Helpers.formatPrice(selectedPromotion.newPrice)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'This sponsored ad will boost your existing promotion for this product.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ] else if (_isAdMode) ...[
                          const SizedBox(height: 10),
                          Text(
                            'No promotion is linked to this product. This sponsored ad will promote the product without discount fields.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ] else ...[
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_isAdMode) ...[
                    AppTextField(
                      controller: _discountPercentageController,
                      label: 'Discount Percentage (%)',
                      hint: '0',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                      suffixText: '%',
                      onChanged: _onPercentageChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final n = double.tryParse(value);
                        if (n == null || n <= 0 || n >= 100) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _newPriceController,
                      label: 'New Price',
                      hint: '0',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      suffixText: 'DZD',
                      onChanged: _onNewPriceChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final n = double.tryParse(value);
                        final original = _selectedProduct!.price;
                        if (n == null || n <= 0 || n >= original) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sponsored Ad'),
                      subtitle: const Text('Boost this product in recommendations'),
                      value: _isAdMode,
                      onChanged: _isLoading || _isAdOnlyFlow
                          ? null
                          : (value) {
                              setState(() {
                                _kind = value ? 'advertising' : 'promotion';
                                _existingOffer = (_selectedProduct == null)
                                    ? null
                                    : context
                                        .read<PostProvider>()
                                        .myOffers
                                        .where((offer) =>
                                            offer.product.id ==
                                                _selectedProduct!.id &&
                                            offer.kind == _kind)
                                        .firstOrNull;
                                if (_isAdMode &&
                                    _maxImpressionsController.text.trim().isEmpty &&
                                    planImpressionLimit != null) {
                                  _maxImpressionsController.text =
                                      '$planImpressionLimit';
                                }
                              });
                            },
                    ),
                  ],

                  if (_isAdMode) ...[
                    const SizedBox(height: 8),
                    if (planImpressionLimit != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD8A8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan sponsored-ad limit: $planImpressionLimit impressions',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Remaining ad slots: ${_adInventory['remaining_ad_slots'] ?? '-'}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      value: _placement,
                      decoration: const InputDecoration(
                        labelText: 'Placement',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'home_top', child: Text('Home Top')),
                        DropdownMenuItem(
                            value: 'home_feed', child: Text('Home Feed')),
                        DropdownMenuItem(
                            value: 'search_top', child: Text('Search Top')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _placement = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _audienceMode,
                      decoration: const InputDecoration(
                        labelText: 'Audience',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                            value: 'followers', child: Text('Followers')),
                        DropdownMenuItem(
                            value: 'nearby', child: Text('Nearby')),
                        DropdownMenuItem(
                            value: 'wilaya', child: Text('Wilaya')),
                        DropdownMenuItem(
                            value: 'custom', child: Text('Custom Users')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _audienceMode = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _maxImpressionsController,
                      label: 'Ad Max Impressions',
                      hint: planImpressionLimit != null
                          ? 'Up to $planImpressionLimit'
                          : 'e.g. 5000',
                      icon: Icons.visibility_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    if (impressionPresets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: impressionPresets.map((value) {
                          return ActionChip(
                            label: Text('$value impressions'),
                            onPressed: () {
                              setState(() {
                                _maxImpressionsController.text = '$value';
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _priorityBoostController,
                      label: 'Sponsored Priority Boost',
                      hint: '0',
                      icon: Icons.trending_up,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _targetWilayasController,
                      label: 'Sponsored Target Wilayas',
                      hint: 'e.g. 16, 09, 31',
                      icon: Icons.map_outlined,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _targetUsersController,
                      label: 'Sponsored Target Users (IDs)',
                      hint: 'e.g. 12, 55, 103',
                      icon: Icons.person_pin_circle_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _pickDate(isStart: true),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(_startDate == null
                                ? 'Start Date'
                                : _startDate!.toIso8601String().split('T')[0]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _pickDate(isStart: false),
                            icon: const Icon(Icons.event_outlined),
                            label: Text(_endDate == null
                                ? 'End Date'
                                : _endDate!.toIso8601String().split('T')[0]),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_availabilityTitle),
                    subtitle: Text(_availabilitySubtitle),
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
                      text: _submitButtonText,
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
