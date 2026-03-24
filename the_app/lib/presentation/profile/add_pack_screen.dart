import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/pack_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/store_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../common/location_filter_picker.dart';
import '../subscription/subscription_gate.dart';
import 'widgets/product_picker_sheet.dart';

class AddPackScreen extends StatefulWidget {
  final Pack? pack;

  const AddPackScreen({super.key, this.pack});

  @override
  State<AddPackScreen> createState() => _AddPackScreenState();
}

class _AddPackScreenState extends State<AddPackScreen> {
  final TextEditingController _packNameController = TextEditingController();
  final TextEditingController _packPriceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  double _enteredPackPrice = 0.0;
  String? _formError;
  bool _isAvailable = true;

  // Delivery state
  bool _deliveryAvailable = false;
  LocationFilterResult? _deliveryAreas;

  bool get _isEditMode => widget.pack != null;

  Future<void> _initAfterFirstFrame() async {
    // Clear on next frame to avoid notifyListeners during build.
    final packProvider = context.read<PackProvider>();
    packProvider.clear();

    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id.toString();
    if (userId != null) {
      await context.read<PostProvider>().loadMyPosts(userId);
    }

    final existingPack = widget.pack;
    if (existingPack == null) return;

    _packNameController.text = existingPack.name;
    _packPriceController.text = existingPack.discountPrice.toStringAsFixed(2);
    _enteredPackPrice = existingPack.discountPrice;
    _isAvailable = existingPack.isAvailable;
    // Restore delivery state
    _deliveryAvailable = existingPack.deliveryAvailable;
    if (existingPack.deliveryWilayas.isNotEmpty) {
      _deliveryAreas = LocationFilterResult(
        selectedWilayas: existingPack.deliveryWilayas,
        selectedBaladiyat: const {},
      );
    }

    final postProvider = context.read<PostProvider>();

    for (final pp in existingPack.products) {
      final match = postProvider.myPosts.where((p) => p.id == pp.productId);
      final Post post;
      if (match.isNotEmpty) {
        post = match.first;
      } else {
        // Fallback: create a lightweight Post so the table can still render.
        var imageUrl = pp.productImage;
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          if (imageUrl.startsWith('/media/')) {
            imageUrl = '${ApiConfig.baseUrl}$imageUrl';
          } else {
            imageUrl = ApiConfig.getImageUrl(imageUrl);
          }
        }

        post = Post(
          id: pp.productId,
          title: pp.productName,
          description: '',
          category: 'Uncategorized',
          categoryId: null,
          storeId: existingPack.merchantId,
          storeName: existingPack.merchantName,
          author: User(
            id: existingPack.merchantId,
            username: existingPack.merchantName,
            email: '',
            name: existingPack.merchantName,
            dateJoined: DateTime.now(),
          ),
          price: pp.productPrice,
          oldPrice: null,
          discountPercentage: null,
          isAvailable: true,
          isNegotiable: false,
          hidePrice: false,
          rating: 0.0,
          reviewCount: 0,
          isFavorited: false,
          isHotDeal: false,
          isFeatured: false,
          createdAt: DateTime.now(),
          images: imageUrl.isNotEmpty
              ? [ProductImageData(id: 0, url: imageUrl, isMain: true)]
              : const [],
        );
      }

      if (packProvider.selectedProducts.any((p) => p.id == post.id)) continue;
      final index = packProvider.selectedProducts.length;
      packProvider.addProduct(post);
      packProvider.setQuantity(post, pp.quantity);
      _listKey.currentState?.insertItem(index);
    }

