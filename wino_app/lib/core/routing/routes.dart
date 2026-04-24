/// Central registry of all named routes in the application.
/// Only routes with a corresponding case in [RouteGenerator.generateRoute] are listed here.
class Routes {
  Routes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash           = '/';
  static const String login            = '/login';
  static const String register         = '/register';

  // ── Main shell ────────────────────────────────────────────────────────────
  static const String home             = '/home';

  // ── Store ─────────────────────────────────────────────────────────────────
  static const String store            = '/store';

  // ── Product / Post ────────────────────────────────────────────────────────
  static const String productDetails   = '/product-details';
  static const String promotionDetails = '/promotion-details';

  // ── Pack ─────────────────────────────────────────────────────────────────
  static const String packDetails      = '/pack-details';
  static const String addPack          = '/add-pack';

  // ── Search ────────────────────────────────────────────────────────────────
  static const String searchTab        = '/search';
  static const String searchResults    = '/search-results';

  // ── Favorites ─────────────────────────────────────────────────────────────
  static const String favorites        = '/favorites';
  static const String wishlist         = '/wishlist';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications    = '/notifications';

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const String feedbackSend     = '/feedback/send';
  static const String feedbackMy       = '/feedback/my';
  static const String qrScan           = '/qr/scan';
}
