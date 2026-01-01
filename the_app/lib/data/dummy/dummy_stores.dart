import 'store_model.dart';

class DummyStores {
  static final List<Store> nearbyStores = [
    Store(
      id: 's1',
      name: 'تيك زون للإلكترونيات',
      category: 'إلكترونيات',
      rating: 4.9,
      followers: 2340,
      distance: 0.3,
      imageUrl: 'https://images.unsplash.com/photo-1531297461136-82f5fca919b?w=500',
      isOpen: true,
      description: 'متجر متخصص في بيع الإلكترونيات والهواتف الذكية وملحقاتها',
    ),
    Store(
      id: 's2',
      name: 'فاشن هب بوتيك',
      category: 'أزياء وملابس',
      rating: 4.7,
      followers: 1820,
      distance: 0.7,
      imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500',
      isOpen: true,
      description: 'أحدث صيحات الموضة والأزياء العصرية',
    ),
    Store(
      id: 's3',
      name: 'هوم إسنشيالز بلس',
      category: 'منزل ومعيشة',
      rating: 4.5,
      followers: 980,
      distance: 1.1,
      imageUrl: 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=500',
      isOpen: true,
      description: 'كل ما تحتاجه لمنزلك من أثاث وديكورات',
    ),
    Store(
      id: 's4',
      name: 'سبورت هب',
      category: 'رياضة ولياقة',
      rating: 4.8,
      followers: 1560,
      distance: 0.5,
      imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=500',
      isOpen: true,
      description: 'معدات رياضية وملابس رياضية عالية الجودة',
    ),
    Store(
      id: 's5',
      name: 'بيوتي لاونج',
      category: 'تجميل وعناية',
      rating: 4.6,
      followers: 890,
      distance: 1.8,
      imageUrl: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=500',
      isOpen: false,
      description: 'منتجات تجميل وعناية بالبشرة والشعر',
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
