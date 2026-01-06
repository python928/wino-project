import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/pack_provider.dart';
import '../../core/providers/store_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/premium_ui_components.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/post_model.dart';
import 'package:flutter/services.dart';

class AddPackScreen extends StatefulWidget {
  const AddPackScreen({super.key});

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
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id.toString();
      if (userId != null) {
        context.read<PostProvider>().loadMyPosts(userId);
      }
    });
    _searchController.addListener(() {
      setState(() {});
      final query = _searchController.text;
      context.read<PostProvider>().onSearchQueryChanged(query);
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
      Helpers.showSnackBar(context, 'This product already exists in the pack');
      return;
    }
    HapticFeedback.lightImpact();
    final index = provider.selectedProducts.length;
    provider.addProduct(product);
    _listKey.currentState?.insertItem(index);
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void _removeProductFromPack(Post product, int index) {
    final provider = context.read<PackProvider>();
    HapticFeedback.mediumImpact();
    final qty = provider.quantities[product.id] ?? 1;
    
    provider.removeProduct(product);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTableRow(product, animation, quantityOverride: qty),
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
    if (provider.selectedProducts.isEmpty) {
      setState(() => _formError = 'Select pack products first');
      return;
    }
    if (_packNameController.text.trim().isEmpty) {
      setState(() => _formError = 'Enter pack name');
      return;
    }
    if (_packPriceController.text.isEmpty || double.tryParse(_packPriceController.text) == null) {
      setState(() => _formError = 'Enter pack sale price');
      return;
    }
    final enteredPrice = double.tryParse(_packPriceController.text) ?? 0.0;
    if (enteredPrice >= provider.totalPrice) {
      setState(() => _formError = 'Pack price must be less than the total price of products');
      return;
    }
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    
    if (userId == null) {
       setState(() => _formError = 'Must login first');
       return;
    }

    try {
      // Get Store ID
      final storeProvider = context.read<StoreProvider>();
      final store = await storeProvider.getMyStore(userId);
      
      if (store == null) {
         setState(() => _formError = 'No store found for this user');
         return;
      }

      await provider.submitPack(
        name: _packNameController.text.trim(),
        description: 'Pack published from app',
        discountPrice: enteredPrice,
        merchantId: store.id,
      );
      if (mounted) {
        Helpers.showSnackBar(context, 'Pack published successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _formError = 'Error during publishing: ${provider.error ?? e.toString()}');
    }
  }

  Widget _buildSearchResults() {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        final products = postProvider.myPosts;
        if (products.isEmpty) {
           return const Center(child: Text('No results found'));
        }
        return SizedBox(
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: SizedBox(width: 50, height: 50, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: _safeThumb(product.image))),
                title: Text(product.title),
                subtitle: Text('${product.price} DZD'),
                trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                onTap: () => _addProductToPack(product),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSelectedProductsTable() {
    return Consumer<PackProvider>(
      builder: (context, provider, child) {
        final selected = provider.selectedProducts;
        if (selected.isEmpty) {
          return const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('You haven\'t added any products to the pack yet', style: TextStyle(color: Colors.grey)),
                  Text('Use the search above to add products', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return Expanded(
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[200],
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
                  ],
                ),
              ),
              // Table Body
              Expanded(
                child: AnimatedList(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  key: _listKey,
                  initialItemCount: selected.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= selected.length) return const SizedBox.shrink();
                    return _buildTableRow(selected[index], animation);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableRow(Post product, Animation<double> animation, {int? quantityOverride}) {
    return SizeTransition(
      sizeFactor: animation,
      child: Consumer<PackProvider>(
        builder: (context, provider, _) {
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
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () {
                           final index = provider.selectedProducts.indexOf(product);
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
                        )
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${product.price} DZD', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      InkWell(
                        onTap: () => _onQuantityChange(product, qty + 1),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
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
                    '${total.toStringAsFixed(0)} DZD',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }
      ),
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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _packNameController,
                  decoration: InputDecoration(
                    labelText: 'Pack Name *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Product Prices:', style: TextStyle(color: Colors.grey)),
                    Text('${totalPrice.toStringAsFixed(2)} DZD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _packPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Pack Sale Price',
                          suffixText: 'DZD',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Savings', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          '${diff > 0 ? diff.toStringAsFixed(2) : "0.00"} DZD',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: provider.isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Publish Pack', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Pack'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for product to add...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),

            // Content Area
            isSearching ? _buildSearchResults() : _buildSelectedProductsTable(),

            // Bottom Summary Section
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }
}
