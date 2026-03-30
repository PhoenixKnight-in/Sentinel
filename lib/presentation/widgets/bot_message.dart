import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BotMessage extends StatelessWidget {
  final String message;

  const BotMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        // Slightly lighter navy than background — line border only
        color:  const Color(0xFF0F2040),
        border: Border.all(color: const Color(0xFFFFFFFF).withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize:   18.sp,
          fontWeight: FontWeight.w400,
          color:      const Color(0xFFFFFFFF),
          height:     1.5,
        ),
      ),
    );
  }
}