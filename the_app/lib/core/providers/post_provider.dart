import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

import '../../data/models/offer_model.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _myPosts = [];
  List<Offer> _offers = [];
  List<Offer> _myOffers = [];
  bool _isLoading = false;
  String? _error;

  bool _isLoadingPosts = false;
  bool _isLoadingOffers = false;
  String? _postsError;
  String? _offersError;

  List<Post> get posts => _posts;
  List<Post> get myPosts => _myPosts;
  List<Offer> get offers => _offers;
  List<Offer> get myOffers => _myOffers;
  bool get isLoading => _isLoading || _isLoadingPosts || _isLoadingOffers;
  String? get error => _error ?? _postsError ?? _offersError;

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get postsError => _postsError;
  String? get offersError => _offersError;

  // ... existing methods ...

  Future<void> loadOffers() async {
    _isLoadingOffers = true;
    _offersError = null;
    notifyListeners();

    try {
      _offers = await PostRepository.getOffers();
    } catch (e) {
      _offersError = e.toString();
      _error = _offersError;
    } finally {
      _isLoadingOffers = false;
      notifyListeners();
    }
  }

  Future<void> loadMyOffers(String authorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myOffers = await PostRepository.getOffers(authorId: authorId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMyData() {
    _myPosts = [];
    _myOffers = [];
    notifyListeners();
  }

  Future<void> createOffer({
    required int productId,
    required int discountPercentage,
    bool isAvailable = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newOffer = await PostRepository.createOffer(
        productId: productId,
        discountPercentage: discountPercentage,
        isAvailable: isAvailable,
      );
      _myOffers.insert(0, newOffer);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOffer({
    required int offerId,
    int? discountPercentage,
    bool? isAvailable,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await PostRepository.updateOffer(
        offerId: offerId,
        discountPercentage: discountPercentage,
        isAvailable: isAvailable,
      );
      final idx = _myOffers.indexWhere((o) => o.id == offerId);
      if (idx != -1) {
        _myOffers[idx] = updated;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOffer(int offerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await PostRepository.deleteOffer(offerId);
      _myOffers.removeWhere((o) => o.id == offerId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> loadPosts({
    String? search,
    int? storeId,
    int? categoryId,
  }) async {
    _isLoadingPosts = true;
    _postsError = null;
    notifyListeners();

    try {
      _posts = await PostRepository.getPosts(
        search: search,
        storeId: storeId,
        categoryId: categoryId,
      );
    } catch (e) {
      _postsError = e.toString();
      _error = _postsError;
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadMyPosts(String authorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch posts for the current user's store to ensure visibility even if author id in response differs
      final storeId = await PostRepository.getOrCreateMyStoreId();
      final posts = await PostRepository.getPosts(storeId: storeId);
      _myPosts = posts;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStorePosts(int storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myPosts = await PostRepository.getPosts(storeId: storeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHotDeals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final posts = await PostRepository.getPosts();
      _posts = posts.where((p) => (p.discountPercentage ?? 0) > 0 || p.isHotDeal).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPosts(String query) async {
    await loadPosts(search: query);
  }

  // Debounced search to avoid flooding the API during typing.
  Timer? _searchDebounce;

  void onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        await loadPosts(search: query);
      } catch (_) {
        // ignore; loadPosts already sets error state
      }
    });
  }

  Future<void> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required List<File> images,
    bool isAvailable = true,
    bool isNegotiable = false,
    bool hidePrice = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Provider: Adding product...');
      final newPost = await PostRepository.createProduct(
        title: title,
        description: description,
        price: price,
        category: category,
        images: images,
        isAvailable: isAvailable,
        isNegotiable: isNegotiable,
        hidePrice: hidePrice,
      );
      debugPrint('Provider: Product added, inserting to list');
      _posts.insert(0, newPost);

      // Always add to myPosts so it appears instantly in the merchant profile grid
      // Backend may return store owner differently (store id vs user id), so we avoid over-filtering here.
      _myPosts.insert(0, newPost);
    } catch (e) {
      debugPrint('Provider: Error adding product: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct({
    required int id,
    required String title,
    required String description,
    required double price,
    required String category,
    required bool isAvailable,
    bool hidePrice = false,
    List<File> newImages = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Provider: Updating product $id...');
      final updatedPost = await PostRepository.updateProduct(
        id: id,
        title: title,
        description: description,
        price: price,
        category: category,
        isAvailable: isAvailable,
        hidePrice: hidePrice,
        newImages: newImages,
      );
      
      final index = _posts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
      
      // Update myPosts as well
      final myIndex = _myPosts.indexWhere((p) => p.id == id);
      if (myIndex != -1) {
        _myPosts[myIndex] = updatedPost;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Provider: Error updating product: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await PostRepository.deletePost(id);
      _posts.removeWhere((p) => p.id == id);
      _myPosts.removeWhere((p) => p.id == id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
