import 'package:flutter/material.dart';
import '../logic/calculator_logic.dart';
import '../widgets/calculator_button.dart';
import 'dashboard_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  final CalculatorLogic _logic = CalculatorLogic();
  String _display = '0';
  String _expression = '';
  bool _showClear = false; // tracks AC vs C toggle

  // Unlock transition animation
  late AnimationController _unlockController;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _unlockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _unlockController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _unlockController.dispose();
    super.dispose();
  }

  void _onButton(String input) {
    setState(() {
      _display = _logic.handleInput(input);
      _expression = _logic.expression;
      _showClear = _display != '0';
    });

    if (_logic.unlockTriggered) {
      _logic.resetUnlock();
      _triggerUnlock();
    }
  }

  Future<void> _triggerUnlock() async {
    await _unlockController.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOut,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ── Display ────────────────────────────────────────────
              Expanded(child: _buildDisplay()),
              // ── Button grid ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _buildButtonGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    // Shrink font when number is long
    final fontSize = _display.length > 9
        ? 56.0
        : _display.length > 6
            ? 72.0
            : 88.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Sub-expression (e.g. "125 ×")
          AnimatedOpacity(
            opacity: _expression.isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              _expression,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Main display
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 100),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w200,
              letterSpacing: -2,
            ),
            child: Text(
              _display,
              maxLines: 1,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    final clearLabel = _showClear ? 'C' : 'AC';

    // Row definitions: [label, type, isWide]
    final rows = [
      // Row 1 — action row
      [
        [clearLabel, ButtonType.action, false],
        ['+/-', ButtonType.action, false],
        ['%', ButtonType.action, false],
        ['÷', ButtonType.operator, false],
      ],
      // Row 2
      [
        ['7', ButtonType.number, false],
        ['8', ButtonType.number, false],
        ['9', ButtonType.number, false],
        ['×', ButtonType.operator, false],
      ],
      // Row 3
      [
        ['4', ButtonType.number, false],
        ['5', ButtonType.number, false],
        ['6', ButtonType.number, false],
        ['-', ButtonType.operator, false],
      ],
      // Row 4
      [
        ['1', ButtonType.number, false],
        ['2', ButtonType.number, false],
        ['3', ButtonType.number, false],
        ['+', ButtonType.operator, false],
      ],
    ];

    // Button size based on screen width
    final screenW = MediaQuery.of(context).size.width - 32;
    final btnSize = (screenW - 3 * 12) / 4; // 4 cols, 3 gaps

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((cell) {
                final label = cell[0] as String;
                final type = cell[1] as ButtonType;
                return SizedBox(
                  width: btnSize,
                  height: btnSize,
                  child: CalculatorButton(
                    label: label,
                    type: type,
                    onPressed: () => _onButton(label),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Bottom row: 0 (wide) + . + =
        Row(
          children: [
            SizedBox(
              width: btnSize * 2 + 12,
              height: btnSize,
              child: CalculatorButton(
                label: '0',
                type: ButtonType.number,
                onPressed: () => _onButton('0'),
                isWide: true,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: btnSize,
              height: btnSize,
              child: CalculatorButton(
                label: '.',
                type: ButtonType.number,
                onPressed: () => _onButton('.'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: btnSize,
              height: btnSize,
              child: CalculatorButton(
                label: '=',
                type: ButtonType.equals,
                onPressed: () => _onButton('='),
              ),
            ),
          ],
        ),
      ],
    );
  }
}