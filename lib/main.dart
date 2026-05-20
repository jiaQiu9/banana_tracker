import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/badge_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
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

  final notificationService = NotificationService();
  await notificationService.init();

  final badgeService = BadgeService();

  final savedTheme = await prefsService.getThemeMode();
  final initialThemeMode = switch (savedTheme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  runApp(BananaTrackerApp(
    db: db,
    prefsService: prefsService,
    badgeService: badgeService,
    initialRoute: initialRoute,
    initialThemeMode: initialThemeMode,
  ));
}

class BananaTrackerApp extends StatefulWidget {
  final DatabaseService db;
  final PreferencesService prefsService;
  final BadgeService badgeService;
  final String initialRoute;
  final ThemeMode initialThemeMode;

  const BananaTrackerApp({
    super.key,
    required this.db,
    required this.prefsService,
    required this.badgeService,
    required this.initialRoute,
    required this.initialThemeMode,
  });

  @override
  State<BananaTrackerApp> createState() => _BananaTrackerAppState();
}

class _BananaTrackerAppState extends State<BananaTrackerApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _toggleTheme() {
    final systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final effectiveIsDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            systemBrightness == Brightness.dark);
    final newMode = effectiveIsDark ? ThemeMode.light : ThemeMode.dark;
    widget.prefsService.setThemeMode(
      newMode == ThemeMode.light ? 'light' : 'dark',
    );
    setState(() => _themeMode = newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banana Tracker',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      initialRoute: widget.initialRoute,
      routes: {
        '/home': (context) => HomeScreen(
          db: widget.db,
          prefsService: widget.prefsService,
          badgeService: widget.badgeService,
          onToggleTheme: _toggleTheme,
        ),
        '/onboarding': (context) =>
            OnboardingScreen(db: widget.db, prefsService: widget.prefsService),
        '/history': (context) => HistoryScreen(
          db: widget.db,
          badgeService: widget.badgeService,
        ),
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
