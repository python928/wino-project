import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../shared_widgets/gradient_button.dart';
import '../../data/models/post_model.dart';

class EditPackScreen extends StatefulWidget {
  final Map<String, dynamic> packData;
  const EditPackScreen({super.key, required this.packData});

  @override
  State<EditPackScreen> createState() => _EditPackScreenState();
}

class _EditPackScreenState extends State<EditPackScreen> {
  late List<Post> _selectedProducts;
  late Map<int, int> _quantities;
  double _totalProductsPrice = 0;
  late TextEditingController _packPriceController;
  bool _isLoading = false;

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
    _selectedProducts = List<Post>.from(widget.packData['products'] ?? []);
    _quantities = Map<int, int>.from(widget.packData['quantities'] ?? {});
    _packPriceController = TextEditingController(text: widget.packData['packPrice']?.toString() ?? '');
    _updateTotal();
  }

  void _updateTotal() {
    _totalProductsPrice = 0;
    for (final product in _selectedProducts) {
      final qty = _quantities[product.id] ?? 1;
      _totalProductsPrice += product.price * qty;
    }
    setState(() {});
  }

  void _onQuantityChange(Post product, int qty) {
    setState(() {
      _quantities[product.id] = qty;
      _updateTotal();
    });
  }

  Future<void> _submit() async {
    if (_selectedProducts.isEmpty) {
      Helpers.showSnackBar(context, 'Select pack products first');
      return;
    }
    if (_packPriceController.text.isEmpty || double.tryParse(_packPriceController.text) == null) {
      Helpers.showSnackBar(context, 'Enter the pack sale price');
      return;
    }
    setState(() => _isLoading = true);
    // TODO: Call backend to update pack
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Helpers.showSnackBar(context, 'Pack updated successfully');
      Navigator.pop(context, true);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final allProducts = postProvider.myPosts;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Pack'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search for product to add',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (query) {
                  // TODO: implement search logic
                },
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Image')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Quantity')),
                      ],
                      rows: allProducts.map((product) {
                        final selected = _selectedProducts.contains(product);
                        if (!selected) return null;
                        return DataRow(
                          selected: selected,
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: product.gallery.isNotEmpty
                                    ? _safeThumb(product.gallery.first)
                                    : _safeThumb(null),
                              ),
                            ),
                            DataCell(
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(Text('${product.price.toStringAsFixed(2)} DZD')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      final qty = (_quantities[product.id] ?? 1);
                                      if (qty > 1) _onQuantityChange(product, qty - 1);
                                    },
                                  ),
                                  Text('${_quantities[product.id] ?? 1}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final qty = (_quantities[product.id] ?? 1);
                                      _onQuantityChange(product, qty + 1);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).whereType<DataRow>().toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Products Price: ${_totalProductsPrice.toStringAsFixed(2)} DZD'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _packPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pack Sale Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: _isLoading ? 'Updating...' : 'Save Changes',
                      onPressed: _isLoading ? () {} : _submit,
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
