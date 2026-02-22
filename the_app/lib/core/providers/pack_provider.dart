import 'package:flutter/foundation.dart';
import '../../data/models/pack_model.dart';
import '../../data/models/post_model.dart';
import '../services/pack_api_service.dart';

class PackProvider extends ChangeNotifier {
  final PackApiService apiService;

  PackProvider({required this.apiService});

  final List<Post> _selectedProducts = [];
  final Map<int, int> _quantities = {};
  final List<Pack> _myPacks = [];
  final List<Pack> _storePacks = [];
  bool _isSubmitting = false;
  bool _isLoadingPacks = false;
  String? _error;

  List<Post> get selectedProducts => List.unmodifiable(_selectedProducts);
  Map<int, int> get quantities => Map.unmodifiable(_quantities);
  List<Pack> get myPacks => List.unmodifiable(_myPacks);
  List<Pack> get storePacks => List.unmodifiable(_storePacks);
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingPacks => _isLoadingPacks;
  String? get error => _error;

  Future<void> loadMyPacks(int merchantId) async {
    _isLoadingPacks = true;
    _error = null;
    notifyListeners();

    try {
      _myPacks.clear();
      final packs = await apiService.getMerchantPacks(merchantId, availableOnly: false);
      _myPacks.addAll(packs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPacks = false;
      notifyListeners();
    }
  }

  Future<void> loadStorePacks(int merchantId) async {
    _isLoadingPacks = true;
    _error = null;
    notifyListeners();

    try {
      _storePacks.clear();
      final packs = await apiService.getMerchantPacks(merchantId, availableOnly: true);
      _storePacks.addAll(packs);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingPacks = false;
      notifyListeners();
    }
  }

  double get totalPrice {
    double total = 0;
    for (final p in _selectedProducts) {
      final qty = _quantities[p.id] ?? 1;
      total += p.price * qty;
    }
    return total;
  }

  void addProduct(Post product) {
    if (_selectedProducts.any((p) => p.id == product.id)) return;
    _selectedProducts.add(product);
    _quantities[product.id] = 1;
    notifyListeners();
  }

  void removeProduct(Post product) {
    _selectedProducts.removeWhere((p) => p.id == product.id);
    _quantities.remove(product.id);
    notifyListeners();
  }

  void setQuantity(Post product, int qty) {
    if (!_selectedProducts.any((p) => p.id == product.id)) return;
    if (qty < 1) qty = 1;
    _quantities[product.id] = qty;
    notifyListeners();
  }

  void clear() {
    _selectedProducts.clear();
    _quantities.clear();
    _error = null;
    notifyListeners();
  }

  Future<Pack> submitPack({
    required String name,
    required String description,
    required double discountPrice,
    required int merchantId,
    bool isAvailable = true,
    bool deliveryAvailable = false,
    List<String> deliveryWilayas = const [],
  }) async {
    if (_selectedProducts.isEmpty) {
      throw Exception('Empty pack');
    }
    final products = _selectedProducts.map((p) {
      final qty = _quantities[p.id] ?? 1;
      return PackProduct(
        productId: p.id,
        productName: p.title,
        productImage: p.image ?? '',
        productPrice: p.price,
        quantity: qty,
      );
    }).toList();

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final pack = await apiService.createPack(
        name: name,
        description: description,
        products: products,
        discountPrice: discountPrice,
        merchantId: merchantId,
        isAvailable: isAvailable,
        deliveryAvailable: deliveryAvailable,
        deliveryWilayas: deliveryWilayas,
      );
      clear();
      await loadMyPacks(merchantId);
      return pack;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<Pack> updatePack({
    required int id,
    required String name,
    required String description,
    required double discountPrice,
    required bool isAvailable,
    required int merchantId,
    bool deliveryAvailable = false,
    List<String> deliveryWilayas = const [],
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> updates = {
        'name': name,
        'description': description,
        'discount_price': discountPrice.toStringAsFixed(2),
        'available_status': isAvailable ? 'available' : 'out_of_stock',
        'delivery_available': deliveryAvailable,
        'delivery_wilayas': deliveryWilayas.join(','),
      };

      if (_selectedProducts.isNotEmpty) {
        final products = _selectedProducts.map((p) {
          final qty = _quantities[p.id] ?? 1;
          return PackProduct(
            productId: p.id,
            productName: p.title,
            productImage: p.image ?? '',
            productPrice: p.price,
            quantity: qty,
          );
        }).toList();
        updates['products'] = products.map((p) => p.toJson()).toList();
      }

      final pack = await apiService.updatePack(id, updates);
      final index = _myPacks.indexWhere((p) => p.id == id);
      if (index != -1) _myPacks[index] = pack;
      notifyListeners();
      return pack;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deletePack(int id, {required int merchantId}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.deletePack(id);
      _myPacks.removeWhere((p) => p.id == id);
      await loadMyPacks(merchantId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
