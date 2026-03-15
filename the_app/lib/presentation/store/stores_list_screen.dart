import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/routing/routes.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/store_repository.dart';
import '../shared_widgets/empty_state_widget.dart';
import '../shared_widgets/error_state_widget.dart';
import '../shared_widgets/loading_indicator.dart';
import '../shared_widgets/unified_app_bar.dart';
import '../../core/services/follow_change_notifier.dart';

/// Stores list screen for bottom navigation
/// Shows all available stores with search and filter
class StoresListScreen extends StatefulWidget {
  const StoresListScreen({super.key});

  @override
  State<StoresListScreen> createState() => _StoresListScreenState();
}

class _StoresListScreenState extends State<StoresListScreen> {
  bool _isLoading = true;
  List<User> _stores = [];
  String? _error;

  late final VoidCallback _followListener;

  @override
  void initState() {
    super.initState();
    _followListener = () {
      if (!mounted) return;
      _loadStores();
    };
    FollowChangeNotifier.version.addListener(_followListener);
    _loadStores();
  }

  @override
  void dispose() {
    FollowChangeNotifier.version.removeListener(_followListener);
    super.dispose();
  }

  Future<void> _loadStores() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stores = await StoreRepository.getFollowedStores();

      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: UnifiedAppBar(
        showLocation: false,
        showNotificationIcon: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_stores.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadStores,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _stores.length,
        separatorBuilder: (context, index) => const SizedBox(
          height: AppConstants.spacing16,
        ),
        itemBuilder: (context, index) {
          final store = _stores[index];
          return _buildStoreCard(store);
        },
      ),
    );
  }

  Widget _buildStoreCard(User store) {
    final avatarUrl = store.profileImage;
    final rating = store.averageRating;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.store,
          arguments: store.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(
            color: AppColors.blackColor10,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // Store Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSmall),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.store,
                              color: AppColors.primaryColor,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: AppColors.primaryColor,
                        size: 30,
                      ),
              ),

              const SizedBox(width: AppConstants.spacing12),

              // Store Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (store.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.ratingYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const LoadingIndicator();
  }

  Widget _buildErrorState() {
    return ErrorStateWidget(
      message: 'Failed to load stores',
      details: _error ?? 'Unknown error',
      onRetry: _loadStores,
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.store_outlined,
      title: 'No followed stores',
      message: 'Follow a store to see it here',
    );
  }
}
