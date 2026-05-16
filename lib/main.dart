// ============================================================
// RailGuide — App Entry Point
// main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ← ADD THIS
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RailGuideApp());
}

class RailGuideApp extends StatelessWidget {
  const RailGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RailAuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'RailGuide',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // ── Locale ─────────────────────────────────────
            locale: langProvider.currentLocale,
            supportedLocales: LanguageProvider.supportedLocales,

            // ── Localisation delegates (FIXES THE CRASH) ───
            // These are required for Material widgets like
            // BottomNavigationBar, AlertDialog, DatePicker etc.
            // to find their translated labels in any locale.
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}