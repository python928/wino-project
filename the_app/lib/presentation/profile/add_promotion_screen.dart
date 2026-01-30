import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/post_provider.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/post_model.dart';
import '../../data/models/offer_model.dart';
import '../shared_widgets/gradient_button.dart';

class AddPromotionScreen extends StatefulWidget {
  const AddPromotionScreen({super.key});

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  Post? _selectedProduct;
  Offer? _existingOffer;
  final _formKey = GlobalKey<FormState>();
  final _newPriceController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    super.dispose();
  }

  void _showProductSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<PostProvider>(
            builder: (context, provider, child) {
              final allPosts = provider.myPosts;
              
              return StatefulBuilder(
                builder: (context, setStateSheet) {
                  final filteredPosts = allPosts.where((post) {
                    final query = _searchController.text.toLowerCase();
                    return post.title.toLowerCase().contains(query);
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for product...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          onChanged: (val) => setStateSheet(() {}),
                        ),
                      ),
                      Expanded(
                        child: filteredPosts.isEmpty
                            ? const Center(child: Text('No matching products found'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredPosts.length,
                                itemBuilder: (context, index) {
                                  final post = filteredPosts[index];
                                  return ListTile(
                                    leading: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (post.image == null || post.image!.isEmpty)
                                            ? Container(
                                                color: Colors.grey[200],
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.image, color: Colors.grey),
                                              )
                                            : Image.network(
                                                post.image!,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
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
                                              ),
                                      ),
                                    ),
                                    title: Text(post.title),
                                    subtitle: Text('${post.price} DZD'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _onProductSelected(post);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _onProductSelected(Post post) {
    final provider = Provider.of<PostProvider>(context, listen: false);

    // Check if product already has a promotion
    final existingOffer = provider.myOffers.where((o) => o.product.id == post.id).firstOrNull;

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
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                child: const Icon(Icons.image, color: Colors.grey),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${offer.discountPercentage}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedProduct = post;
                  _existingOffer = offer;
                  _isEditMode = true;
                  _discountPercentageController.text = offer.discountPercentage.toString();
                  _newPriceController.text = offer.newPrice.toStringAsFixed(2);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Edit Discount', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
        );

        if (mounted) {
          Helpers.showSnackBar(context, 'Discount added successfully');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to ${_isEditMode ? 'edit' : 'add'} discount: $e');
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Discount' : 'Add Discount'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
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
                  onTap: _showProductSearchSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (_selectedProduct != null)
                          Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(left: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: (_selectedProduct!.image == null || _selectedProduct!.image!.isEmpty)
                                  ? Container(
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image, size: 20, color: Colors.grey),
                                    )
                                  : Image.network(
                                      _selectedProduct!.image!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _selectedProduct?.title ?? 'Tap to select product...',
                            style: TextStyle(
                              color: _selectedProduct == null ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
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
                        child: TextFormField(
                          controller: _discountPercentageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Discount Percentage (%)',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          onChanged: _onPercentageChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final n = double.tryParse(value);
                            if (n == null || n <= 0 || n >= 100) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // New Price
                      Expanded(
                        child: TextFormField(
                          controller: _newPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'New Price',
                            border: OutlineInputBorder(),
                            suffixText: 'DZD',
                          ),
                          onChanged: _onNewPriceChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            final n = double.tryParse(value);
                            final original = _selectedProduct!.price;
                            if (n == null || n <= 0 || n >= original) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: _isLoading
                          ? 'Saving...'
                          : (_isEditMode ? 'Save Changes' : 'Apply Discount'),
                      onPressed: _isLoading ? () {} : _submit,
                      gradient: AppColors.primaryGradient,
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
