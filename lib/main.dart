import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home_page.dart'; // MainHomePage, MapDecoyPage, AppColors, serif(), route constants
import 'report_status_page.dart'; // ReportStatusPage
import 'chatbot/chatbot_main.dart'; // re-exports ChatbotScreen
import "calculator.dart";

// ── Uncomment as you connect the remaining pages ──────────────────────────────
// import 'evidence/main.dart';   // re-exports EvidenceUploadPage
// import 'calculator/main.dart'; // re-exports CalculatorPage

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so navy bg shows through
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ProviderScope wraps the whole app so Riverpod works in ChatbotScreen
  // (and any other screen that uses it later)
  runApp(const ProviderScope(child: SafeTraceApp()));
}

class SafeTraceApp extends StatelessWidget {
  const SafeTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit uses the same design size the chatbot was built with.
    // All other screens are unaffected — they don't use .w / .h / .sp helpers.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'SafeTrace',
        debugShowCheckedModeBanner: false,

        // ── Global theme ───────────────────────────────────────────────────────
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bg,
          fontFamily: 'Georgia', // serif throughout
          colorScheme: const ColorScheme.dark(
            surface: AppColors.surface,
            primary: AppColors.white,
            onPrimary: AppColors.bg,
            secondary: AppColors.amber,
            error: AppColors.danger,
          ),
          // Remove all default splash / highlight effects for a clean tap feel
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          // Icon theme
          iconTheme: const IconThemeData(color: AppColors.white),
          // AppBar (not used directly, but good to set for consistency)
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.white,
            elevation: 0,
            titleTextStyle: serif(size: 18, weight: FontWeight.w600),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          // Text theme — all Georgia, all white
          textTheme: TextTheme(
            displayLarge: serif(size: 32, weight: FontWeight.w700),
            displayMedium: serif(size: 26, weight: FontWeight.w700),
            displaySmall: serif(size: 22, weight: FontWeight.w600),
            headlineLarge: serif(size: 20, weight: FontWeight.w600),
            headlineMedium: serif(size: 18, weight: FontWeight.w600),
            headlineSmall: serif(size: 16, weight: FontWeight.w600),
            titleLarge: serif(size: 15, weight: FontWeight.w600),
            titleMedium: serif(size: 14, weight: FontWeight.w500),
            titleSmall: serif(size: 13, weight: FontWeight.w500),
            bodyLarge: serif(size: 15),
            bodyMedium: serif(size: 14),
            bodySmall: serif(size: 12, color: AppColors.whiteSubtle),
            labelLarge: serif(
              size: 13,
              weight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            labelMedium: serif(size: 11, letterSpacing: 0.4),
            labelSmall: serif(
              size: 10,
              letterSpacing: 0.8,
              color: AppColors.whiteSubtle,
            ),
          ),
        ),

        // ── Routing ────────────────────────────────────────────────────────────
        initialRoute: kRouteCalculator,

        routes: {
          // Hub
          kRouteHome: (_) => const MainHomePage(),

          // Map (decoy — replace MapDecoyPage with your real map widget later)
          kRouteMapDecoy: (_) => const MapDecoyPage(),

          // Report status (fully coded)
          kRouteReportStatus: (_) => const ReportStatusPage(),

          // ── Chatbot (connected) ─────────────────────────────────────────────
          kRouteChatbot: (_) => const ChatbotScreen(),

          // ── Remaining pages — uncomment as you connect them ─────────────────
          // kRouteEvidence:   (_) => const EvidenceUploadPage(),
          kRouteCalculator: (_) => const CalculatorScreen(),
        },

        // Fallback for any unknown route
        onUnknownRoute: (_) =>
            MaterialPageRoute(builder: (_) => const _UnknownPage()),
      ),
    ); // end MaterialApp
  } // end ScreenUtilInit builder
} // end SafeTraceApp

// ─────────────────────────────────────────────────────────────────────────────
//  FALLBACK — shown if a route isn't wired yet (e.g. during development)
// ─────────────────────────────────────────────────────────────────────────────
class _UnknownPage extends StatelessWidget {
  const _UnknownPage();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                    Text(
                      'Page not found',
                      style: serif(size: 18, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.whiteDim),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off_rounded,
                        size: 48,
                        color: AppColors.whiteDim,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This page isn\'t connected yet.',
                        style: serif(
                          size: 15,
                          color: AppColors.whiteSubtle,
                          style: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          kRouteHome,
                          (_) => false,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.whiteSubtle,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Go home',
                            style: serif(size: 13, weight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
