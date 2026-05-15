import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/database_service.dart';
import 'services/preferences_service.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final db = DatabaseService();
  await db.database;

  final prefsService = PreferencesService();
  final hasSeenOnboarding = await prefsService.hasSeenOnboarding();
  final initialRoute = hasSeenOnboarding ? '/home' : '/onboarding';

  runApp(BananaTrackerApp(
    db: db,
    prefsService: prefsService,
    initialRoute: initialRoute,
  ));
}

class BananaTrackerApp extends StatelessWidget {
  final DatabaseService db;
  final PreferencesService prefsService;
  final String initialRoute;

  const BananaTrackerApp({
    super.key,
    required this.db,
    required this.prefsService,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banana Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      routes: {
        '/home': (context) => HomeScreen(db: db),
        '/onboarding': (context) =>
            OnboardingScreen(db: db, prefsService: prefsService),
        '/history': (context) => HistoryScreen(db: db),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFC107),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFFBEB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFF3CD),
        foregroundColor: Color(0xFF5D4037),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFF8E1),
        elevation: 2,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC107),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF2A2618),
      onSurface: const Color(0xFFF5E6C8),
      outline: const Color(0xFF3D3825),
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1C1A14),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF252318),
        foregroundColor: Color(0xFFF5E6C8),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2618),
        elevation: 2,
      ),
    );
  }
}
