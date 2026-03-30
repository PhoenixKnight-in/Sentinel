import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/questions_tree.dart';

class ChatProgressIndicator extends StatelessWidget {
  final int currentIndex;

  const ChatProgressIndicator({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(questionFlow.length, (i) {
        final isActive = i <= currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 2.h,
          width: isActive ? 32.w : 16.w,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFFFFF)
                : const Color(0xFFFFFFFF).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(1.r),
          ),
        );
      }),
    );
  }
}
