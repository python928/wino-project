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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Storage Service
  await StorageService.init();
  
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
