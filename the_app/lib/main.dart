import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/storage_service.dart';
import 'core/services/store_api_service.dart';
import 'core/services/pack_api_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/post_provider.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/store_provider.dart';
import 'core/providers/pack_provider.dart';
import 'core/routing/route_generator.dart';
import 'presentation/auth/splash_screen.dart';
import 'features/analytics/analytics_export.dart';
import 'core/services/notification_badge_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'dz_local_channel',
  'DZ Local Notifications',
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
    final body =
        message.notification?.body ?? message.data['body']?.toString();
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
  });

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    NotificationBadgeService.instance.refresh();
  }

  // Initialize Storage Service
  await StorageService.init();
  await NotificationBadgeService.instance.refresh();
  await NotificationBadgeService.instance.syncMissedUnreadToShade();
  
  runApp(const DzLocalApp());
}

class DzLocalApp extends StatelessWidget {
  const DzLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider(apiService: StoreApiService())),
        ChangeNotifierProvider(create: (_) => PackProvider(apiService: PackApiService())),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        
        // Localization
        locale: const Locale(
          AppConstants.arabicLanguageCode,
          AppConstants.algeriaCountryCode,
        ),
        supportedLocales: const [
          Locale(AppConstants.arabicLanguageCode, AppConstants.algeriaCountryCode),
          Locale(AppConstants.englishLanguageCode, AppConstants.usCountryCode),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Theme
        theme: AppTheme.lightTheme,

        onGenerateRoute: onGenerateRoute,
        
        // Start with Splash Screen
        home: const SplashScreen(),
      ),
    );
  }
}
