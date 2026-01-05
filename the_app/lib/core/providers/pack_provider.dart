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
  bool _isSubmitting = false;
  bool _isLoadingPacks = false;
  String? _error;

  List<Post> get selectedProducts => List.unmodifiable(_selectedProducts);
  Map<int, int> get quantities => Map.unmodifiable(_quantities);
  List<Pack> get myPacks => List.unmodifiable(_myPacks);
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingPacks => _isLoadingPacks;
  String? get error => _error;

  Future<void> loadMyPacks(int merchantId) async {
    _isLoadingPacks = true;
    _error = null;
    notifyListeners();

    try {
      _myPacks.clear();
      final packs = await apiService.getMerchantPacks(merchantId);
      _myPacks.addAll(packs);
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
      );
      clear();
      // Refresh packs list
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
}
