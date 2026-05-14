import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const BananaTrackerApp());
}

class BananaTrackerApp extends StatelessWidget {
  const BananaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return MaterialApp(
      title: 'Banana Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
      ),
      home: HomeScreen(db: db),
      routes: {
        '/history': (context) => HistoryScreen(db: db),
      },
    );
  }
}
