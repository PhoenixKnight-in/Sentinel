import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/calculator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — calculators don't rotate
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar blends into calculator chrome
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SafeHerApp());
}

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',           // Disguise: shown in recent apps
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const CalculatorScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF9500),   // iOS Calculator orange
        surface: Color(0xFF1C1C1E),
        background: Color(0xFF000000),
      ),
      fontFamily: 'SF Pro Display',  // Fallback to system sans-serif
      scaffoldBackgroundColor: Colors.black,
    );
  }
}