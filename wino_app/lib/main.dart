import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/pack_provider.dart';
import 'core/providers/post_provider.dart';
import 'core/providers/store_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/routing/route_generator.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_badge_service.dart';
import 'core/services/pack_api_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/store_api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/analytics_export.dart';
import 'l10n/app_localizations.dart';
import 'presentation/auth/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'wino_channel',
  'Wino Notifications',
  description: 'General notifications for Wino app',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Setup local notifications for foreground
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);
  NotificationBadgeService.instance
      .attachLocalNotifications(flutterLocalNotificationsPlugin);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    NotificationBadgeService.instance.refresh();
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title != null && title.isNotEmpty) ||
        (body != null && body.isNotEmpty)) {
      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title ?? 'Notification',
        body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });
  FirebaseMessaging.onMessageOpenedApp.listen((_) {
    NotificationBadgeService.instance.refresh();
    final deepLink = _.data['deep_link']?.toString();
    if (deepLink != null && deepLink.isNotEmpty) {
      DeepLinkService.handleFromString(deepLink);
    }
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    NotificationBadgeService.instance.refresh();
    final deepLink = initialMessage.data['deep_link']?.toString();
    if (deepLink != null && deepLink.isNotEmpty) {
      DeepLinkService.handleFromString(deepLink);
    }
  }

  // Initialize Storage Service
  await StorageService.init();
  await DeepLinkService.init();
  await NotificationBadgeService.instance.refresh();
  await NotificationBadgeService.instance.syncMissedUnreadToShade();

  runApp(const WinoApp());
}

class WinoApp extends StatelessWidget {
  const WinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
            create: (_) => StoreProvider(apiService: StoreApiService())),
        ChangeNotifierProvider(
            create: (_) => PackProvider(apiService: PackApiService())),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          navigatorKey: DeepLinkService.navigatorKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Localization
          locale: localeProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          // Theme
          theme: AppTheme.lightThemeFor(localeProvider.locale),

          // Keep navigation callbacks without overriding app text direction.
          builder: (context, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DeepLinkService.flushPendingLink();
            });
            return child ?? const SizedBox.shrink();
          },

          onGenerateRoute: onGenerateRoute,

          // Start with Splash Screen
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
