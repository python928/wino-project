import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/pack_provider.dart';
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
  final TextEditingController _packPriceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Post> _filteredProducts = [];
  final GlobalKey<AnimatedListState> _selectedListKey = GlobalKey<AnimatedListState>();
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
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    // deprecated: we now use PostProvider.onSearchQueryChanged (debounced)
  }

  void _addProductToPack(Post product) {
    final provider = context.read<PackProvider>();
    if (provider.selectedProducts.any((p) => p.id == product.id)) {
      Helpers.showSnackBar(context, 'هذا المنتج موجود مسبقاً في الحزمة');
      return;
    }
    HapticFeedback.lightImpact();
    final index = provider.selectedProducts.length;
    provider.addProduct(product);
    _selectedListKey.currentState?.insertItem(index, duration: const Duration(milliseconds: 300));
  }

  void _removeProductFromPack(Post product) {
    final provider = context.read<PackProvider>();
    HapticFeedback.mediumImpact();
    final index = provider.selectedProducts.indexWhere((p) => p.id == product.id);
    if (index == -1) return;
    provider.removeProduct(product);
    _selectedListKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildSelectedItem(product),
      ),
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
      setState(() => _formError = 'اختر منتجات الحزمة أولاً');
      return;
    }
    if (_packPriceController.text.isEmpty || double.tryParse(_packPriceController.text) == null) {
      setState(() => _formError = 'أدخل سعر بيع الحزمة');
      return;
    }
    final enteredPrice = double.tryParse(_packPriceController.text) ?? 0.0;
    if (enteredPrice >= provider.totalPrice) {
      setState(() => _formError = 'سعر الحزمة يجب أن يكون أقل من مجموع أسعار المنتجات');
      return;
    }
    final auth = context.read<AuthProvider>();
    final merchantId = auth.user?.id ?? 0;
    try {
      await provider.submitPack(
        name: 'حزمة جديدة',
        description: 'حزمة منشورة من التطبيق',
        discountPrice: enteredPrice,
        merchantId: merchantId,
      );
      if (mounted) {
        Helpers.showSnackBar(context, 'تم نشر الحزمة بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _formError = 'حدث خطأ أثناء النشر: ${provider.error ?? e.toString()}');
    }
  }

  Widget _buildSelectedItem(Post product) {
    final packProvider = context.read<PackProvider>();
    final qty = packProvider.quantities[product.id] ?? 1;
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.goldGradient,
        boxShadow: AppColors.goldShadow,
        border: Border.all(color: AppColors.borderGold.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: product.gallery.isNotEmpty ? _safeThumb(product.gallery.first) : _safeThumb(null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () {
                  final current = packProvider.quantities[product.id] ?? 1;
                  if (current > 1) {
                    HapticFeedback.selectionClick();
                    _onQuantityChange(product, current - 1);
                  }
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text('$qty', key: ValueKey(qty)),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _onQuantityChange(product, (packProvider.quantities[product.id] ?? 1) + 1);
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            onPressed: () {
              HapticFeedback.heavyImpact();
              _removeProductFromPack(product);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نشر حزمة جديدة'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
            Expanded(
              child: Consumer<PostProvider>(
                builder: (context, postProvider, child) {
                  final products = postProvider.myPosts;
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Dismissible(
                        key: Key(product.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _addProductToPack(product),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.primary,
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        child: ListTile(
                          leading: SizedBox(width: 50, height: 50, child: product.gallery.isNotEmpty ? _safeThumb(product.gallery.first) : _safeThumb(null)),
                          title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${product.price.toStringAsFixed(2)} د.ج'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _addProductToPack(product),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<PackProvider>(
              builder: (context, packProvider, child) {
                final selected = packProvider.selectedProducts;
                if (selected.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('المنتجات المختارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: AnimatedList(
                          key: _selectedListKey,
                          scrollDirection: Axis.horizontal,
                          initialItemCount: selected.length,
                          itemBuilder: (context, index, animation) {
                            final product = selected[index];
                            return SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.horizontal,
                              child: _buildSelectedItem(product),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إجمالي السعر: ${packProvider.totalPrice.toStringAsFixed(2)} د.ج',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (_enteredPackPrice > 0)
                                Text(
                                  'الفرق: ${(packProvider.totalPrice - _enteredPackPrice).toStringAsFixed(2)} د.ج',
                                  style: TextStyle(
                                    color: (packProvider.totalPrice - _enteredPackPrice) >= 0 ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _packPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'سعر الحزمة',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.amber[50],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_formError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _formError!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: PremiumUIComponents.luxuryGoldButton(
                          text: packProvider.isSubmitting ? 'جاري النشر...' : 'نشر الحزمة',
                          onPressed: packProvider.isSubmitting ? () {} : () => _submit(),
                          isLoading: packProvider.isSubmitting,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
