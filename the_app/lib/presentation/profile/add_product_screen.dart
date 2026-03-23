import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/category_model.dart';
import '../../data/models/post_model.dart';
import '../common/location_filter_picker.dart';
import '../search/category_selection_screen.dart';
import '../subscription/subscription_gate.dart';

class AddProductScreen extends StatefulWidget {
  final Post? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<dynamic> _images = [];
  final List<int> _removedExistingImageIds = [];
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isAvailable = true;
  bool _showPrice = true;

  // Category selection state (single category only)
  Set<int> _selectedCategoryIds = {};
  List<Category> _categories = [];
  bool _loadingCategories = true;

  // Delivery state
  bool _deliveryAvailable = false;
  LocationFilterResult? _deliveryAreas;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    final product = widget.product;
    if (product != null) {
      _titleController.text = product.title;
      _priceController.text = product.price.toString();
      _descriptionController.text = product.description;
      if (product.categoryId != null) {
        _selectedCategoryIds = {product.categoryId!};
      }
      _isAvailable = product.isAvailable;
      _showPrice = !product.hidePrice;
      _images.addAll(product.images);
      // Restore delivery state
      _deliveryAvailable = product.deliveryAvailable;
      if (product.deliveryWilayas.isNotEmpty) {
        _deliveryAreas = LocationFilterResult(
          selectedWilayas: product.deliveryWilayas,
          selectedBaladiyat: const {},
        );
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.categories);
      final list = response is List ? response : (response['results'] ?? []);
      final cats = (list as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _openCategoryPicker() async {
    if (_loadingCategories) {
      Helpers.showSnackBar(context, 'Loading categories, please wait...');
      return;
    }
    if (_categories.isEmpty) {
      Helpers.showSnackBar(context, 'No categories available');
      return;
    }

    final result = await Navigator.push<Set<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionScreen(
          categories: _categories,
          initialSelectedCategoryIds: _selectedCategoryIds,
          singleSelection: true,
        ),
      ),
    );

    if (result != null) {
      _setSelectedCategoryIds(result);
    }
  }

  void _setSelectedCategoryIds(Set<int> ids) {
    final selectedId = ids.isEmpty ? null : ids.first;
    setState(() {
      _selectedCategoryIds = selectedId == null ? {} : {selectedId};
    });
  }

