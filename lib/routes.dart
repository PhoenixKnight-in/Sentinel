// ─────────────────────────────────────────────────────────────────────────────
//  routes.dart  — wire into your MaterialApp
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'report_status_page.dart';

// Uncomment and import your existing pages:
// import '../../../calculator/lib/main.dart';
// import '../../../chatbot/lib/main.dart';
// import '../../../status/lib/main.dart';

final Map<String, WidgetBuilder> appRoutes = {
  kRouteHome:         (_) => const MainHomePage(),
  kRouteMapDecoy:     (_) => const MapDecoyPage(),
  kRouteReportStatus: (_) => const ReportStatusPage(),
  // kRouteEvidence:   (_) => const EvidenceUploadPage(),
  // kRouteChatbot:    (_) => const ChatbotPage(),
  // kRouteCalculator: (_) => const CalculatorPage(),
};

// ── Theme to add to MaterialApp ───────────────────────────────────────────────
// Sets Georgia as the app-wide default text style so any Text widget
// not using the serif() helper still inherits the serif font.
ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      fontFamily: 'Georgia',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'Georgia', color: Color(0xFFFFFFFF)),
        bodySmall:  TextStyle(fontFamily: 'Georgia', color: Color(0xAAFFFFFF)),
      ),
      colorScheme: const ColorScheme.dark(
        surface:    Color(0xFF132236),
        primary:    Color(0xFFFFFFFF),
        onPrimary:  Color(0xFF0D1B2A),
        secondary:  Color(0xFFE6A817),
      ),
    );

// ── Minimal main.dart example ────────────────────────────────────────────────
//
// void main() => runApp(const SafeTraceApp());
//
// class SafeTraceApp extends StatelessWidget {
//   const SafeTraceApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SafeTrace',
//       debugShowCheckedModeBanner: false,
//       theme: appTheme(),
//       initialRoute: kRouteHome,
//       routes: appRoutes,
//     );
//   }
// }
