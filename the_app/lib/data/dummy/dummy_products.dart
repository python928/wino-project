import 'product_model.dart';

class DummyProducts {
  static final List<Product> hotDeals = [
    Product(
      id: 'hd1',
      name: 'نايك اير ماكس 2024',
      storeName: 'سبورت هب',
      price: 18500,
      oldPrice: 25000,
      discount: '-26%',
      rating: 4.8,
      distance: 0.5,
      imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
      category: 'رياضة',
    ),
    Product(
      id: 'hd2',
      name: 'سامسونج جالاكسي S24',
      storeName: 'تيك زون',
      price: 145000,
      oldPrice: 180000,
      discount: '-20%',
      rating: 4.9,
      distance: 0.3,
      imageUrl: 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=500',
      category: 'إلكترونيات',
    ),
    Product(
      id: 'hd3',
      name: 'ساعة أبل الجيل 9',
      storeName: 'أبل ستور',
      price: 89000,
      oldPrice: 110000,
      discount: '-19%',
      rating: 4.7,
      distance: 1.2,
      imageUrl: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=500',
      category: 'إلكترونيات',
    ),
  ];

  static final List<Product> recommendedProducts = [
    Product(
      id: 'p1',
      name: 'ساعة ذكية سيريز 9',
      storeName: 'تيك بارادايس',
      price: 35000,
      rating: 4.6,
      distance: 1.2,
      imageUrl: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=500',
      category: 'إلكترونيات',
    ),
    Product(
      id: 'p2',
      name: 'سماعات لاسلكية',
      storeName: 'عالم الصوت',
      price: 8500,
      rating: 4.8,
      distance: 0.8,
      imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=500',
      category: 'إلكترونيات',
    ),
    Product(
      id: 'p3',
      name: 'آلة قهوة ديلوكس',
      storeName: 'هوم كوفي',
      price: 15000,
      rating: 4.7,
      distance: 0.5,
      imageUrl: 'https://images.unsplash.com/photo-1520981825232-ece5fae45120?w=500',
      category: 'منزل',
      isAvailable: false,
    ),
    Product(
      id: 'p4',
      name: 'حقيبة جلد فاخرة',
      storeName: 'فاشن ستايل',
      price: 12000,
      rating: 4.9,
      distance: 2.1,
      imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=500',
      category: 'أزياء',
    ),
    Product(
      id: 'p5',
      name: 'كاميرا احترافية كانون',
      storeName: 'فوتو برو',
      price: 95000,
      rating: 4.9,
      distance: 1.5,
      imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=500',
      category: 'إلكترونيات',
    ),
    Product(
      id: 'p6',
      name: 'حذاء رياضي أديداس',
      storeName: 'سبورت هب',
      price: 14500,
      rating: 4.6,
      distance: 0.9,
      imageUrl: 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=500',
      category: 'رياضة',
    ),
  ];

  static List<Product> getAllProducts() {
    return [...hotDeals, ...recommendedProducts];
  }
}