    if (mounted) setState(() {});
  }

  Widget _safeThumb(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const SizedBox(
            width: 16,
            height: 16,
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAfterFirstFrame();
    });

    _packPriceController.addListener(() {
      setState(() {
        _enteredPackPrice = double.tryParse(_packPriceController.text) ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _packNameController.dispose();
    _searchController.dispose();
    _packPriceController.dispose();
    super.dispose();
  }

  void _addProductToPack(Post product) {
    final provider = context.read<PackProvider>();
    if (provider.selectedProducts.any((p) => p.id == product.id)) {
      Helpers.showSnackBar(
        context,
        context.tr('This product already exists in the pack'),
        isError: true,
      );
      return;
    }
    HapticFeedback.lightImpact();
    final index = provider.selectedProducts.length;
    provider.addProduct(product);
    _listKey.currentState?.insertItem(index);
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _openProductPicker() async {
    final provider = context.read<PostProvider>();
    final picked = await showProductPickerBottomSheet(
      context,
      products: provider.myPosts,
      title: context.tr('Select Product'),
    );
    if (picked != null) _addProductToPack(picked);
  }

  void _removeProductFromPack(Post product, int index) {
    final provider = context.read<PackProvider>();
    HapticFeedback.mediumImpact();
    final qty = provider.quantities[product.id] ?? 1;

    provider.removeProduct(product);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildTableRow(product, animation, quantityOverride: qty),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onQuantityChange(Post product, int qty) {
    final provider = context.read<PackProvider>();
    provider.setQuantity(product, qty);
  }

  Future<void> _submit() async {
    final provider = context.read<PackProvider>();
    setState(() => _formError = null);
    if (!_hasProfileLocation()) {
      setState(() => _formError = context
          .tr('Set your location area or GPS in Edit Profile before posting.'));
      return;
    }
    if (provider.selectedProducts.isEmpty) {
      setState(() => _formError = context.tr('Select pack products first'));
      return;
    }
    if (_packNameController.text.trim().isEmpty) {
      setState(() => _formError = context.tr('Enter pack name'));
      return;
    }
    if (_packPriceController.text.isEmpty ||
        double.tryParse(_packPriceController.text) == null) {
      setState(() => _formError = context.tr('Enter pack sale price'));
      return;
    }
    final enteredPrice = double.tryParse(_packPriceController.text) ?? 0.0;
    if (enteredPrice >= provider.totalPrice) {
      setState(() => _formError = context
          .tr('Pack price must be less than the total price of products'));
      return;
    }
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;

    if (userId == null) {
      setState(() => _formError = context.tr('Must login first'));
      return;
    }

    try {
      // Get Store ID
      final storeProvider = context.read<StoreProvider>();
      final store = await storeProvider.getMyStore(userId);

      if (store == null) {
        setState(() => _formError = context.tr('No store found for this user'));
        return;
      }

      // Compute delivery wilayas (empty = backend falls back to merchant.address)
      final List<String> deliveryWilayas =
          _deliveryAvailable ? (_deliveryAreas?.selectedWilayas ?? []) : [];

      if (_isEditMode) {
        await provider.updatePack(
          id: widget.pack!.id,
          name: _packNameController.text.trim(),
          description: widget.pack!.description,
          discountPrice: enteredPrice,
          isAvailable: _isAvailable,
          merchantId: store.id,
          deliveryAvailable: _deliveryAvailable,
          deliveryWilayas: deliveryWilayas,
        );

        if (mounted) {
          Helpers.showSnackBar(
              context, context.tr('Pack updated successfully'));
          Navigator.pop(context, true);
        }
      } else {
        await provider.submitPack(
          name: _packNameController.text.trim(),
          description: 'Pack published from app',
          discountPrice: enteredPrice,
          merchantId: store.id,
          isAvailable: _isAvailable,
          deliveryAvailable: _deliveryAvailable,
          deliveryWilayas: deliveryWilayas,
        );
        if (mounted) {
          await context.read<WalletProvider>().fetchWallet();
          Helpers.showSnackBar(
              context, context.tr('Pack published successfully'));
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
        setState(() => _formError =
            '${context.tr('Error during publishing')}: ${provider.error ?? e.toString()}');
      }
    }
  }

  Widget _buildSelectedProductsTable() {
    return Consumer<PackProvider>(
      builder: (context, provider, child) {
        final selected = provider.selectedProducts;
        return Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(context.tr('Product'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      flex: 2,
                      child: Text(context.tr('Quantity'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 2,
                      child: Text(context.tr('Total'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end)),
                ],
              ),
            ),
            // Table Body
            Expanded(
              child: Stack(
                children: [
                  AnimatedList(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: _listKey,
                    initialItemCount: selected.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= selected.length) {
                        return const SizedBox.shrink();
                      }
                      return _buildTableRow(selected[index], animation);
                    },
                  ),
                  if (selected.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_basket_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            context.tr(
                                'You haven\'t added any products to the pack yet'),
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            context.tr('Use the search above to add products'),
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableRow(Post product, Animation<double> animation,
      {int? quantityOverride}) {
    return SizeTransition(
      sizeFactor: animation,
      child: Consumer<PackProvider>(builder: (context, provider, _) {
        final qty = quantityOverride ?? provider.quantities[product.id] ?? 1;
        final total = product.price * qty;

        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Product Info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () {
                        final index =
                            provider.selectedProducts.indexOf(product);
                        if (index != -1) _removeProductFromPack(product, index);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 40,
                        height: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: _safeThumb(product.image),
                        )),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${product.price} ${context.tr('DZD')}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        if (qty > 1) _onQuantityChange(product, qty - 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('$qty',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    InkWell(
                      onTap: () => _onQuantityChange(product, qty + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              // Total
              Expanded(
                flex: 2,
                child: Text(
                  '${total.toStringAsFixed(0)} ${context.tr('DZD')}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummarySection() {
    return Consumer<PackProvider>(
      builder: (context, provider, _) {
        final totalPrice = provider.totalPrice;
        final diff = totalPrice - _enteredPackPrice;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: _packNameController,
                    label: context.tr('Pack Name *'),
                    hint: context.tr('Enter pack name'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('Total Product Prices:'),
                          style: TextStyle(color: Colors.grey)),
                      Text(
                          '${totalPrice.toStringAsFixed(2)} ${context.tr('DZD')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _packPriceController,
                          label: context.tr('Pack Sale Price'),
                          hint: '0',
                          keyboardType: TextInputType.number,
                          suffixText: context.tr('DZD'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(context.tr('Savings'),
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(
                            '${diff > 0 ? diff.toStringAsFixed(2) : "0.00"} ${context.tr('DZD')}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('Available')),
                    subtitle: Text(context
                        .tr('Show this pack to customers in your store')),
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() => _isAvailable = value);
                    },
                  ),
                  const SizedBox(height: 4),
                  // ─── Delivery Section ─────────────────────────────────────
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('Delivery Available')),
                    subtitle:
                        Text(context.tr('Enable home delivery for this pack')),
                    value: _deliveryAvailable,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setState(() => _deliveryAvailable = value);
                    },
                  ),
                  if (_deliveryAvailable)
                    ...([
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text(
                          _deliveryAreas != null &&
                                  _deliveryAreas!.selectedWilayas.isNotEmpty
                              ? '${context.tr('Delivery areas')}: ${_deliveryAreas!.displayTextFor(context)}'
                              : context.tr('Select delivery areas (optional)'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () async {
                          final result =
                              await Navigator.push<LocationFilterResult>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationFilterPicker(
                                initialFilter: _deliveryAreas,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() => _deliveryAreas = result);
                          }
                        },
                      ),
                      if (_deliveryAreas == null ||
                          _deliveryAreas!.selectedWilayas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            context.tr(
                                'No areas selected — your store address will be used by default'),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                    ]),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    text: provider.isSubmitting
                        ? (_isEditMode
                            ? context.tr('Saving...')
                            : context.tr('Publishing...'))
                        : (_isEditMode
                            ? context.tr('Save Changes')
                            : context.tr('Publish Pack')),
                    onPressed: _submit,
                    isLoading: provider.isSubmitting,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Create New Pack')),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPanelHeight =
                (constraints.maxHeight * 0.38).clamp(260.0, 380.0);

            return Column(
              children: [
                // Product picker field
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: InkWell(
                    onTap: _openProductPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      child: AppSearchField(
                        controller: _searchController,
                        hintText: context.tr('Select product to add...'),
                        compact: false,
                        showClearButton: false,
                      ),
                    ),
                  ),
                ),

                // Give table most of the height
                Expanded(
                  child: _buildSelectedProductsTable(),
                ),

                // Bottom panel stays fixed height; content inside is scrollable
                SizedBox(
                  height: bottomPanelHeight,
                  child: _buildSummarySection(),
                ),
              ],
            );
          },
        ),
      ),
    );
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
}
