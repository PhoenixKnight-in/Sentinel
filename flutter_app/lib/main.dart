import 'package:flutter/material.dart';

import 'screens/map_screen.dart';

void main() {
  runApp(const SafeTransitApp());
}

class SafeTransitApp extends StatelessWidget {
  const SafeTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Transit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

