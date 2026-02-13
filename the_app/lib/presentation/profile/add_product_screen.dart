import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/post_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/post_model.dart';

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
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isAvailable = true;
  bool _showPrice = true;
  final _categoryController = TextEditingController();

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _titleController.text = product.title;
      _priceController.text = product.price.toString();
      _descriptionController.text = product.description;
      _categoryController.text = product.category;
      _isAvailable = product.isAvailable;
      _showPrice = !product.hidePrice;
      _images.addAll(product.gallery);
    }
  }

  Widget _buildImage(dynamic image) {
    if (image is File) {
      return Image.file(image, fit: BoxFit.cover);
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
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          title: const Text('Delete Product?'),
          content: const Text('This action cannot be undone.'),
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
          _images.addAll(
            picked.take(remainingSlots).map((x) => File(x.path)),
          );
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
    if (_images.isEmpty) {
      Helpers.showSnackBar(context, 'Please add at least one image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<PostProvider>(context, listen: false);
      final double price = !_showPrice
          ? 0.0
          : double.parse(
                  _priceController.text.isEmpty ? '0' : _priceController.text)
              .toDouble();

      if (_isEditMode) {
        final newFiles = _images.whereType<File>().toList();
        await provider.updateProduct(
          id: widget.product!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          category: _categoryController.text.isEmpty
              ? 'General'
              : _categoryController.text,
          isAvailable: _isAvailable,
          hidePrice: !_showPrice,
          newImages: newFiles,
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
          category: _categoryController.text.isEmpty
              ? 'General'
              : _categoryController.text,
          images: _images.whereType<File>().toList(),
          isAvailable: _isAvailable,
          isNegotiable: false,
          hidePrice: !_showPrice,
        );

        if (mounted) {
          Helpers.showSnackBar(context, 'Product published successfully');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
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
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Product' : 'Publish New Product'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
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

                      // Category
                      AppTextField(
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'Enter product category',
                        icon: Icons.category_outlined,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter product category'
                            : null,
                      ),
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
                        title: const Text('Show Price'),
                        subtitle:
                            const Text('Show price to customers in listings'),
                        value: _showPrice,
                        onChanged: (value) {
                          setState(() => _showPrice = value);
                        },
                      ),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available'),
                        subtitle:
                            const Text('Is the product available for sale?'),
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() => _isAvailable = value);
                        },
                      ),
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
            border:
                Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined,
                  size: 32, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                'Add Images',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to upload',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
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
                      onTap: () => setState(() => _images.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
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
}
