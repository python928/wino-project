import 'package:dzlocal_shop/core/extensions/l10n_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

class ReviewItem {
  final int id;
  final int rating;
  final String comment;
  final String userName;
  final DateTime? createdAt;

  const ReviewItem({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  static ReviewItem? fromJson(dynamic json) {
    if (json is! Map) return null;

    final int? id =
        json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}');
    final int? rating = json['rating'] is int
        ? json['rating'] as int
        : int.tryParse('${json['rating']}');
    final String comment = (json['comment'] ?? '').toString();

    final String userName =
        (json['user_name'] ?? json['username'] ?? 'User').toString();

    DateTime? createdAt;
    final rawCreated = json['created_at'];
    if (rawCreated != null) {
      createdAt = DateTime.tryParse(rawCreated.toString());
    }

    if (id == null || rating == null) return null;

    return ReviewItem(
      id: id,
      rating: rating,
      comment: comment,
      userName: userName,
      createdAt: createdAt,
    );
  }
}

class ReviewsSection extends StatefulWidget {
  final int? productId;
  final int? storeId;
  final Map<String, dynamic>? analyticsContext;

  const ReviewsSection.product({
    super.key,
    required this.productId,
    this.analyticsContext,
  }) : storeId = null;

  const ReviewsSection.store({
    super.key,
    required this.storeId,
    this.analyticsContext,
  }) : productId = null;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final TextEditingController _commentController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _isEditingMode = false;

  double _selectedRating = 0;
  List<ReviewItem> _reviews = const [];
  ReviewItem? _userExistingReview;

  bool get _isStoreReview => widget.storeId != null;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _listEndpoint() {
    if (_isStoreReview) {
      return '${ApiConfig.reviews}?store=${widget.storeId}';
    }
    return '${ApiConfig.reviews}?product=${widget.productId}';
  }

  Future<void> _loadReviews() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.get(_listEndpoint());

      final list = (data is Map && data['results'] is List)
          ? (data['results'] as List)
          : (data is List ? data : const []);

      final items = <ReviewItem>[];
      ReviewItem? userReview;
      final currentUserId = StorageService.getUserId();

      for (final raw in list) {
        final item = ReviewItem.fromJson(raw);
        if (item != null) {
          int? reviewUserId;
          if (raw is Map) {
            final reviewUserRaw = raw['user'];
            if (reviewUserRaw is int) {
              reviewUserId = reviewUserRaw;
            } else if (reviewUserRaw is String) {
              reviewUserId = int.tryParse(reviewUserRaw);
            } else if (reviewUserRaw is Map) {
              final nestedUserId =
                  reviewUserRaw['id'] ?? reviewUserRaw['user_id'];
              if (nestedUserId is int) {
                reviewUserId = nestedUserId;
              } else if (nestedUserId != null) {
                reviewUserId = int.tryParse('$nestedUserId');
              }
            }

            if (reviewUserId == null) {
              final explicitUserId = raw['user_id'];
              if (explicitUserId is int) {
                reviewUserId = explicitUserId;
              } else if (explicitUserId != null) {
                reviewUserId = int.tryParse('$explicitUserId');
              }
            }
          }

          if (currentUserId != null && reviewUserId == currentUserId) {
            userReview = item;
          } else {
            items.add(item);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _reviews = items;
        _userExistingReview = userReview;
        if (userReview != null) {
          _selectedRating = userReview.rating.toDouble();
          _commentController.text = userReview.comment;
        }
      });
    } catch (_) {
      // ignore; keep empty
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_isSubmitting || _isDeleting) return;

    if (!StorageService.isLoggedIn()) {
      Helpers.showSnackBar(context, context.tr('Log in to add a review'),
          isError: true);
      return;
    }

    final rating = _selectedRating.round();
    final comment = _commentController.text.trim();

