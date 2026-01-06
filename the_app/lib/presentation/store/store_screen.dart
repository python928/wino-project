import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/backend_store_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../home/widgets/product_card.dart';

class StoreScreen extends StatefulWidget {
  final int storeId;

  const StoreScreen({
    super.key,
    required this.storeId,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = false;
  String? _error;
  BackendStore? _store;
  List<Post> _products = const [];
  bool _isFollowing = false;
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        StoreRepository.getStore(widget.storeId),
        PostRepository.getPosts(storeId: widget.storeId),
      ]);
      if (!mounted) return;
      setState(() {
        _store = results[0] as BackendStore?;
        _products = results[1] as List<Post>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? 'Store followed' : 'Unfollowed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRatingDialog() {
    double tempRating = _userRating;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rate Store', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate your experience with this store?'),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => tempRating = index + 1.0);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < tempRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  );
                },
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
                setState(() => _userRating = tempRating);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your rating!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callStore() async {
    if (_store?.phoneNumber.isEmpty ?? true) return;
    final uri = Uri.parse('tel:${_store!.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap() async {
    if (_store?.latitude == null || _store?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable')),
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_store!.latitude},${_store!.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Cover Image with App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: _store?.coverImageUrl.isNotEmpty == true
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _store!.coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primaryBlue.withOpacity(0.8),
                              child: const Icon(Icons.store, size: 60, color: Colors.white54),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Icon(Icons.store, size: 60, color: Colors.white54),
                      ),
              ),
            ),

            // Store Info Card
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image and Name
                        Row(
                          children: [
                            // Profile Image
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _store?.profileImageUrl.isNotEmpty == true
                                    ? Image.network(
                                        _store!.profileImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.store, size: 30, color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.store, size: 30, color: Colors.grey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name and Description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _store?.name ?? 'Store',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_store?.description.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _store!.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Rating and Follow Row
                        Row(
                          children: [
                            // Rating Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _showRatingDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _userRating > 0 ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _userRating > 0 ? _userRating.toStringAsFixed(0) : 'Rate',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Follow Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _toggleFollow,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isFollowing
                                        ? AppColors.primaryBlue
                                        : AppColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isFollowing ? Icons.check : Icons.add,
                                        color: _isFollowing ? Colors.white : AppColors.primaryBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isFollowing ? 'Following' : 'Follow',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _isFollowing ? Colors.white : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Contact Info
                        Row(
                          children: [
                            // Phone
                            if (_store?.phoneNumber.isNotEmpty == true)
                              Expanded(
                                child: GestureDetector(
                                  onTap: _callStore,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.phone, color: Colors.green, size: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Phone',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              _store!.phoneNumber,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Map
                            if (_store?.latitude != null && _store?.longitude != null)
                              GestureDetector(
                                onTap: _openMap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, color: AppColors.primaryBlue, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Map',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Address
                        if (_store?.address.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _store!.address,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Products Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'Store Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_products.length}',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products Grid
            if (_isLoading && _products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null && _products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                  child: Column(
                    children: [
                      Text(
                        'Error loading store data.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadStore,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No products currently available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = _products[index];
                      return ProductCard(
                        product: p,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Routes.productDetails,
                            arguments: p,
                          );
                        },
                      );
                    },
                    childCount: _products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
