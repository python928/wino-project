import '../models/user_model.dart';

class DummyStores {
  static final List<User> nearbyStores = [
    User(
      id: 1,
      username: 'tech_zone',
      email: 'tech@example.com',
      name: 'Tech Zone Electronics',
      phone: '+213000000001',
      dateJoined: DateTime.now(),
      storeDescription: 'A store specializing in electronics, smartphones, and accessories',
      address: 'Algiers',
      followersCount: 2340,
      averageRating: 4.9,
    ),
    User(
      id: 2,
      username: 'fashion_hub',
      email: 'fashion@example.com',
      name: 'Fashion Hub Boutique',
      phone: '+213000000002',
      dateJoined: DateTime.now(),
      storeDescription: 'Latest trends in modern fashion and clothing',
      address: 'Oran',
      followersCount: 1820,
      averageRating: 4.7,
    ),
    User(
      id: 3,
      username: 'home_essentials',
      email: 'home@example.com',
      name: 'Home Essentials Plus',
      phone: '+213000000003',
      dateJoined: DateTime.now(),
      storeDescription: 'Everything you need for your home: furniture and decor',
      address: 'Constantine',
      followersCount: 980,
      averageRating: 4.5,
    ),
    User(
      id: 4,
      username: 'sport_hub',
      email: 'sport@example.com',
      name: 'Sport Hub',
      phone: '+213000000004',
      dateJoined: DateTime.now(),
      storeDescription: 'High-quality sports equipment and apparel',
      address: 'Annaba',
      followersCount: 1560,
      averageRating: 4.8,
    ),
    User(
      id: 5,
      username: 'beauty_lounge',
      email: 'beauty@example.com',
      name: 'Beauty Lounge',
      phone: '+213000000005',
      dateJoined: DateTime.now(),
      storeDescription: 'Beauty products and skin/hair care',
      address: 'Algiers',
      followersCount: 890,
      averageRating: 4.6,
    ),
  ];

  static List<User> getAllStores() => nearbyStores;

  static User? getStoreById(int id) {
    try {
      return nearbyStores.firstWhere((store) => store.id == id);
    } catch (_) {
      return null;
    }
  }
}
