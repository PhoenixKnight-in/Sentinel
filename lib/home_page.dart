import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'report_status_page.dart';

// ─── Route constants ──────────────────────────────────────────────────────────
const String kRouteHome = '/home';
const String kRouteReportStatus = '/report-status';
const String kRouteEvidence = '/evidence';
const String kRouteChatbot = '/chatbot';
const String kRouteCalculator = '/calculator';
const String kRouteMapDecoy = '/map';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
//  Background: deep navy  |  Text: white  |  Lines: white @ low opacity
//  Font: Georgia (system serif). To use a custom serif (e.g. Playfair Display):
//    1. Add the font to pubspec.yaml
//    2. Replace 'Georgia' with your font family name in the serif() helper
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const bg = Color(0xFF0D1B2A); // deep navy
  static const surface = Color(0xFF132236); // card surface
  static const surfaceHigh = Color(0xFF1A2E47); // elevated / hover

  static const white = Color(0xFFFFFFFF);
  static const whiteSubtle = Color(0xAAFFFFFF); // ~67 %
  static const whiteDim = Color(0x44FFFFFF); // ~27 % — dividers / borders

  static const amber = Color(0xFFE6A817);
  static const danger = Color(0xFFCF4949);
  static const success = Color(0xFF4A9B6F);
  static const info = Color(0xFF4A7FA5);
  static const purple = Color(0xFF7C5CBF);
}

TextStyle serif({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.white,
  double letterSpacing = 0,
  double height = 1.4,
  FontStyle style = FontStyle.normal,
}) => TextStyle(
  fontFamily: 'Georgia',
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing,
  height: height,
  fontStyle: style,
);

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN HOME PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MainHomePage extends StatelessWidget {
  const MainHomePage({super.key});

  void _go(BuildContext ctx, String route) => Navigator.pushNamed(ctx, route);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SafeTrace',
                      style: serif(
                        size: 22,
                        weight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.whiteSubtle,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.whiteDim),

              // ── Map ─────────────────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: GestureDetector(
                    onTap: () => _go(context, kRouteMapDecoy),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: AppColors.surface,
                            child: CustomPaint(painter: _MapGridPainter()),
                          ),
                          Positioned(
                            top: 72,
                            left: 110,
                            child: Icon(
                              Icons.location_pin,
                              color: AppColors.danger,
                              size: 32,
                            ),
                          ),
                          // border overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.whiteDim,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: AppColors.whiteDim,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.map_outlined,
                                      color: AppColors.whiteSubtle,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Tap to open map',
                                      style: serif(
                                        size: 11,
                                        color: AppColors.whiteSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Section label ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'QUICK ACTIONS',
                    style: serif(
                      size: 10,
                      color: AppColors.whiteSubtle,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Action cards ─────────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.assignment_outlined,
                          label: 'Report\nStatus',
                          onTap: () => _go(context, kRouteReportStatus),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.chat_bubble_outline,
                          label: 'Quick\nReport',
                          onTap: () => _go(context, kRouteChatbot),
                          highlight: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.upload_file_outlined,
                          label: 'Evidence\nUpload',
                          onTap: () => _go(context, kRouteEvidence),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Bottom bar ───────────────────────────────────────────────
              BottomBar(currentRoute: kRouteHome),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────
class BottomBar extends StatelessWidget {
  final String currentRoute;
  const BottomBar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: AppColors.whiteDim),
        Container(
          height: 64,
          color: AppColors.bg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BarBtn(
                icon: Icons.home_outlined,
                label: 'Home',
                active: currentRoute == kRouteHome,
                onTap: () {
                  if (currentRoute != kRouteHome) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      kRouteHome,
                      (_) => false,
                    );
                  }
                },
              ),
              _BarBtn(
                icon: Icons.description_outlined,
                label: 'Reports',
                active: currentRoute == kRouteReportStatus,
                onTap: () => Navigator.pushNamed(context, kRouteReportStatus),
              ),
              _BarBtn(
                icon: Icons.lock_outline,
                label: 'Evidence',
                active: currentRoute == kRouteEvidence,
                onTap: () => Navigator.pushNamed(context, kRouteEvidence),
              ),
              // Hard exit — looks like a ← back button → routes to calculator
              _HardExitBtn(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  kRouteCalculator,
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BarBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = active ? AppColors.white : AppColors.whiteDim;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: col, size: 20),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 18 : 0,
              height: 1,
              color: AppColors.white,
            ),
            const SizedBox(height: 4),
            Text(label, style: serif(size: 9, color: col, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

class _HardExitBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _HardExitBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.whiteDim,
              size: 20,
            ),
            const SizedBox(height: 4),
            const SizedBox(height: 1), // align with animated bar
            const SizedBox(height: 4),
            Text(
              'Exit',
              style: serif(
                size: 9,
                color: AppColors.whiteDim,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight; // ← new

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight ? AppColors.danger : AppColors.surface;
    final borderColor = highlight ? AppColors.danger : AppColors.whiteDim;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: serif(size: 11, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAP DECOY PAGE
// ─────────────────────────────────────────────────────────────────────────────
class MapDecoyPage extends StatelessWidget {
  const MapDecoyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              _PageHeader(
                title: 'Safety Map',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.whiteDim),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 52,
                              color: AppColors.whiteDim,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Map integration\ncoming soon',
                              textAlign: TextAlign.center,
                              style: serif(
                                size: 16,
                                color: AppColors.whiteSubtle,
                                style: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              BottomBar(currentRoute: kRouteMapDecoy),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  const _PageHeader({required this.title, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: serif(size: 20, weight: FontWeight.w600),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Container(height: 1, color: AppColors.whiteDim),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAP GRID PAINTER — dark navy theme
// ─────────────────────────────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    final road = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (double y = 0; y < size.height; y += 36)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    for (double x = 0; x < size.width; x += 36)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);

    canvas.drawLine(
      Offset(0, size.height * 0.38),
      Offset(size.width, size.height * 0.38),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.33, 0),
      Offset(size.width * 0.33, size.height),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.68, size.height * 0.15),
      Offset(size.width * 0.68, size.height * 0.85),
      road,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width * 0.65, size.height * 0.68),
      road,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
