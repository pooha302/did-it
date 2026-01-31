import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'providers/action_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/main_screen.dart';
import 'services/ad_service.dart';
import 'constants/app_colors.dart';
import 'dart:io';

bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("🚀 Starting App Initialization...");
  
  try {
    debugPrint("🔥 Initializing Firebase...");
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDUZ6BJVyjuVajQN_kfuF3jl1WAq43fvRc',
          appId: '1:931227350417:ios:76bc34612723e33b071630',
          messagingSenderId: '931227350417',
          projectId: 'did-it-102b0',
          storageBucket: 'did-it-102b0.firebasestorage.app',
          iosBundleId: 'com.pooha302.didit',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    isFirebaseInitialized = true;
    debugPrint("✅ Firebase Initialized");
  } catch (e) {
    debugPrint("❌ Firebase Initialization Failed: $e");
  }

  try {
    debugPrint("🌐 Initializing Date Formatting...");
    const locales = ['ko', 'en', 'ja', 'zh', 'es', 'fr', 'de'];
    for (final locale in locales) {
      await initializeDateFormatting(locale, null);
    }
    debugPrint("✅ Date Formatting Initialized");
  } catch (e) {
    debugPrint("❌ Date Formatting Failed: $e");
  }
  
  try {
    debugPrint("💰 Initializing AdService...");
    await AdService.instance.init();
    debugPrint("✅ AdService Initialized");
  } catch (e) {
    debugPrint("❌ AdService Failed: $e");
  }
  
  debugPrint("🏁 Running App...");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppLocaleProvider()),
      ],
      child: const DiditApp(),
    ),
  );
}

class DiditApp extends StatelessWidget {
  const DiditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Did it',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.notoSansKrTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          onPrimary: Colors.black,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.secondary,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.dark,
      locale: context.watch<AppLocaleProvider>().locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [
        if (isFirebaseInitialized) FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
      ],
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse, 
          PointerDeviceKind.touch, 
          PointerDeviceKind.stylus, 
          PointerDeviceKind.unknown
        },
      ),
      home: const AppInitializer(),
    );
  }
}
