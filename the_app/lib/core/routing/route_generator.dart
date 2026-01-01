import 'package:flutter/material.dart';

import '../../presentation/auth/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/home/main_navigation_screen.dart';
import '../../presentation/product/product_detail_screen.dart';
import '../../presentation/store/store_screen.dart';
import '../../presentation/store_details/store_details_screen.dart';
import '../../presentation/profile/add_product_screen.dart';
import '../../presentation/profile/edit_product_screen.dart';
import '../../presentation/profile/add_pack_screen.dart';
import '../../presentation/profile/edit_pack_screen.dart';
import '../../presentation/profile/add_promotion_screen.dart';
import '../../presentation/store_map/store_map_screen.dart';
import '../../presentation/statistics/statistics_screen.dart';
import '../../presentation/favorites/favorites_screen.dart';
import '../../presentation/discovery/discovery_screen.dart';
import '../../presentation/search/search_results_screen.dart';
import '../../data/models/post_model.dart';
import '../../data/models/store_model.dart';
import '../../data/models/pack_model.dart';
import 'routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ===== AUTH ROUTES =====
      case Routes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case Routes.login:
        return _slideTransition(
          settings: settings,
          child: const LoginScreen(),
        );

      case Routes.register:
        return _slideTransition(
          settings: settings,
          child: const RegisterScreen(),
        );

      // ===== MAIN ROUTES =====
      case Routes.home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: settings,
        );

      // ===== STORE ROUTES =====
      case Routes.store:
        final store = settings.arguments;
        if (store is! Store) {
          return _invalidArgsRoute(settings);
        }
        return _fadeTransition(
          settings: settings,
          child: StoreDetailsScreen(store: store),
        );

      // ===== PRODUCT ROUTES =====
      case Routes.productDetails:
        final product = settings.arguments;
        if (product is! Post) {
          return _invalidArgsRoute(settings);
        }
        return _slideTransition(
          settings: settings,
          child: ProductDetailScreen(product: product),
        );

      // ===== MERCHANT ROUTES =====
      case '/merchant/products/add':
        return _slideTransition(
          settings: settings,
          child: const AddProductScreen(),
        );

      case '/merchant/products/edit':
        final product = settings.arguments;
        if (product is! Post) {
          return _invalidArgsRoute(settings);
        }
        return _slideTransition(
          settings: settings,
          child: EditProductScreen(product: product),
        );

      case '/merchant/packs/add':
        return _slideTransition(
          settings: settings,
          child: AddPackScreen(),
        );

      case '/merchant/packs/edit':
        final pack = settings.arguments;
        if (pack is! Pack) {
          return _invalidArgsRoute(settings);
        }
        return _slideTransition(
          settings: settings,
          child: EditPackScreen(packData: pack.toJson()),
        );

      case '/merchant/promotions/add':
        return _slideTransition(
          settings: settings,
          child: const AddPromotionScreen(),
        );

      // ===== MAP & DISCOVERY =====
      case Routes.storeMap:
        return _slideTransition(
          settings: settings,
          child: const StoreMapScreen(),
        );

      case Routes.discovery:
        return _slideTransition(
          settings: settings,
          child: const DiscoveryScreen(),
        );

      case Routes.searchResults:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideTransition(
          settings: settings,
          child: SearchResultsScreen(
            initialQuery: args?['query'],
            initialCategoryId: args?['categoryId'],
            initialCategoryName: args?['categoryName'],
          ),
        );

      // ===== STATISTICS =====
      case Routes.statistics:
        return _slideTransition(
          settings: settings,
          child: const StatisticsScreen(),
        );

      // ===== FAVORITES =====
      case Routes.favorites:
      case Routes.wishlist:
        return _slideTransition(
          settings: settings,
          child: const FavoritesScreen(),
        );

      default:
        return _notFoundRoute(settings);
    }
  }

  // ===== TRANSITION HELPERS =====

  static Route<dynamic> _fadeTransition({
    required RouteSettings settings,
    required Widget child,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> _slideTransition({
    required RouteSettings settings,
    required Widget child,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Check for RTL
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final begin = isRtl ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Route<dynamic> _invalidArgsRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => _SimpleRouteErrorScreen(
        title: 'بيانات غير صحيحة',
        message: 'لا يمكن فتح هذه الصفحة لأن البيانات المرسلة غير صحيحة.',
        routeName: settings.name,
      ),
      settings: settings,
    );
  }

  static Route<dynamic> _notFoundRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => _SimpleRouteErrorScreen(
        title: 'الصفحة غير موجودة',
        message: 'هذه الصفحة غير متوفرة حالياً.',
        routeName: settings.name,
      ),
      settings: settings,
    );
  }
}

class _SimpleRouteErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? routeName;

  const _SimpleRouteErrorScreen({
    required this.title,
    required this.message,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              if (routeName != null)
                Text(
                  routeName!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
