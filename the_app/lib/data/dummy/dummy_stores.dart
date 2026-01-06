import 'store_model.dart';

class DummyStores {
  static final List<Store> nearbyStores = [
    Store(
      id: 's1',
      name: 'Tech Zone Electronics',
      category: 'Electronics',
      rating: 4.9,
      followers: 2340,
      distance: 0.3,
      imageUrl: 'https://images.unsplash.com/photo-1531297461136-82f5fca919b?w=500',
      isOpen: true,
      description: 'A store specializing in electronics, smartphones, and accessories',
    ),
    Store(
      id: 's2',
      name: 'Fashion Hub Boutique',
      category: 'Fashion & Clothing',
      rating: 4.7,
      followers: 1820,
      distance: 0.7,
      imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500',
      isOpen: true,
      description: 'Latest trends in modern fashion and clothing',
    ),
    Store(
      id: 's3',
      name: 'Home Essentials Plus',
      category: 'Home & Living',
      rating: 4.5,
      followers: 980,
      distance: 1.1,
      imageUrl: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=500',
      isOpen: true,
      description: 'Everything you need for your home: furniture and decor',
    ),
    Store(
      id: 's4',
      name: 'Sport Hub',
      category: 'Sports & Fitness',
      rating: 4.8,
      followers: 1560,
      distance: 0.5,
      imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500',
      isOpen: true,
      description: 'High-quality sports equipment and apparel',
    ),
    Store(
      id: 's5',
      name: 'Beauty Lounge',
      category: 'Beauty & Care',
      rating: 4.6,
      followers: 890,
      distance: 1.8,
      imageUrl: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=500',
      isOpen: false,
      description: 'Beauty products and skin/hair care',
    ),
  ];

  static List<Store> getAllStores() {
    return nearbyStores;
  }

  static Store? getStoreById(String id) {
    try {
      return nearbyStores.firstWhere((store) => store.id == id);
    } catch (e) {
      return null;
    }
  }
}
