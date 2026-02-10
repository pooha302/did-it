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
import 'services/widget_service.dart';
import 'package:home_widget/home_widget.dart';

import 'config/api_keys.dart';
import 'constants/app_colors.dart';
import 'dart:io';

bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: Platform.isIOS
            ? ApiKeys.iosFirebaseOptions
            : ApiKeys.androidFirebaseOptions,
      );
    }
    isFirebaseInitialized = true;
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      isFirebaseInitialized = true;
    } else {
      debugPrint("Firebase Initialization Failed: $e");
    }
  }

  try {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('ko_KR', null);
    await initializeDateFormatting('ja_JP', null);
  } catch (e) {
    debugPrint("Date Formatting Failed: $e");
  }
  
  try {
    await AdService.instance.initialize();
  } catch (e) {
    debugPrint("AdService Failed: $e");
  }

  // Register Home Widget Interaction (Always register this)
  try {
    await HomeWidget.registerBackgroundCallback(
      homeWidgetBackgroundCallback,
    );
  } catch (e) {
    debugPrint("HomeWidget Registration Failed: $e");
  }
  
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
