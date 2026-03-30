import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The real app revealed after the unlock code is entered.
/// Contains: SOS trigger, incident reporting, vault access, location toggle.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _locationEnabled = false;
  int _sosTapCount = 0;
  Timer? _sosTapResetTimer;

  // Duress (covert) mode: 4 rapid taps on the SOS button
  static const int _duressThreshold = 4;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sosTapResetTimer?.cancel();
    super.dispose();
  }

  // ── Duress tap detection ─────────────────────────────────────────
  void _onSOSTap() {
    HapticFeedback.heavyImpact();
    _sosTapResetTimer?.cancel();

    setState(() => _sosTapCount++);

    if (_sosTapCount >= _duressThreshold) {
      _sosTapCount = 0;
      _triggerDuressMode();
      return;
    }

    // Reset counter after 1.5 s of inactivity
    _sosTapResetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_sosTapCount > 0 && _sosTapCount < _duressThreshold) {
        // Single deliberate tap — normal SOS
        _triggerSOS();
      }
      setState(() => _sosTapCount = 0);
    });
  }

  void _triggerSOS() {
    // TODO: send alert to trusted contacts via Firebase
    _showAlert(
      title: 'SOS Sent',
      message: 'Your location has been shared with your trusted contacts.',
      icon: Icons.check_circle_outline,
      color: const Color(0xFF34C759),
    );
  }

  void _triggerDuressMode() {
    // Duress = silent alert — NO visible confirmation to attacker
    // TODO: send silent FCM push + start evidence recording
    HapticFeedback.vibrate();
    // Show nothing. Return to calculator face silently.
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _showAlert({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(message,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildSOSButton(),
                    const SizedBox(height: 12),
                    _buildDuressTip(),
                    const SizedBox(height: 28),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildRecentAlerts(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'SafeHer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              Text(
                'You are protected',
                style: TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Return to calculator disguise
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calculate_outlined,
                  color: Color(0xFF8E8E93), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── SOS Button ───────────────────────────────────────────────────
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: _onSOSTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B30).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              const Text(
                'SEND SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              if (_sosTapCount > 0 && _sosTapCount < _duressThreshold)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_duressThreshold - _sosTapCount} more for silent mode',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuressTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: Color(0xFF636366), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap SOS 4× rapidly for silent duress mode (returns to calculator)',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.file_present_outlined,
        label: 'Report\nIncident',
        color: const Color(0xFFFF9500),
        onTap: () => _showComingSoon('Incident Report'),
      ),
      _QuickAction(
        icon: Icons.lock_outline,
        label: 'Evidence\nVault',
        color: const Color(0xFF007AFF),
        onTap: () => _showComingSoon('Evidence Vault'),
      ),
      _QuickAction(
        icon: Icons.people_outline,
        label: 'Trusted\nContacts',
        color: const Color(0xFF5856D6),
        onTap: () => _showComingSoon('Trusted Contacts'),
      ),
      _QuickAction(
        icon: Icons.map_outlined,
        label: 'Safety\nMap',
        color: const Color(0xFF34C759),
        onTap: () => _showComingSoon('Safety Map'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      children: actions
          .map((a) => GestureDetector(
                onTap: a.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: a.color.withOpacity(0.3), width: 1),
                      ),
                      child:
                          Icon(a.icon, color: a.color, size: 26),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFAEAEB2),
                          fontSize: 10,
                          height: 1.3),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ── Status Card ──────────────────────────────────────────────────
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Protection Status',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            icon: Icons.location_on_outlined,
            label: 'Background Location',
            active: _locationEnabled,
            trailing: Switch(
              value: _locationEnabled,
              activeColor: const Color(0xFF34C759),
              onChanged: (v) => setState(() => _locationEnabled = v),
            ),
          ),
          const Divider(color: Color(0xFF2C2C2E), height: 24),
          _buildStatusRow(
            icon: Icons.cloud_upload_outlined,
            label: 'Offline Queue',
            active: true,
            subtitle: '0 pending items',
          ),
          const Divider(color: Color(0xFF2C2C2E), height: 24),
          _buildStatusRow(
            icon: Icons.link,
            label: 'Blockchain Anchoring',
            active: false,
            subtitle: 'Polygon testnet',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool active,
    String? subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon,
            color: active ? const Color(0xFF34C759) : const Color(0xFF636366),
            size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF636366), fontSize: 12)),
            ],
          ),
        ),
        if (trailing != null) trailing,
        if (trailing == null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF34C759).withOpacity(0.15)
                  : const Color(0xFF636366).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              active ? 'Active' : 'Inactive',
              style: TextStyle(
                color: active
                    ? const Color(0xFF34C759)
                    : const Color(0xFF636366),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── Recent Alerts ────────────────────────────────────────────────
  Widget _buildRecentAlerts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Recent Activity',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                'See all',
                style:
                    TextStyle(color: Color(0xFF007AFF), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: Color(0xFF3A3A3C), size: 40),
                  SizedBox(height: 10),
                  Text(
                    'No recent incidents',
                    style: TextStyle(
                        color: Color(0xFF636366), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom NavBar ────────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF2C2C2E))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, 'Home', true),
          _navItem(Icons.description_outlined, 'Reports', false),
          _navItem(Icons.map_outlined, 'Map', false),
          _navItem(Icons.settings_outlined, 'Settings', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active) {
    final color =
        active ? const Color(0xFFFF3B30) : const Color(0xFF636366);
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming in next sprint'),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}