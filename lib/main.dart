import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/entry_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';

class AppColors {
  static const Color crimson = Color(0xFFCC0000);
  static const Color crimsonDark = Color(0xFF8B0000);
  static const Color crimsonLight = Color(0xFFFF1A1A);
  static const Color navy = Color(0xFF0A1628);
  static const Color navyMid = Color(0xFF112240);
  static const Color steel = Color(0xFF1E3A5F);
  static const Color accent = Color(0xFF2A6FC4);
  static const Color accentLight = Color(0xFF4A90D9);
  static const Color offWhite = Color(0xFFF5F0EB);
  static const Color warmGray = Color(0xFFB0A9A0);
  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color black = Color(0xFF080808);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.navy,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const ApocalypseApp());
}

class ApocalypseApp extends StatelessWidget {
  const ApocalypseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apocalypse | أبوكاليبس',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AuthGate(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.navy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.crimson,
        secondary: AppColors.accent,
        surface: AppColors.navyMid,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.offWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.navyMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.steel),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.steel),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.crimson, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.warmGray),
        hintStyle: const TextStyle(color: AppColors.warmGray),
        prefixIconColor: AppColors.warmGray,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        return const EntryScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ApocalypseLogo(size: 80),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppColors.crimson,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class ApocalypseLogo extends StatelessWidget {
  final double size;
  const ApocalypseLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AppColors.crimsonLight, AppColors.crimsonDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.crimson.withOpacity(0.6),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            Icons.public,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
        SizedBox(height: size * 0.18),
        Text(
          'APOCALYPSE',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: size * 0.06,
          ),
        ),
        Text(
          'أبوكاليبس',
          style: TextStyle(
            color: AppColors.crimson,
            fontSize: size * 0.22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
