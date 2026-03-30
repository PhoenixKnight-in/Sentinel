import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ButtonType { number, operator, action, equals }

class CalculatorButton extends StatefulWidget {
  final String label;
  final ButtonType type;
  final VoidCallback onPressed;
  final bool isWide;

  const CalculatorButton({
    super.key,
    required this.label,
    required this.type,
    required this.onPressed,
    this.isWide = false,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.91).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case ButtonType.number:
        return const Color(0xFF333333);
      case ButtonType.operator:
        return const Color(0xFFFF9500);
      case ButtonType.action:
        return const Color(0xFFA5A5A5);
      case ButtonType.equals:
        return const Color(0xFFFF9500);
    }
  }

  Color get _textColor {
    switch (widget.type) {
      case ButtonType.action:
        return Colors.black;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            shape: widget.isWide ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: widget.isWide ? BorderRadius.circular(50) : null,
            boxShadow: [
              BoxShadow(
                color: _backgroundColor.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: widget.isWide ? Alignment.centerLeft : Alignment.center,
          padding: widget.isWide
              ? const EdgeInsets.only(left: 32)
              : EdgeInsets.zero,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.label.length > 2 ? 20 : 28,
              fontWeight: FontWeight.w400,
              color: _textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}