    if (rating <= 0) {
      Helpers.showSnackBar(context, context.tr('Please select a rating'),
          isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isStoreReview) {
        // Use rate-store endpoint for store reviews
        final payload = <String, dynamic>{
          'store': widget.storeId,
          'rating': rating,
          'comment': comment,
        };
        if (widget.analyticsContext != null) {
          payload.addAll(widget.analyticsContext!);
        }
        await ApiService.post(ApiConfig.reviewsRateStore, payload);
      } else {
        // For product reviews, always use POST - backend will handle update logic
        final payload = <String, dynamic>{
          'product': widget.productId,
          'rating': rating,
          'comment': comment,
        };
        if (widget.analyticsContext != null) {
          payload.addAll(widget.analyticsContext!);
        }
        await ApiService.post(ApiConfig.reviews, payload);
      }

      if (!mounted) return;

      // Reset UI state
      setState(() {
        _isEditingMode = false;
        _selectedRating = 0;
      });
      _commentController.clear();

      Helpers.showSnackBar(
          context, context.tr('Review submitted successfully'));

      // Reload reviews to show updated state
      await _loadReviews();
    } catch (error) {
      if (!mounted) return;
      Helpers.showSnackBar(context,
          '${context.tr('Failed to submit review')}: ${error.toString()}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _confirmDeleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Delete your review?')),
        content: Text(context.tr('This will permanently remove your review.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              context.tr('Delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteReview() async {
    final review = _userExistingReview;
    if (review == null || _isDeleting || _isSubmitting) return;

    final confirmed = await _confirmDeleteReview();
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ApiService.delete('${ApiConfig.reviews}${review.id}/');

      if (!mounted) return;
      setState(() {
        _isEditingMode = false;
        _selectedRating = 0;
        _userExistingReview = null;
      });
      _commentController.clear();

      Helpers.showSnackBar(context, context.tr('Review deleted successfully'));
      await _loadReviews();
    } catch (error) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        '${context.tr('Failed to delete review')}: ${error.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _startEditing() {
    setState(() => _isEditingMode = true);
  }

  void _cancelEditing() {
    if (_userExistingReview != null) {
      setState(() {
        _isEditingMode = false;
        _selectedRating = _userExistingReview!.rating.toDouble();
        _commentController.text = _userExistingReview!.comment;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          context.tr('Reviews'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // User's existing review or input section
        if (_userExistingReview != null && !_isEditingMode) ...[
          // Show existing review with edit button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLightShade,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('Your Review'),
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(context.tr('Edit')),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed:
                          (_isSubmitting || _isDeleting) ? null : _deleteReview,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                      label: Text(
                        context.tr('Delete'),
                        style: const TextStyle(color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RatingBarIndicator(
                  rating: _userExistingReview!.rating.toDouble(),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: AppColors.ratingYellow,
                  ),
                  itemCount: 5,
                  itemSize: 18,
                  direction: Axis.horizontal,
                ),
                if (_userExistingReview!.comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _userExistingReview!.comment,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),
        ] else if (StorageService.isLoggedIn()) ...[
          // Show rating input (for new review or editing existing)
          RatingBar.builder(
            initialRating: _selectedRating,
            minRating: 1,
            allowHalfRating: false,
            itemSize: 24,
            unratedColor: Colors.grey.shade300,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: AppColors.ratingYellow,
            ),
            onRatingUpdate: (value) {
              setState(() => _selectedRating = value);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: context.tr('Write your review...'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditingMode)
                    IconButton(
                      onPressed: _cancelEditing,
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      tooltip: context.tr('Cancel'),
                    ),
                  IconButton(
                    onPressed:
                        (_isSubmitting || _isDeleting) ? null : _submitReview,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const Divider(height: 18),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              final dateText = review.createdAt != null
                  ? Helpers.formatDate(review.createdAt!, context: context)
                  : '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (dateText.isNotEmpty)
                        Text(
                          dateText,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  RatingBarIndicator(
                    rating: review.rating.toDouble(),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: AppColors.ratingYellow,
                    ),
                    itemCount: 5,
                    itemSize: 16,
                    direction: Axis.horizontal,
                  ),
                  if (review.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}
