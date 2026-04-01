import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  // Load saved theme preferences
  await ThemeProvider.instance.loadPreferences();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeProvider = ThemeProvider.instance;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  bool get isDark {
    if (_themeProvider.themeMode == ThemeMode.dark) return true;
    if (_themeProvider.themeMode == ThemeMode.light) return false;
    final brightness = WidgetsBinding
        .instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  void toggleTheme() {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    _themeProvider.setThemeMode(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKharcha',
      debugShowCheckedModeBanner: false,
      themeMode: _themeProvider.themeMode,
      theme: _themeProvider.buildTheme(Brightness.light),
      darkTheme: _themeProvider.buildTheme(Brightness.dark),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}