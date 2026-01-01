import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/post_model.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../shared_widgets/gradient_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final Post product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;
  final PageController _pageController = PageController();

  // Rating state
  int _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _hasUserReview = false;
  bool _isSubmittingReview = false;
  bool _isEditingReview = false;
  int? _userReviewId;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = false;

  // Favorite state
  bool _isFavorited = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.product.isFavorited;
    _loadReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final response = await ApiService.get('${ApiConfig.reviews}?product=${widget.product.id}');
      final list = response is Map && response.containsKey('results')
          ? response['results'] as List
          : (response is List ? response : []);

      final userData = StorageService.getUserData();
      final userId = userData?['id'];

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(list);
        // Check if user already reviewed
        if (userId != null) {
          final userReview = _reviews.where((r) => r['user'] == userId).toList();
          if (userReview.isNotEmpty) {
            _hasUserReview = true;
            _userReviewId = userReview.first['id'];
            _userRating = userReview.first['rating'] ?? 0;
            _commentController.text = userReview.first['comment'] ?? '';
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      Helpers.showSnackBar(context, 'الرجاء اختيار تقييم');
      return;
    }

    // Check if user is logged in
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'يجب تسجيل الدخول لإضافة تقييم', isError: true);
      return;
    }

    setState(() => _isSubmittingReview = true);
    try {
      // If editing, use PATCH, otherwise POST
      if (_isEditingReview && _userReviewId != null) {
        await ApiService.patch('${ApiConfig.reviews}$_userReviewId/', {
          'rating': _userRating,
          'comment': _commentController.text.trim(),
        });
        setState(() {
          _isEditingReview = false;
          _hasUserReview = true;
        });
        Helpers.showSnackBar(context, 'تم تحديث تقييمك بنجاح');
      } else {
        await ApiService.post(ApiConfig.reviews, {
          'product': widget.product.id,
          'rating': _userRating,
          'comment': _commentController.text.trim(),
        });
        setState(() => _hasUserReview = true);
        Helpers.showSnackBar(context, 'تم إرسال تقييمك بنجاح');
      }
      _loadReviews();
    } catch (e) {
      debugPrint('Error submitting review: $e');
      String errorMessage = _isEditingReview ? 'فشل في تحديث التقييم' : 'فشل في إرسال التقييم';
      if (e.toString().contains('unique') || e.toString().contains('already')) {
        errorMessage = 'لقد قمت بتقييم هذا المنتج مسبقاً';
        setState(() => _hasUserReview = true);
      }
      Helpers.showSnackBar(context, errorMessage, isError: true);
    } finally {
      setState(() => _isSubmittingReview = false);
    }
  }

  void _startEditingReview() {
    setState(() {
      _isEditingReview = true;
    });
  }

  void _cancelEditingReview() {
    // Restore original values from the user's review
    final userData = StorageService.getUserData();
    final userId = userData?['id'];
    if (userId != null) {
      final userReview = _reviews.where((r) => r['user'] == userId).toList();
      if (userReview.isNotEmpty) {
        setState(() {
          _userRating = userReview.first['rating'] ?? 0;
          _commentController.text = userReview.first['comment'] ?? '';
          _isEditingReview = false;
        });
      }
    }
  }

  void _navigateToStore() {
    final userData = StorageService.getUserData();
    final userStoreId = userData?['store_id'];

    if (userStoreId != null && widget.product.storeId == userStoreId) {
      Navigator.pushNamed(context, Routes.profile);
    } else {
      Navigator.pushNamed(context, Routes.store, arguments: widget.product.storeId);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, 'يجب تسجيل الدخول لإضافة للمفضلة', isError: true);
      return;
    }

    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);
    try {
      final response = await ApiService.post(ApiConfig.favoritesToggle, {
        'product': widget.product.id,
      });

      setState(() {
        _isFavorited = response['is_favorited'] ?? !_isFavorited;
      });

      Helpers.showSnackBar(
        context,
        _isFavorited ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة',
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      Helpers.showSnackBar(context, 'حدث خطأ', isError: true);
    } finally {
      setState(() => _isTogglingFavorite = false);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsApp(String phone, String message) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanPhone.startsWith('213')) {
      cleanPhone = '213$cleanPhone';
    }
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasDiscount = product.oldPrice != null && product.oldPrice! > product.price;
    final discountPercent = hasDiscount
        ? ((product.oldPrice! - product.price) / product.oldPrice! * 100).round()
        : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: CustomScrollView(
          slivers: [
            // Image Gallery App Bar
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share, color: AppColors.textPrimary),
                  ),
                  onPressed: () => Helpers.showSnackBar(context, 'مشاركة المنتج'),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: _isTogglingFavorite
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : AppColors.textPrimary,
                          ),
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildImageGallery(product),
              ),
            ),

            // Product Content
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and Title Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.category,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Title
                          Text(
                            product.title,
                            style: AppTextStyles.h2,
                          ),

                          const SizedBox(height: 12),

                          // Price row
                          Row(
                            children: [
                              Text(
                                Helpers.formatPrice(product.price),
                                style: AppTextStyles.h1.copyWith(
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 12),
                                Text(
                                  Helpers.formatPrice(product.oldPrice!),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-$discountPercent%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Rating and availability
                          Row(
                            children: [
                              // Rating
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.rating > 0 ? product.rating.toStringAsFixed(1) : '-',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_reviews.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${_reviews.length})',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Availability
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: product.isAvailable
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.isAvailable ? 'متوفر' : 'غير متوفر',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: product.isAvailable ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Store info section
                    InkWell(
                      onTap: _navigateToStore,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
                              child: const Icon(Icons.store, color: AppColors.primaryPurple),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.storeName,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'اضغط لزيارة المتجر',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Description section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الوصف', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          AnimatedCrossFade(
                            firstChild: Text(
                              product.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              product.description,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            crossFadeState: _isDescriptionExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          if (product.description.length > 150)
                            TextButton(
                              onPressed: () {
                                setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
                              },
                              child: Text(
                                _isDescriptionExpanded ? 'عرض أقل' : 'عرض المزيد',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Rating Section
                    _buildRatingSection(),

                    const Divider(height: 1),

                    // Reviews List
                    _buildReviewsList(),

                    // Spacer for bottom buttons
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Bottom action buttons
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Call button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.call, color: AppColors.primaryPurple),
                    onPressed: () => _launchPhone('0555555555'), // Would use actual phone
                  ),
                ),
                const SizedBox(width: 12),
                // WhatsApp button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat, color: Colors.green),
                    onPressed: () => _launchWhatsApp(
                      '0555555555',
                      'مرحباً، أريد الاستفسار عن: ${product.title}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Contact seller button
                Expanded(
                  child: GradientButton(
                    text: 'تواصل مع البائع',
                    icon: Icons.message,
                    onPressed: () {
                      Helpers.showSnackBar(context, 'فتح المحادثة مع البائع');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(Post product) {
    if (product.images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.image, size: 80, color: Colors.grey),
      );
    }

    return Stack(
      children: [
        // Page view for images
        PageView.builder(
          controller: _pageController,
          itemCount: product.images.length,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemBuilder: (context, index) {
            final img = product.images[index];
            return GestureDetector(
              onTap: () {
                // Could open fullscreen gallery
              },
              child: Image.network(
                img.url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  );
                },
              ),
            );
          },
        ),

        // Page indicators
        if (product.images.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.primaryPurple
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

        // Discount badge
        if (product.discountPercentage != null && product.discountPercentage! > 0)
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '-${product.discountPercentage}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSection() {
    // Show login prompt if not logged in
    if (!StorageService.isLoggedIn()) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.login, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل الدخول لإضافة تقييم',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'شارك رأيك مع الآخرين',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.login);
                },
                child: Text(
                  'تسجيل الدخول',
                  style: TextStyle(color: AppColors.primaryPurple),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show user's existing review with edit option
    if (_hasUserReview && !_isEditingReview) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('تقييمك', style: AppTextStyles.h4),
                const Spacer(),
                // Edit button
                GestureDetector(
                  onTap: _startEditingReview,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: AppColors.primaryPurple, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'تعديل',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'تم التقييم',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < _userRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                );
              }),
            ),
            if (_commentController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _commentController.text,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Show edit form if editing
    if (_isEditingReview) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('تعديل تقييمك', style: AppTextStyles.h4),
                const Spacer(),
                TextButton(
                  onPressed: _cancelEditingReview,
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Star rating
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _userRating = index + 1);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      index < _userRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Comment field
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك هنا (اختياري)...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Update button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmittingReview
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('قيّم هذا المنتج', style: AppTextStyles.h4),
          const SizedBox(height: 12),

          // Star rating
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() => _userRating = index + 1);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Comment field
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب تعليقك هنا (اختياري)...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryPurple),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingReview ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmittingReview
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'إرسال التقييم',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'لا توجد تقييمات بعد',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'كن أول من يقيّم هذا المنتج',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('التقييمات', style: AppTextStyles.h4),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_reviews.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _reviews.length > 5 ? 5 : _reviews.length,
            (index) {
              final review = _reviews[index];
              final rating = review['rating'] ?? 0;
              final comment = review['comment'] ?? '';
              final userName = review['user_name'] ?? review['username'] ?? 'مستخدم';
              final createdAt = DateTime.tryParse(review['created_at'] ?? '') ?? DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.1),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'م',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Helpers.formatDate(createdAt),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            return Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_reviews.length > 5)
            Center(
              child: TextButton(
                onPressed: () {
                  // Could show all reviews in a modal
                  Helpers.showSnackBar(context, 'عرض كل التقييمات قريباً');
                },
                child: Text(
                  'عرض كل التقييمات (${_reviews.length})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