  Widget _buildImage(dynamic image) {
    if (image is ProductImageData) {
      return Image.network(
        image.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
    if (image is XFile) {
      return FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    if (image is String) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  Future<void> _confirmDeleteProduct() async {
    final product = widget.product;
    if (product == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: Text(context.tr('Delete Product?')),
          content: Text(context.tr('This action cannot be undone.')),
          actions: [
            AppTextButton(
              onPressed: () => Navigator.pop(context, false),
              text: context.tr('Cancel'),
            ),
            AppPrimaryButton(
              onPressed: () => Navigator.pop(context, true),
              text: context.tr('Delete'),
            ),
          ],
        ),
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isLoading = true);
    try {
      await context.read<PostProvider>().deletePost(product.id);
      if (mounted) {
        Helpers.showSnackBar(context, 'Product deleted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to delete product: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() {
          final remainingSlots = 5 - _images.length;
          _images.addAll(picked.take(remainingSlots));
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Error selecting images', isError: true);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasProfileLocation()) {
      Helpers.showSnackBar(
        context,
        'Set your location area or GPS in Edit Profile before posting.',
        isError: true,
      );
      return;
    }
    if (_images.isEmpty) {
      Helpers.showSnackBar(context, 'Please add at least one image');
      return;
    }
    if (_selectedCategoryIds.isEmpty) {
      Helpers.showSnackBar(context, 'Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    // Resolve selected category name
    final selectedId =
        _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.first;
    final selectedNames = selectedId == null
        ? <String>[]
        : [
            () {
              try {
                return _categories.firstWhere((c) => c.id == selectedId).name;
              } catch (_) {
                return '';
              }
            }()
          ].where((n) => n.isNotEmpty).toList();
    final primaryCategoryName =
        selectedNames.isNotEmpty ? selectedNames.first : '';

    try {
      final provider = Provider.of<PostProvider>(context, listen: false);
      final double price = double.parse(
        _priceController.text.isEmpty ? '0' : _priceController.text,
      ).toDouble();

      // Compute effective delivery wilayas (empty = use store.address fallback on backend)
      final List<String> deliveryWilayas =
          _deliveryAvailable ? (_deliveryAreas?.selectedWilayas ?? []) : [];

      if (_isEditMode) {
        final newFiles = _images.whereType<XFile>().toList();
        await provider.updateProduct(
          id: widget.product!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          category: primaryCategoryName,
          isAvailable: _isAvailable,
          hidePrice: !_showPrice,
          newImages: newFiles,
          removeImageIds: _removedExistingImageIds,
          deliveryAvailable: _deliveryAvailable,
          deliveryWilayas: deliveryWilayas,
        );

        if (mounted) {
          Helpers.showSnackBar(context, 'Product updated successfully');
          Navigator.pop(context, true);
        }
      } else {
        await provider.addProduct(
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          category: primaryCategoryName,
          images: _images.whereType<XFile>().toList(),
          isAvailable: _isAvailable,
          isNegotiable: false,
          hidePrice: !_showPrice,
          deliveryAvailable: _deliveryAvailable,
          deliveryWilayas: deliveryWilayas,
        );

        if (mounted) {
          await context.read<WalletProvider>().fetchWallet();
          Helpers.showSnackBar(context, 'Product published successfully');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        final coinInfo = SubscriptionService.parseCoinBalanceError(e);
        if (coinInfo != null) {
          await openCoinStore(
            context,
            required: coinInfo['required'] as int?,
            balance: coinInfo['balance'] as int?,
          );
          return;
        }
        Helpers.showSnackBar(
          context,
          'Failed to ${_isEditMode ? 'update' : 'publish'} product: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _hasProfileLocation() {
    final userData = StorageService.getUserData();
    final address =
        (userData?['address'] ?? userData?['location'] ?? '').toString().trim();
    final latRaw = userData?['latitude'];
    final lngRaw = userData?['longitude'];
    final lat = double.tryParse(latRaw?.toString() ?? '');
    final lng = double.tryParse(lngRaw?.toString() ?? '');
    final hasGps = lat != null && lng != null;
    return address.isNotEmpty || hasGps;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _isEditMode
                ? context.tr('Edit Product')
                : context.tr('Publish New Product'),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isEditMode)
              IconButton(
                onPressed: _isLoading ? null : _confirmDeleteProduct,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      const Text(
                        'Product Images',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildImagePicker(),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'You can add up to 5 product images',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Product Name
                      AppTextField(
                        controller: _titleController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        icon: Icons.inventory_2_outlined,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter product name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Opacity(
                        opacity: _showPrice ? 1.0 : 0.6,
                        child: IgnorePointer(
                          ignoring: !_showPrice,
                          child: AppTextField(
                            controller: _priceController,
                            label: 'Price',
                            hint: '0',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            suffixText: 'DZD',
                            validator: (value) {
                              if (!_showPrice) return null;
                              if (value == null || value.isEmpty) {
                                return 'Please enter price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category — tappable field
                      _buildCategoryField(),
                      const SizedBox(height: 16),

                      // Description
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Add product description..',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('Show Price')),
                        subtitle: const Text(
                          'Show price to customers in listings',
                        ),
                        value: _showPrice,
                        onChanged: (value) {
                          setState(() => _showPrice = value);
                        },
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('Available')),
                        subtitle: const Text(
                          'Is the product available for sale?',
                        ),
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() => _isAvailable = value);
                        },
                      ),

                      const SizedBox(height: 8),
                      _buildDeliverySection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    text: _isLoading
                        ? (_isEditMode ? 'Saving...' : 'Publishing...')
                        : (_isEditMode ? 'Save Changes' : 'Publish Product'),
                    icon: Icons.add,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delivery section
  // ---------------------------------------------------------------------------
  void _openDeliveryAreaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationFilterPicker(initialFilter: _deliveryAreas),
    ).then((result) {
      if (result != null && result is LocationFilterResult) {
        setState(() => _deliveryAreas = result);
      }
    });
  }

  Widget _buildDeliverySection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _deliveryAvailable
            ? const Color(0xFFF0EEFF)
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _deliveryAvailable
              ? AppColors.primaryColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Toggle row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _deliveryAvailable
                        ? AppColors.primaryColor.withOpacity(0.12)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: _deliveryAvailable
                        ? AppColors.primaryColor
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Delivery Available'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _deliveryAvailable
                            ? context.tr('Select areas you deliver to')
                            : context.tr('Customers can come pick up'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _deliveryAvailable,
                  onChanged: (v) => setState(() => _deliveryAvailable = v),
                  activeColor: AppColors.primaryColor,
                ),
              ],
            ),
          ),

          // Delivery areas (only when enabled)
          if (_deliveryAvailable) ...[
            Divider(height: 1, color: AppColors.primaryColor.withOpacity(0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _deliveryAreas == null || !_deliveryAreas!.hasFilters
                            ? context.tr('No areas selected')
                            : _deliveryAreas!.displayTextFor(context),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _deliveryAreas?.hasFilters == true
                              ? AppColors.textPrimary
                              : Colors.grey.shade500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openDeliveryAreaPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _deliveryAreas?.hasFilters == true
                                    ? Icons.edit_rounded
                                    : Icons.add_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _deliveryAreas?.hasFilters == true
                                    ? context.tr('Edit')
                                    : context.tr('Add Areas'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Chips display
                  if (_deliveryAreas?.hasFilters == true) ...[
                    const SizedBox(height: 10),
                    LocationChipsWidget(
                      filter: _deliveryAreas!,
                      onEdit: _openDeliveryAreaPicker,
                      maxVisible: 5,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    final bool hasCategories = _selectedCategoryIds.isNotEmpty;

    // Resolve names for display
    final selectedNames = _selectedCategoryIds
        .map((id) {
          try {
            return _categories.firstWhere((c) => c.id == id).name;
          } catch (_) {
            return '';
          }
        })
        .where((n) => n.isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: _openCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasCategories ? AppColors.primaryColor : Colors.grey[300]!,
            width: hasCategories ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 20,
              color: hasCategories ? AppColors.primaryColor : Colors.grey[500],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _loadingCategories
                  ? Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading categories...',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : hasCategories
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: selectedNames.map((name) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      AppColors.primaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Text(
                          'Select category',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 32,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 8),
              Text(
                'Add Images',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to upload',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImages,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _buildImage(_images.first),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_images.length}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + (_images.length < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 86,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 24, color: Colors.grey[500]),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  Container(
                    width: 86,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: index == 0
                            ? AppColors.primaryColor.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 86,
                        height: 86,
                        child: _buildImage(_images[index]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImageAt(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _removeImageAt(int index) {
    final img = _images[index];
    setState(() {
      if (img is ProductImageData && img.id > 0) {
        _removedExistingImageIds.add(img.id);
      }
      _images.removeAt(index);
    });
  }
}
