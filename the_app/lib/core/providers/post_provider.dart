import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/offer_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _myPosts = [];
  List<Post> _storePosts = [];
  List<Offer> _offers = [];
  List<Offer> _adOffers = [];
  List<Offer> _myOffers = [];
  List<Offer> _storeOffers = [];
  bool _isLoading = false;
  String? _error;

  bool _isLoadingPosts = false;
  bool _isLoadingOffers = false;
  String? _postsError;
  String? _offersError;

  List<Post> get posts => _posts;
  List<Post> get myPosts => _myPosts;
  List<Post> get storePosts => _storePosts;
  List<Offer> get offers => _offers;
  List<Offer> get adOffers => _adOffers;
  List<Offer> get myOffers => _myOffers;
  List<Offer> get storeOffers => _storeOffers;
  bool get isLoading => _isLoading || _isLoadingPosts || _isLoadingOffers;
  String? get error => _error ?? _postsError ?? _offersError;

  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingOffers => _isLoadingOffers;
  String? get postsError => _postsError;
  String? get offersError => _offersError;

  Future<void> refreshMarketplaceFeed({
    String? search,
    int? storeId,
    int? categoryId,
    String? wilayaCode,
  }) async {
    await Future.wait([
      loadPosts(search: search, storeId: storeId, categoryId: categoryId),
      loadOffers(),
      loadAdOffers(wilayaCode: wilayaCode),
    ]);
  }

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

  Future<void> loadAdOffers({String? wilayaCode}) async {
    _isLoadingOffers = true;
    _offersError = null;
    notifyListeners();

    try {
      _adOffers = await PostRepository.getOffers(
        kind: 'advertising',
        placement: 'home_top',
        wilayaCode: wilayaCode,
      );
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
      final storeId = int.tryParse(authorId);
      final promotions = await PostRepository.getOffers(
        storeId: storeId,
        includeInactive: true,
      );
      final ads = await PostRepository.getOffers(
        storeId: storeId,
        includeInactive: true,
        kind: 'advertising',
      );
      _myOffers = [...promotions, ...ads]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStoreOffers(int storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _storeOffers = await PostRepository.getOffers(
        storeId: storeId,
        includeInactive: false,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMyData({bool notify = true}) {
    _myPosts = [];
    _myOffers = [];
    _storePosts = [];
    _storeOffers = [];
    if (notify) notifyListeners();
  }

  Future<void> createOffer({
    int? productId,
    int? packId,
    required int discountPercentage,
    bool isAvailable = true,
    String kind = 'promotion',
    String placement = 'home_top',
    String audienceMode = 'all',
    List<String> targetWilayas = const [],
    List<String> targetCategories = const [],
    int? priorityBoost,
    int? maxImpressions,
    int? ageFrom,
    int? ageTo,
    String geoMode = 'all',
    int? targetRadiusKm,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newOffer = await PostRepository.createOffer(
        productId: productId,
        packId: packId,
        discountPercentage: discountPercentage,
        isAvailable: isAvailable,
        kind: kind,
        placement: placement,
        audienceMode: audienceMode,
        targetWilayas: targetWilayas,
        targetCategories: targetCategories,
        priorityBoost: priorityBoost,
        maxImpressions: maxImpressions,
        ageFrom: ageFrom,
        ageTo: ageTo,
        geoMode: geoMode,
        targetRadiusKm: targetRadiusKm,
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
    int? productId,
    int? packId,
    int? discountPercentage,
    bool? isAvailable,
    String? kind,
    String? placement,
    String? audienceMode,
    List<String>? targetWilayas,
    List<String>? targetCategories,
    int? priorityBoost,
    int? maxImpressions,
    int? ageFrom,
    int? ageTo,
    String? geoMode,
    int? targetRadiusKm,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await PostRepository.updateOffer(
        offerId: offerId,
        productId: productId,
        packId: packId,
        discountPercentage: discountPercentage,
        isAvailable: isAvailable,
        kind: kind,
        placement: placement,
        audienceMode: audienceMode,
        targetWilayas: targetWilayas,
        targetCategories: targetCategories,
        priorityBoost: priorityBoost,
        maxImpressions: maxImpressions,
        ageFrom: ageFrom,
        ageTo: ageTo,
        geoMode: geoMode,
        targetRadiusKm: targetRadiusKm,
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
      final posts =
          await PostRepository.getPosts(storeId: storeId, availableOnly: false);
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
      // Public store view: show only available items.
      _storePosts =
          await PostRepository.getPosts(storeId: storeId, availableOnly: true);
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
      _posts = posts
          .where((p) => (p.discountPercentage ?? 0) > 0 || p.isHotDeal)
          .toList();
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
    required List<XFile> images,
    bool isAvailable = true,
    bool isNegotiable = false,
    bool hidePrice = false,
    bool deliveryAvailable = false,
    List<String> deliveryWilayas = const [],
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
        deliveryAvailable: deliveryAvailable,
        deliveryWilayas: deliveryWilayas,
      );
      debugPrint('Provider: Product added, inserting to list');
      _posts.insert(0, newPost);
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
    List<XFile> newImages = const [],
    List<int> removeImageIds = const [],
    bool deliveryAvailable = false,
    List<String> deliveryWilayas = const [],
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
        removeImageIds: removeImageIds,
        deliveryAvailable: deliveryAvailable,
        deliveryWilayas: deliveryWilayas,
      );

      final index = _posts.indexWhere((p) => p.id == id);
      if (index != -1) _posts[index] = updatedPost;
      final myIndex = _myPosts.indexWhere((p) => p.id == id);
      if (myIndex != -1) _myPosts[myIndex] = updatedPost;

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

  void clearAllData({bool notify = true}) {
    _posts = [];
    _myPosts = [];
    _storePosts = [];
    _offers = [];
    _myOffers = [];
    _storeOffers = [];
    _isLoading = false;
    _isLoadingPosts = false;
    _isLoadingOffers = false;
    _error = null;
    _postsError = null;
    _offersError = null;
    _searchDebounce?.cancel();
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
