import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/post_provider.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/post_model.dart';
import '../shared_widgets/gradient_button.dart';
import '../../core/widgets/app_button.dart';

class EditProductScreen extends StatefulWidget {
  final Post product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  final _picker = ImagePicker();
  bool _isLoading = false;
  late bool _isAvailable;
  // REMOVED duplicate _mainImageIndex declaration
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _categoryController = TextEditingController(text: widget.product.category);
    _isAvailable = widget.product.isAvailable;
    // Unified image list: network URLs (String) + new files (File)
    _images = List<dynamic>.from(widget.product.gallery);
  }

  Future<void> _pickImages() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() {
          final remainingSlots = 4 - _images.length;
          _images.addAll(
            picked.take(remainingSlots).map((x) => File(x.path)),
          );
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Error selecting images: $e', isError: true);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('Updating product...');
      // Gather only new File images for upload
      final List<File> newFiles = _images.whereType<File>().toList();
      await Provider.of<PostProvider>(context, listen: false).updateProduct(
        id: widget.product.id,
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _categoryController.text.isEmpty ? 'General' : _categoryController.text,
        isAvailable: _isAvailable,
        newImages: newFiles,
      );
      
      if (mounted) {
        debugPrint('Product updated successfully');
        Helpers.showSnackBar(context, 'Product updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Failed to update product: $e');
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
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Product'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallerySection(),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter product name' : null,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (DZD)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter price';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Product Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter product description' : null,
                ),
                const SizedBox(height: 16),

                // Availability Toggle
                SwitchListTile(
                  title: const Text('Show product in store'),
                  subtitle: const Text('You can temporarily hide the product without deleting it'),
                  value: _isAvailable,
                  onChanged: (bool value) {
                    setState(() {
                      _isAvailable = value;
                    });
                  },
                  activeColor: AppColors.primaryOrange,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: _isLoading ? 'Updating...' : 'Save Changes',
                    onPressed: _isLoading ? () {} : _submit,
                    gradient: AppColors.primaryGradient,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Delete Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _deleteProduct,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete Product',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _mainImageIndex = 0;
  List<String> _existingGallery = [];

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Images (max 4)'),
            TextButton.icon(
              onPressed: _images.length >= 4 ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_images.isEmpty)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 36, color: Colors.grey),
                    SizedBox(height: 6),
                    Text('Choose main image then 3 secondary images'),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final isMain = index == _mainImageIndex;
              return GestureDetector(
                onTap: () => setState(() => _mainImageIndex = index),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _images[index] is String
                          ? Image.network(
                              _images[index] as String,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
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
                            )
                          : Image.file(
                              _images[index] as File,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMain ? AppColors.primaryOrange : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isMain ? 'Main' : 'Secondary',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        style: IconButton.styleFrom(backgroundColor: Colors.white70),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _images.removeAt(index);
                            if (_mainImageIndex >= _images.length) {
                              _mainImageIndex = 0;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          AppTextButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          AppDangerButton(
            text: 'Delete',
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              setState(() => _isLoading = true);

              try {
                await Provider.of<PostProvider>(context, listen: false)
                    .deletePost(widget.product.id);

                if (mounted) {
                  Helpers.showSnackBar(context, 'Product deleted successfully');
                  Navigator.pop(context, true); // Return true to refresh
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  Helpers.showSnackBar(context, 'Failed to delete product: $e');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
