// lib/features/chatbot/presentation/widgets/option_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum CircleSize { large, medium, small }

class OptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final CircleSize size;

  const OptionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.size = CircleSize.medium,
  });

  double get _diameter {
    switch (size) {
      case CircleSize.large:
        return 100.r;
      case CircleSize.medium:
        return 82.r;
      case CircleSize.small:
        return 70.r;
    }
  }

  double get _fontSize {
    switch (size) {
      case CircleSize.large:
        return 13.sp;
      case CircleSize.medium:
        return 12.sp;
      case CircleSize.small:
        return 11.sp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFFFFFFFF).withOpacity(0.85),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: _fontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFFFFFF),
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
