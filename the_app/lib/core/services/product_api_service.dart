import '../config/api_config.dart';
import './api_service.dart';
import '../../data/models/post_model.dart';

/// Pagination response wrapper
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  bool get hasMore => next != null;
}

class ProductApiService {
  ProductApiService();

  /// Get a single product by ID
  Future<Post> getProductDetails(int productId) async {
    try {
      final data = await ApiService.get('${ApiConfig.products}$productId/');
      if (data is Map<String, dynamic>) return Post.fromJson(data);
      throw Exception('Unexpected response when fetching product details');
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }

  /// Get products with optional filters
  Future<PaginatedResponse<Post>> getProducts({
    int? categoryId,
    String? searchQuery,
    int? storeId,
    double? minPrice,
    double? maxPrice,
    String? availableStatus,
    String? ordering,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (categoryId != null) params['category'] = categoryId.toString();
      if (searchQuery != null && searchQuery.isNotEmpty) params['search'] = searchQuery;
      if (storeId != null) params['store'] = storeId.toString();
      if (minPrice != null) params['min_price'] = minPrice.toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toString();
      if (availableStatus != null) params['available_status'] = availableStatus;
      if (ordering != null) params['ordering'] = ordering;

      String url = ApiConfig.products;
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }

      final data = await ApiService.get(url);

      if (data is Map<String, dynamic>) {
        final results = (data['results'] as List? ?? [])
            .map((json) => Post.fromJson(json as Map<String, dynamic>))
            .toList();

        return PaginatedResponse(
          count: data['count'] as int? ?? results.length,
          next: data['next'] as String?,
          previous: data['previous'] as String?,
          results: results,
        );
      }

      // Handle non-paginated response
      if (data is List) {
        final results = data.map((json) => Post.fromJson(json as Map<String, dynamic>)).toList();
        return PaginatedResponse(
          count: results.length,
          results: results,
        );
      }

      throw Exception('Unexpected response format');
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  /// Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final data = await ApiService.get(ApiConfig.categories);
      if (data is Map<String, dynamic> && data['results'] is List) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Search products
  Future<List<Post>> searchProducts(String query, {int limit = 20}) async {
    try {
      final response = await getProducts(searchQuery: query, page: 1);
      return response.results.take(limit).toList();
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  /// Get featured/hot products
  Future<List<Post>> getFeaturedProducts({int limit = 10}) async {
    try {
      final response = await getProducts(ordering: '-created_at', page: 1);
      return response.results.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching featured products: $e');
    }
  }
}
