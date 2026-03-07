import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/entry_provider.dart';
import 'screens/main_screen.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'utils/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Backup Service
  BackupService().initialize();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (e) {
      debugPrint("Native database initialization failed: $e");
    }

    try {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1100, 800),
        minimumSize: Size(1000, 700),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: "Transport POS",
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint("Window manager initialization failed: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => EntryProvider())],
      child: MaterialApp(
        title: 'Transport POS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily:
              'Roboto', // Default robust font, you can also consider google fonts
          scaffoldBackgroundColor: const Color(
            0xFFF1F5F9,
          ), // Light modern background
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 1,
            shadowColor: Colors.black12,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 3,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            color: Colors.white,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}
